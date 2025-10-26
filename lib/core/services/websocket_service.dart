import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/api_constants.dart';
import '../utils/logger.dart';
import '../../data/models/realtime/websocket_event_models.dart';

/// WebSocket service for handling real-time chat communication with Pusher
class WebSocketService {
  static const String _tag = 'WebSocketService';

  // WebSocket connection
  late WebSocketChannel _channel;

  // Connection state
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _socketId;
  String? _userToken;
  int? _userId;

  // Stream controllers
  final _eventStreamController = StreamController<WebSocketEvent>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // Reconnection settings
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  // Public streams
  Stream<WebSocketEvent> get eventStream => _eventStreamController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  Stream<String> get errorStream => _errorController.stream;

  // Public getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get socketId => _socketId;

  /// Connect to WebSocket server
  Future<bool> connect({required String token, required int userId}) async {
    if (_isConnected || _isConnecting) {
      Logger.warning('WebSocket already connected or connecting', _tag);
      return false;
    }

    _isConnecting = true;
    _userToken = token;
    _userId = userId;

    try {
      final wsScheme = ApiConstants.reverbScheme.toLowerCase() == 'https'
          ? 'wss'
          : 'ws';
      final wsUrl =
          '$wsScheme://${ApiConstants.reverbHost}:${ApiConstants.reverbPort}/app/${ApiConstants.reverbAppKey}?protocol=7&client=flutter&version=1.0';

      Logger.info('Connecting to WebSocket: $wsUrl', _tag);

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen to messages
      _channel.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleClose,
      );

      _isConnecting = false;
      Logger.info('WebSocket connection initiated', _tag);
      return true;
    } catch (e, stackTrace) {
      _isConnecting = false;
      final errorMsg = 'Failed to connect to WebSocket: $e';
      Logger.error(errorMsg, _tag, e, stackTrace);
      _errorController.add(errorMsg);
      return false;
    }
  }

  /// Authorize and subscribe to a private channel
  Future<bool> subscribeToChannel({
    required String channelName,
    required Function(String) onAuthRequired,
  }) async {
    if (!_isConnected || _socketId == null) {
      Logger.warning(
        'Cannot subscribe: not connected or socket_id missing',
        _tag,
      );
      return false;
    }

    try {
      // Get auth token from callback
      Logger.info(
        '🔑 [CLIENT] Requesting auth for channel: "$channelName"',
        _tag,
      );
      final authToken = await onAuthRequired(channelName);
      Logger.info(
        '✅ [CLIENT] Auth token obtained, length: ${authToken.length}',
        _tag,
      );

      // Send subscription payload
      final payload = {
        'event': 'pusher:subscribe',
        'data': {'channel': channelName, 'auth': authToken},
      };

      Logger.info(
        '📤 [CLIENT] Sending subscription payload for channel: "$channelName"',
        _tag,
      );
      Logger.debug('Payload: ${jsonEncode(payload)}', _tag);
      _send(payload);
      Logger.info(
        '📻 [CLIENT] Subscribe message sent to channel: "$channelName"',
        _tag,
      );
      return true;
    } catch (e, stackTrace) {
      final errorMsg =
          '❌ [CLIENT] Failed to subscribe to channel "$channelName": $e';
      Logger.error(errorMsg, _tag, e, stackTrace);
      Logger.debug('Stack: ${stackTrace.toString()}', _tag);
      _errorController.add(errorMsg);
      return false;
    }
  }

  /// Unsubscribe from a channel
  void unsubscribeFromChannel(String channelName) {
    if (!_isConnected) {
      Logger.warning('Cannot unsubscribe: not connected', _tag);
      return;
    }

    try {
      final payload = {
        'event': 'pusher:unsubscribe',
        'data': {'channel': channelName},
      };

      _send(payload);
      Logger.info('Unsubscribed from channel: $channelName', _tag);
    } catch (e, stackTrace) {
      Logger.error('Failed to unsubscribe: $e', _tag, e, stackTrace);
    }
  }

  /// Send a message to the channel
  void sendMessage({
    required String channel,
    required String event,
    required Map<String, dynamic> data,
  }) {
    if (!_isConnected) {
      Logger.warning('Cannot send message: WebSocket not connected', _tag);
      return;
    }

    try {
      final payload = {'event': event, 'channel': channel, 'data': data};

      _send(payload);
      Logger.debug('Message sent: $event', _tag);
    } catch (e, stackTrace) {
      Logger.error('Failed to send message: $e', _tag, e, stackTrace);
    }
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    Logger.info('Disconnecting from WebSocket', _tag);

    _isConnected = false;
    _isConnecting = false;
    _socketId = null;

    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;

    try {
      await _channel.sink.close();
    } catch (e) {
      Logger.warning('Error closing WebSocket: $e', _tag);
    }
  }

  /// Close and clean up resources
  Future<void> dispose() async {
    await disconnect();
    await _eventStreamController.close();
    await _connectionStateController.close();
    await _errorController.close();
  }

  // ============ Private Methods ============

  /// Send data through WebSocket
  void _send(Map<String, dynamic> data) {
    try {
      _channel.sink.add(jsonEncode(data));
    } catch (e) {
      Logger.error('Failed to send data: $e', _tag, e);
      rethrow;
    }
  }

  /// Handle incoming WebSocket message
  void _handleMessage(dynamic message) {
    try {
      Logger.debug(
        '📥 [TRACE] Raw message received (type: ${message.runtimeType})',
        _tag,
      );

      final decodedMessage = json.decode(message as String);

      // Log the raw message from server
      Logger.info(
        '📨 [SERVER] Raw message: ${jsonEncode(decodedMessage)}',
        _tag,
      );

      // Handle Pusher protocol messages
      final event = decodedMessage['event'] as String?;
      final channel = decodedMessage['channel'] as String?;
      final data = decodedMessage['data'];

      Logger.info(
        '📡 [SERVER] Event: "$event" | Channel: "${channel ?? 'N/A'}" | Data type: ${data.runtimeType}',
        _tag,
      );

      if (event == 'pusher:connection_established') {
        Logger.debug(
          '🔄 [TRACE] Routing to _handleConnectionEstablished',
          _tag,
        );
        _handleConnectionEstablished(decodedMessage);
      } else if (event == 'pusher:ping') {
        Logger.debug('🔄 [TRACE] Routing to _handlePing', _tag);
        _handlePing();
      } else if (event == 'pusher_internal:subscription_succeeded' ||
          event == 'pusher:subscription_succeeded') {
        Logger.debug(
          '🔄 [TRACE] Routing to _handleSubscriptionSucceeded',
          _tag,
        );
        _handleSubscriptionSucceeded(decodedMessage);
      } else {
        // Handle app-specific events
        Logger.info(
          '🎯 [SERVER] App event detected. Event: "$event", Channel: "$channel"',
          _tag,
        );
        Logger.debug('🔄 [TRACE] Routing to _handleAppEvent', _tag);
        _handleAppEvent(decodedMessage);
      }
    } catch (e, stackTrace) {
      Logger.error(
        '❌ Error handling WebSocket message: $e',
        _tag,
        e,
        stackTrace,
      );
      Logger.debug('Stack: ${stackTrace.toString()}', _tag);
    }
  }

  /// Handle connection established message
  void _handleConnectionEstablished(Map<String, dynamic> message) {
    try {
      Logger.info('🔗 [SERVER] Connection established message received', _tag);
      Logger.debug('Full message: ${jsonEncode(message)}', _tag);

      final data = message['data'] is String
          ? json.decode(message['data'] as String)
          : message['data'] as Map<String, dynamic>;

      _socketId = data['socket_id'] as String?;
      _isConnected = true;
      _reconnectAttempts = 0;

      Logger.info(
        '✅ [SERVER] Connection established. socket_id: $_socketId | activity_timeout: ${data['activity_timeout']}',
        _tag,
      );

      _connectionStateController.add(true);
      _eventStreamController.add(
        PusherConnectionEstablishedEvent(socketId: _socketId ?? ''),
      );
    } catch (e, stackTrace) {
      Logger.error(
        '❌ [SERVER] Error parsing connection established: $e',
        _tag,
        e,
        stackTrace,
      );
    }
  }

  /// Handle ping message
  void _handlePing() {
    try {
      _send({'event': 'pusher:pong', 'data': {}});
      Logger.debug('Pong sent', _tag);
    } catch (e, stackTrace) {
      Logger.error('Error sending pong: $e', _tag, e, stackTrace);
    }
  }

  /// Handle subscription succeeded message
  void _handleSubscriptionSucceeded(Map<String, dynamic> message) {
    try {
      final channel = message['channel'] as String?;
      Logger.info(
        '📻 [SERVER] Subscription succeeded for channel: "$channel"',
        _tag,
      );
      Logger.debug('Full message: ${jsonEncode(message)}', _tag);

      _eventStreamController.add(
        PusherSubscriptionSucceededEvent(channel: channel ?? ''),
      );
    } catch (e, stackTrace) {
      Logger.error(
        '❌ [SERVER] Error handling subscription succeeded: $e',
        _tag,
        e,
        stackTrace,
      );
    }
  }

  /// Handle app-specific events
  void _handleAppEvent(Map<String, dynamic> message) {
    try {
      Logger.debug(
        '🔄 [TRACE] _handleAppEvent called with message keys: ${message.keys.toList()}',
        _tag,
      );

      final data = message['data'] is String
          ? json.decode(message['data'] as String)
          : message['data'];

      Logger.info('💾 [SERVER] Raw app event data: ${jsonEncode(data)}', _tag);

      if (data is! Map<String, dynamic>) {
        Logger.warning(
          '⚠️ [SERVER] Invalid app event data type: ${data.runtimeType}',
          _tag,
        );
        Logger.debug('Data value: $data', _tag);
        Logger.debug('🔴 [TRACE] Cannot parse non-Map data', _tag);
        return;
      }

      Logger.debug('🔄 [TRACE] Data is Map, attempting to parse event', _tag);

      // Try to parse the event
      try {
        Logger.debug(
          '🔄 [TRACE] Calling WebSocketEvent.fromJson with: ${data.keys.toList()}',
          _tag,
        );

        final event = WebSocketEvent.fromJson(data);

        Logger.info(
          '✅ [SERVER] Event parsed successfully: ${event.runtimeType}',
          _tag,
        );
        Logger.debug('Event details: ${jsonEncode(event)}', _tag);
        Logger.debug('🔄 [TRACE] Adding event to stream', _tag);

        _eventStreamController.add(event);

        Logger.debug('✅ [TRACE] Event successfully added to stream', _tag);
      } catch (parseError, parseStack) {
        Logger.warning('⚠️ [SERVER] Failed to parse event: $parseError', _tag);
        Logger.debug('Failed data keys: ${data.keys.toList()}', _tag);
        Logger.debug('Failed data: ${jsonEncode(data)}', _tag);
        Logger.debug('Parse stack: $parseStack', _tag);
      }
    } catch (e, stackTrace) {
      Logger.error(
        '❌ [SERVER] Error handling app event: $e',
        _tag,
        e,
        stackTrace,
      );
      Logger.debug('Stack: ${stackTrace.toString()}', _tag);
    }
  }

  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    final errorMsg = '❌ [SERVER] WebSocket error: $error';
    Logger.error(errorMsg, _tag, error);
    Logger.debug('Error type: ${error.runtimeType}', _tag);
    _errorController.add(errorMsg);

    if (!_isConnected) {
      _attemptReconnect();
    }
  }

  /// Handle WebSocket close
  void _handleClose() {
    Logger.warning('🔌 [SERVER] WebSocket connection closed', _tag);
    _isConnected = false;
    _connectionStateController.add(false);

    _attemptReconnect();
  }

  /// Attempt to reconnect
  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      Logger.error('Max reconnection attempts reached. Giving up.', _tag);
      _errorController.add(
        'Failed to connect after $_maxReconnectAttempts attempts',
      );
      return;
    }

    _reconnectAttempts++;
    Logger.info(
      'Attempting to reconnect... (attempt $_reconnectAttempts/$_maxReconnectAttempts)',
      _tag,
    );

    _reconnectTimer = Timer(_reconnectDelay, () {
      if (_userToken != null && _userId != null) {
        connect(token: _userToken!, userId: _userId!);
      }
    });
  }
}
