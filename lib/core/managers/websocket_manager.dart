import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../services/websocket_service.dart';
import '../../data/models/realtime/websocket_event_models.dart';
import '../utils/logger.dart';

typedef ChannelAuthCallback = Future<String> Function(String channelName);

/// WebSocket Manager using ChangeNotifier for state management
class WebSocketManager extends ChangeNotifier {
  static const String _tag = 'WebSocketManager';

  final WebSocketService _webSocketService = WebSocketService();

  // State
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _lastError;
  final List<WebSocketEvent> _eventHistory = [];
  String? _userToken;
  int? _userId;

  // Subscription management
  final Map<String, bool> _subscriptions = {};
  final Map<String, ChannelAuthCallback> _subscriptionAuthCallbacks = {};

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get lastError => _lastError;
  List<WebSocketEvent> get eventHistory => List.unmodifiable(_eventHistory);
  bool get isAuthenticated => _userToken != null && _userId != null;
  String? get socketId => _webSocketService.socketId;

  // Stream getters for direct access
  Stream<bool> get connectionStateStream =>
      _webSocketService.connectionStateStream;
  Stream<String> get errorStream => _webSocketService.errorStream;
  Stream<WebSocketEvent> get eventStream => _webSocketService.eventStream;

  WebSocketManager() {
    _initializeListeners();
  }

