import 'package:flutter/foundation.dart';
import '../../core/services/firebase_service.dart';
import '../../core/utils/logger.dart';

class FirebaseProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  bool _isInitialized = false;
  String? _fcmToken;
  bool _isRegisteredWithBackend = false;
  bool _isLoading = false;
  String? _error;
  String? _lastRegistrationResult;
  String? _lastDeactivationResult;

  // Getters
  bool get isInitialized => _isInitialized;
  String? get fcmToken => _fcmToken;
  bool get isRegisteredWithBackend => _isRegisteredWithBackend;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastRegistrationResult => _lastRegistrationResult;
  String? get lastDeactivationResult => _lastDeactivationResult;

  // Loading state management
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Initialize Firebase
  Future<void> initialize() async {
    try {
      _error = null;
      notifyListeners();

      await _firebaseService.initialize();

      _isInitialized = _firebaseService.isInitialized;
      _fcmToken = _firebaseService.fcmToken;

      // Listen to token refresh
      _firebaseService.listenToTokenRefresh((newToken) {
        Logger.info('🔄 FCM token refreshed in provider');
        _fcmToken = newToken;
        notifyListeners();

        // Auto-register new token with backend if previously registered
        if (_isRegisteredWithBackend) {
          _registerTokenWithBackend();
        }
      });

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      Logger.error('❌ Firebase provider initialization failed: $e');
      notifyListeners();
    }
  }

  /// Register FCM token with backend
  Future<void> registerToken({required String authToken}) async {
    try {
      setLoading(true);

      final result = await _firebaseService.registerTokenWithBackend(
        authToken: authToken,
      );

      if (result) {
        _lastRegistrationResult = 'Token registered successfully';
        Logger.info('✅ Firebase token registration successful');
      } else {
        _lastRegistrationResult = 'Failed to register token';
        Logger.error('❌ Firebase token registration failed');
      }

      notifyListeners();
    } catch (e) {
      _lastRegistrationResult = 'Error: $e';
      Logger.error('❌ Firebase token registration error: $e');
      notifyListeners();
    } finally {
      setLoading(false);
    }
  }

  Future<void> deactivateToken({required String authToken}) async {
    try {
      setLoading(true);

      final result = await _firebaseService.deactivateTokenFromBackend(
        authToken: authToken,
      );

      if (result) {
        _lastDeactivationResult = 'Token deactivated successfully';
        Logger.info('✅ Firebase token deactivation successful');
      } else {
        _lastDeactivationResult = 'Failed to deactivate token';
        Logger.error('❌ Firebase token deactivation failed');
      }

      notifyListeners();
    } catch (e) {
      _lastDeactivationResult = 'Error: $e';
      Logger.error('❌ Firebase token deactivation error: $e');
      notifyListeners();
    } finally {
      setLoading(false);
    }
  }

  /// Deactivate FCM token from backend
  Future<void> deactivateTokenFromBackend({String? authToken}) async {
    try {
      _error = null;
      notifyListeners();

      final success = await _firebaseService.deactivateTokenFromBackend(
        authToken: authToken,
      );

      if (success) {
        _isRegisteredWithBackend = false;
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      Logger.error('❌ Failed to deactivate token from backend: $e');
      notifyListeners();
    }
  }

  /// Private method to register token (used for auto-registration)
  Future<void> _registerTokenWithBackend() async {
    // This will be called when token refreshes and we need to re-register
    // You'll need to implement this based on your auth state management
    Logger.info('🔄 Auto-registering refreshed token with backend');

    // Example:
    // final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // if (authProvider.isAuthenticated) {
    //   await registerTokenWithBackend(
    //     apiBaseUrl: authProvider.apiBaseUrl,
    //     authToken: authProvider.authToken,
    //   );
    // }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseService.subscribeToTopic(topic);
    } catch (e) {
      _error = e.toString();
      Logger.error('❌ Failed to subscribe to topic: $e');
      notifyListeners();
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseService.unsubscribeFromTopic(topic);
    } catch (e) {
      _error = e.toString();
      Logger.error('❌ Failed to unsubscribe from topic: $e');
      notifyListeners();
    }
  }

  /// Refresh FCM token
  Future<void> refreshToken() async {
    try {
      _error = null;
      notifyListeners();

      final newToken = await _firebaseService.refreshToken();
      _fcmToken = newToken;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      Logger.error('❌ Failed to refresh token: $e');
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
