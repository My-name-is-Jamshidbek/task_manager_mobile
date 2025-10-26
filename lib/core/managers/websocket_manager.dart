import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/websocket_service.dart';
import '../../data/models/realtime/websocket_event_models.dart';
import '../utils/logger.dart';

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

  /// Initialize listeners for WebSocket service streams
  void _initializeListeners() {
    // Listen to connection state changes
    _webSocketService.connectionStateStream.listen((isConnected) {
      _isConnected = isConnected;
      _lastError = null;
      notifyListeners();

      if (isConnected) {
        Logger.info('WebSocket connected', _tag);
      } else {
        Logger.warning('WebSocket disconnected', _tag);
      }
    });

    // Listen to errors
    _webSocketService.errorStream.listen((error) {
      _lastError = error;
      notifyListeners();
      Logger.error('WebSocket error: $error', _tag);
    });

    // Listen to events (events are handled by subscribers)
    _webSocketService.eventStream.listen((event) {
      _addToEventHistory(event);
      notifyListeners();
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

      notifyListeners();
      return success;
    } catch (e, stackTrace) {
      _isConnecting = false;
      _lastError = 'Error during connection: $e';
      Logger.error(_lastError!, _tag, e, stackTrace);
      notifyListeners();
      return false;
    }
  }

  /// Subscribe to a channel for real-time updates
  Future<bool> subscribeToChannel({
    required String channelName,
    required Function(String) onAuthRequired,
  }) async {
    if (!_isConnected) {
      _lastError = 'Not connected to WebSocket';
      Logger.warning(_lastError!, _tag);
      notifyListeners();
      return false;
    }

    if (_subscriptions[channelName] == true) {
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
        Logger.info('Subscribed to channel: $channelName', _tag);
      } else {
        _lastError = 'Failed to subscribe to channel: $channelName';
        Logger.error(_lastError!, _tag);
      }

      notifyListeners();
      return success;
    } catch (e, stackTrace) {
      _lastError = 'Error subscribing to channel: $e';
      Logger.error(_lastError!, _tag, e, stackTrace);
      notifyListeners();
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
      _subscriptions[channelName] = false;
      Logger.info('Unsubscribed from channel: $channelName', _tag);
      notifyListeners();
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
      notifyListeners();
      return;
    }

    try {
      _webSocketService.sendMessage(channel: channel, event: event, data: data);
      Logger.debug('Message sent: $event', _tag);
    } catch (e, stackTrace) {
      _lastError = 'Error sending message: $e';
      Logger.error(_lastError!, _tag, e, stackTrace);
      notifyListeners();
    }
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    try {
      await _webSocketService.disconnect();
      _isConnected = false;
      _isConnecting = false;
      _subscriptions.clear();
      _eventHistory.clear();
      _userToken = null;
      _userId = null;
      Logger.info('WebSocket disconnected', _tag);
      notifyListeners();
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
    notifyListeners();
  }

  /// Add event to history (max 100 events)
  void _addToEventHistory(WebSocketEvent event) {
    _eventHistory.insert(0, event);
    if (_eventHistory.length > 100) {
      _eventHistory.removeLast();
    }
  }

  @override
  Future<void> dispose() async {
    await _webSocketService.dispose();
    super.dispose();
  }
}