  /// Safely notify listeners after current frame
  void _safeNotifyListeners() {
    if (!hasListeners) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!hasListeners) return;
      try {
        notifyListeners();
      } catch (e) {
        Logger.warning('Error notifying listeners: $e', _tag);
      }
    });
  }

  /// Initialize listeners for WebSocket service streams
  void _initializeListeners() {
    // Listen to connection state changes
    _webSocketService.connectionStateStream.listen((isConnected) {
      _isConnected = isConnected;
      _lastError = null;
      _safeNotifyListeners();

      if (isConnected) {
        Logger.info('WebSocket connected', _tag);
        _resubscribeStaleChannels();
      } else {
        Logger.warning('WebSocket disconnected', _tag);
        _markSubscriptionsStale();
      }
    });

    // Listen to errors
    _webSocketService.errorStream.listen((error) {
      _lastError = error;
      _safeNotifyListeners();
      Logger.error('WebSocket error: $error', _tag);
    });

    // Listen to events (events are handled by subscribers)
    _webSocketService.eventStream.listen((event) {
      _addToEventHistory(event);
      _safeNotifyListeners();
    });
  }

  /// Connect to WebSocket server
  Future<bool> connect({required String token, required int userId}) async {
    if (_isConnecting) {
      Logger.warning('Already connecting', _tag);
      return false;
    }

    _isConnecting = true;
    _userToken = token;
    _userId = userId;
    _lastError = null;
    notifyListeners();

    try {
      final success = await _webSocketService.connect(
        token: token,
        userId: userId,
      );

      _isConnecting = false;

      if (success) {
        Logger.info('WebSocket connection successful', _tag);
      } else {
        _lastError = 'Failed to connect to WebSocket';
        Logger.error(_lastError!, _tag);
      }

      _safeNotifyListeners();
      return success;
    } catch (e, stackTrace) {
      _isConnecting = false;
      _lastError = 'Error during connection: $e';
      Logger.error(_lastError!, _tag, e, stackTrace);
      _safeNotifyListeners();
      return false;
    }
  }

  /// Subscribe to a channel for real-time updates
  Future<bool> subscribeToChannel({
    required String channelName,
    required ChannelAuthCallback onAuthRequired,
  }) async {
    if (!_isConnected) {
      _lastError = 'Not connected to WebSocket';
      Logger.warning(_lastError!, _tag);
      _safeNotifyListeners();
      return false;
    }

    if (_subscriptions[channelName] == true) {
      _subscriptionAuthCallbacks[channelName] = onAuthRequired;
      Logger.info('Already subscribed to channel: $channelName', _tag);
      return true;
    }

    try {
      final success = await _webSocketService.subscribeToChannel(
        channelName: channelName,
        onAuthRequired: onAuthRequired,
      );

      if (success) {
        _subscriptions[channelName] = true;
        _subscriptionAuthCallbacks[channelName] = onAuthRequired;
        Logger.info('Subscribed to channel: $channelName', _tag);
      } else {
        _lastError = 'Failed to subscribe to channel: $channelName';
        Logger.error(_lastError!, _tag);
      }

      _safeNotifyListeners();
      return success;
    } catch (e, stackTrace) {
      _lastError = 'Error subscribing to channel: $e';
      Logger.error(_lastError!, _tag, e, stackTrace);
      _safeNotifyListeners();
      return false;
    }
  }

  /// Unsubscribe from a channel
  void unsubscribeFromChannel(String channelName) {
    if (_subscriptions[channelName] != true) {
      Logger.info('Not subscribed to channel: $channelName', _tag);
      return;
    }

    try {
      _webSocketService.unsubscribeFromChannel(channelName);
      _subscriptions.remove(channelName);
      _subscriptionAuthCallbacks.remove(channelName);
      Logger.info('Unsubscribed from channel: $channelName', _tag);
      _safeNotifyListeners();
    } catch (e, stackTrace) {
      Logger.error('Error unsubscribing: $e', _tag, e, stackTrace);
    }
  }

  /// Listen to events with a callback
  StreamSubscription<WebSocketEvent> onEvent(
    Function(WebSocketEvent event) callback,
  ) {
    return _webSocketService.eventStream.listen(callback);
  }

  /// Listen to specific event types with a callback
  StreamSubscription<T> onEventType<T extends WebSocketEvent>(
    Function(T event) callback,
  ) {
    return _webSocketService.eventStream
        .where((event) => event is T)
        .map((event) => event as T)
        .listen(callback);
  }

  /// Send message through WebSocket
  void sendMessage({
    required String channel,
    required String event,
    required Map<String, dynamic> data,
  }) {
    if (!_isConnected) {
      _lastError = 'Not connected to WebSocket';
      Logger.warning(_lastError!, _tag);
      _safeNotifyListeners();
      return;
    }

    try {
      _webSocketService.sendMessage(channel: channel, event: event, data: data);
      Logger.debug('Message sent: $event', _tag);
    } catch (e, stackTrace) {
      _lastError = 'Error sending message: $e';
      Logger.error(_lastError!, _tag, e, stackTrace);
      _safeNotifyListeners();
    }
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    try {
      await _webSocketService.disconnect();
      _isConnected = false;
      _isConnecting = false;
      _subscriptions.clear();
      _subscriptionAuthCallbacks.clear();
      _eventHistory.clear();
      _userToken = null;
      _userId = null;
      Logger.info('WebSocket disconnected', _tag);
      _safeNotifyListeners();
    } catch (e, stackTrace) {
      Logger.error('Error disconnecting: $e', _tag, e, stackTrace);
    }
  }

  /// Check if subscribed to a channel
  bool isSubscribedTo(String channelName) {
    return _subscriptions[channelName] == true;
  }

  /// Clear event history
  void clearEventHistory() {
    _eventHistory.clear();
    _safeNotifyListeners();
  }

  /// Add event to history (max 100 events)
  void _addToEventHistory(WebSocketEvent event) {
    _eventHistory.insert(0, event);
    if (_eventHistory.length > 100) {
      _eventHistory.removeLast();
    }
  }

  void _markSubscriptionsStale() {
    if (_subscriptions.isEmpty) {
      return;
    }
    for (final channel in _subscriptions.keys.toList()) {
      _subscriptions[channel] = false;
    }
  }

  void _resubscribeStaleChannels() {
    if (_subscriptions.isEmpty) {
      return;
    }

    for (final entry in _subscriptions.entries.toList()) {
      final channel = entry.key;
      final isActive = entry.value;

      if (isActive) {
        continue;
      }

      final authCallback = _subscriptionAuthCallbacks[channel];
      if (authCallback == null) {
        continue;
      }

      // Mark as in-flight to avoid duplicate resubscribe attempts
      _subscriptions[channel] = true;

      _webSocketService
          .subscribeToChannel(
            channelName: channel,
            onAuthRequired: authCallback,
          )
          .then((success) {
            if (success) {
              _subscriptions[channel] = true;
              Logger.info('Resubscribed to channel: $channel', _tag);
            } else {
              _subscriptions[channel] = false;
              Logger.warning(
                'Failed to resubscribe to channel: $channel',
                _tag,
              );
            }
          })
          .catchError((error, stackTrace) {
            _subscriptions[channel] = false;
            Logger.error(
              'Error resubscribing to $channel: $error',
              _tag,
              error,
              stackTrace is StackTrace ? stackTrace : null,
            );
          });
    }
  }

  @override
  Future<void> dispose() async {
    await _webSocketService.dispose();
    super.dispose();
  }
}
