import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../utils/logger.dart';
import '../notifications/notification_templates.dart';
import 'notification_service.dart';
import '../../firebase_options.dart';
import '../localization/localization_service.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseMessaging? _messaging;
  String? _fcmToken;
  bool _isInitialized = false;

  // Getters
  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  /// Initialize Firebase and Firebase Messaging
  Future<void> initialize() async {
    // Prevent redundant initialization
    if (_isInitialized) {
      Logger.info('🔥 Firebase already initialized');
      return;
    }
    Logger.info('🔥 Initializing Firebase...');
    // Initialize Firebase Core if not already done
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } else {
        Logger.info('🔥 Firebase app already exists, skipping initializeApp');
      }
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        Logger.info('🔥 Firebase already initialized (duplicate-app)');
      } else {
        Logger.error('❌ Firebase initialization failed: $e');
        rethrow;
      }
    }
    // Initialize Firebase Messaging and handlers
    _messaging = FirebaseMessaging.instance;
    await _requestPermissions();
    await _getFCMToken();
    await _setupMessageHandlers();
    _isInitialized = true;
    Logger.info('✅ Firebase initialized successfully');
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      Logger.info('📱 Requesting notification permissions...');

      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      Logger.info('🔔 Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        Logger.info('✅ Notification permissions granted');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        Logger.info('⚠️ Provisional notification permissions granted');
      } else {
        Logger.warning('❌ Notification permissions denied');
      }
    } catch (e) {
      Logger.error('❌ Failed to request permissions: $e');
    }
  }

  /// Get FCM token
  Future<String?> _getFCMToken() async {
    // Directly fetch FCM token using the FirebaseMessaging singleton
    try {
      final token = await FirebaseMessaging.instance.getToken();
      _fcmToken = token;
      Logger.info('🔑 FCM Token obtained: ${token?.substring(0, 20)}...');
      return token;
    } catch (e) {
      Logger.error('❌ Failed to get FCM token: $e');
      return null;
    }
  }

  /// Setup message handlers for different states
  Future<void> _setupMessageHandlers() async {
    try {
      Logger.info('📨 Setting up message handlers...');

      // Handle messages when app is in foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background or terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      // Handle messages when app is terminated
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        Logger.info('📬 App opened from terminated state via notification');
        _handleTerminatedMessage(initialMessage);
      }

      // Handle background messages (when app is not in foreground)
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      Logger.info('✅ Message handlers setup complete');
    } catch (e) {
      Logger.error('❌ Failed to setup message handlers: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    Logger.info('📱 Foreground message received: ${message.messageId}');
    Logger.info('📄 Title: ${message.notification?.title}');
    Logger.info('📄 Body: ${message.notification?.body}');
    Logger.info('📄 Data: ${message.data}');

    // Show in-app notification
    NotificationService.showInAppNotification(
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? 'You have a new notification',
      data: message.data,
    );
  }

  /// Handle background message taps
  void _handleBackgroundMessage(RemoteMessage message) {
    Logger.info('📱 Background message tapped: ${message.messageId}');
    _navigateBasedOnMessage(message);
  }

  /// Handle terminated message taps
  void _handleTerminatedMessage(RemoteMessage message) {
    Logger.info('📱 Terminated message tapped: ${message.messageId}');
    _navigateBasedOnMessage(message);
  }

  /// Navigate based on message data
  void _navigateBasedOnMessage(RemoteMessage message) {
    final data = message.data;
    Logger.info('📱 Raw navigation data: $data');
    final parsed = parseNotificationTemplate(data);
    if (parsed == null) {
      Logger.warning('⚠️ No actionable navigation from message');
      return;
    }
    // Reuse NotificationService navigation helpers via reflection of screen.
    // For now we directly depend on NotificationService's internal dispatch
    // by re-invoking tap handler semantics.
    NotificationService.showInAppNotification(
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      data: data,
      duration: const Duration(seconds: 3),
    );
  }

  /// Register FCM token with backend
  Future<bool> registerTokenWithBackend({String? authToken}) async {
    // Ensure Firebase is initialized and token retrieved
    if (!_isInitialized) {
      await initialize();
    }
    if (_fcmToken == null) {
      await _getFCMToken();
    }

    if (_fcmToken == null) {
      Logger.error('❌ Cannot register token: FCM token is null');
      return false;
    }

    try {
      Logger.info('📤 Registering FCM token with backend...');

      final apiClient = ApiClient();
      if (authToken != null) {
        apiClient.setAuthToken(authToken);
      }

      final requestBody = {
        'token': _fcmToken!,
        'device_type': _getDeviceType(),
        'device_id': _getSimpleDeviceId(),
        // Send current app locale to backend for push localization
        'locale': LocalizationService().currentLocale.languageCode,
      };

      final response = await apiClient.post<Map<String, dynamic>>(
        '/firebase/tokens',
        body: requestBody,
      );

      if (response.isSuccess) {
        Logger.info('✅ FCM token registered successfully');
        return true;
      } else {
        Logger.error('❌ Failed to register FCM token: ${response.error}');
        return false;
      }
    } catch (e) {
      Logger.error('❌ Error registering FCM token: $e');
      return false;
    }
  }

  /// Deactivate FCM token from backend
  Future<bool> deactivateTokenFromBackend({String? authToken}) async {
    // Ensure Firebase is initialized and token retrieved
    if (!_isInitialized) {
      await initialize();
    }
    if (_fcmToken == null) {
      await _getFCMToken();
    }

    if (_fcmToken == null) {
      Logger.error('❌ Cannot deactivate token: FCM token is null');
      return false;
    }

    try {
      Logger.info('📤 Deactivating FCM token from backend...');

      final apiClient = ApiClient();
      if (authToken != null) {
        apiClient.setAuthToken(authToken);
      }

      final deleteResponse = await apiClient.delete<void>(
        '/firebase/tokens',
        body: {'token': _fcmToken!},
      );

      if (deleteResponse.isSuccess) {
        Logger.info('✅ FCM token deactivated from backend');
        return true;
      }

      // If unauthorized, try public deactivation endpoint without auth header
      if (deleteResponse.statusCode == 401) {
        Logger.warning(
          '⚠️ Auth deactivation returned 401, trying public endpoint',
        );
        final publicResponse = await apiClient.delete<void>(
          '/firebase/tokens/public',
          body: {'token': _fcmToken!},
          includeAuth: false,
        );

        if (publicResponse.isSuccess) {
          Logger.info('✅ FCM token deactivated via public endpoint');
          return true;
        }
        Logger.error(
          '❌ Public deactivation failed with status: '
          '${publicResponse.statusCode}',
        );
        return false;
      }

      Logger.error(
        '❌ Failed to deactivate FCM token, status: '
        '${deleteResponse.statusCode ?? 'unknown'} '
        '- ${deleteResponse.error}',
      );
      return false;
    } catch (e) {
      Logger.error('❌ Error deactivating FCM token: $e');
      return false;
    }
  }

  /// Update current FCM token locale on backend
  Future<bool> updateTokenLocale({String? authToken, String? locale}) async {
    // Ensure Firebase is initialized and token retrieved
    if (!_isInitialized) {
      await initialize();
    }
    if (_fcmToken == null) {
      await _getFCMToken();
    }

    if (_fcmToken == null) {
      Logger.error('❌ Cannot update token locale: FCM token is null');
      return false;
    }

    try {
      Logger.info('🌍 Updating FCM token locale on backend...');

      final apiClient = ApiClient();
      if (authToken != null) {
        apiClient.setAuthToken(authToken);
      }

      final currentLocale =
          (locale ?? LocalizationService().currentLocale.languageCode)
              .toLowerCase();

      final response = await apiClient.patch<Map<String, dynamic>>(
        '/firebase/tokens/locale',
        body: {'token': _fcmToken!, 'locale': currentLocale},
      );

      if (response.isSuccess) {
        Logger.info('✅ FCM token locale updated to "$currentLocale"');
        return true;
      } else {
        Logger.error('❌ Failed to update FCM token locale: ${response.error}');
        return false;
      }
    } catch (e) {
      Logger.error('❌ Error updating FCM token locale: $e');
      return false;
    }
  }

  /// Get simple device identifier (for basic device tracking)
  String _getSimpleDeviceId() {
    // Generate a simple device identifier based on platform
    if (Platform.isAndroid) {
      return 'android_${DateTime.now().millisecondsSinceEpoch % 100000}';
    } else if (Platform.isIOS) {
      return 'ios_${DateTime.now().millisecondsSinceEpoch % 100000}';
    }
    return 'unknown_${DateTime.now().millisecondsSinceEpoch % 100000}';
  }

  /// Get device type
  String _getDeviceType() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (kIsWeb) return 'web';
    return 'unknown';
  }

  /// Refresh FCM token
  Future<String?> refreshToken() async {
    // Ensure Firebase and messaging are initialized
    if (!_isInitialized) await initialize();
    _messaging ??= FirebaseMessaging.instance;
    try {
      Logger.info('🔄 Refreshing FCM token...');
      await _messaging!.deleteToken();
      return await _getFCMToken();
    } catch (e) {
      Logger.error('❌ Failed to refresh FCM token: $e');
      return null;
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    // Ensure Firebase and messaging are initialized
    if (!_isInitialized) await initialize();
    _messaging ??= FirebaseMessaging.instance;
    try {
      Logger.info('📢 Subscribing to topic: $topic');
      await _messaging!.subscribeToTopic(topic);
      Logger.info('✅ Subscribed to topic: $topic');
    } catch (e) {
      Logger.error('❌ Failed to subscribe to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    // Ensure Firebase and messaging are initialized
    if (!_isInitialized) await initialize();
    _messaging ??= FirebaseMessaging.instance;
    try {
      Logger.info('📢 Unsubscribing from topic: $topic');
      await _messaging!.unsubscribeFromTopic(topic);
      Logger.info('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      Logger.error('❌ Failed to unsubscribe from topic $topic: $e');
    }
  }

  /// Listen to token refresh
  void listenToTokenRefresh(Function(String) onTokenRefresh) {
    // Ensure Firebase and messaging are initialized
    _messaging ??= FirebaseMessaging.instance;
    _messaging!.onTokenRefresh.listen((newToken) {
      Logger.info('🔄 FCM token refreshed: ${newToken.substring(0, 20)}...');
      _fcmToken = newToken;
      onTokenRefresh(newToken);
    });
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  await Firebase.initializeApp();

  Logger.info('📱 Background message received: ${message.messageId}');
  Logger.info('📄 Title: ${message.notification?.title}');
  Logger.info('📄 Body: ${message.notification?.body}');
  Logger.info('📄 Data: ${message.data}');

  // Handle background message logic here if needed
}
