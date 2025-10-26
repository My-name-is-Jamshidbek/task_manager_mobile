import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../core/managers/websocket_manager.dart';
import '../../data/models/realtime/websocket_event_models.dart';
import '../../core/utils/logger.dart';
import '../../core/services/websocket_auth_service.dart';
import '../widgets/websocket_error_dialog.dart';

/// Mixin to integrate WebSocket functionality into chat screens
mixin WebSocketChatMixin<T extends StatefulWidget> on State<T> {
  static const String _tag = 'WebSocketChatMixin';

  late WebSocketManager _webSocketManager;
  late StreamSubscription<WebSocketEvent> _eventSubscription;

  /// Initialize WebSocket connection
  /// Call this in initState of your chat screen
  void initializeWebSocket({
    required String userToken,
    required int userId,
    required String channelName,
    required Function(MessageSentEvent) onMessageReceived,
    required Function(UserIsTypingEvent) onUserTyping,
    required Function(MessagesReadEvent) onMessagesRead,
  }) {
    _webSocketManager = context.read<WebSocketManager>();

    // Listen to WebSocket errors
    _webSocketManager.errorStream.listen((error) {
      _handleWebSocketError(error);
    });

    // Connect to WebSocket
    _connectWebSocket(
      userToken: userToken,
      userId: userId,
      channelName: channelName,
      onMessageReceived: onMessageReceived,
      onUserTyping: onUserTyping,
      onMessagesRead: onMessagesRead,
    );
  }

  /// Connect to WebSocket server
  Future<void> _connectWebSocket({
    required String userToken,
    required int userId,
    required String channelName,
    required Function(MessageSentEvent) onMessageReceived,
    required Function(UserIsTypingEvent) onUserTyping,
    required Function(MessagesReadEvent) onMessagesRead,
  }) async {
    Logger.info('Initializing WebSocket connection', _tag);

    // Connect to WebSocket
    final connected = await _webSocketManager.connect(
      token: userToken,
      userId: userId,
    );

    if (!connected) {
      Logger.error('Failed to connect to WebSocket', _tag);
      if (mounted) {
        showWebSocketErrorSnackbar(
          context,
          message: 'Failed to connect to chat server',
        );
      }
      return;
    }

    // Subscribe to channel
    final subscribed = await _webSocketManager.subscribeToChannel(
      channelName: channelName,
      onAuthRequired: (channel) async {
        // This will be called to authorize the channel
        // You need to implement the actual authorization logic
        return await _authorizeChannel(channel, userToken);
      },
    );

    if (!subscribed) {
      Logger.error('Failed to subscribe to channel: $channelName', _tag);
      if (mounted) {
        showWebSocketErrorSnackbar(
          context,
          message: 'Failed to subscribe to chat channel',
        );
      }
      return;
    }

    // Set up event listeners
    _eventSubscription = _webSocketManager.onEvent((event) {
      if (event is MessageSentEvent) {
        onMessageReceived(event);
      } else if (event is UserIsTypingEvent) {
        onUserTyping(event);
      } else if (event is MessagesReadEvent) {
        onMessagesRead(event);
      }
    });

    Logger.info(
      'WebSocket connection established and subscribed to $channelName',
      _tag,
    );
  }

  /// Authorize channel subscription using ApiClient
  /// This mirrors the user login authentication flow
  Future<String> _authorizeChannel(String channel, String token) async {
    try {
      Logger.info(
        'WebSocketChatMixin: Starting channel authorization for $channel',
        _tag,
      );

      final socketId = _webSocketManager.socketId;
      if (socketId == null || socketId.isEmpty) {
        Logger.error('WebSocketChatMixin: Socket ID not available', _tag);
        throw Exception('Socket ID not available');
      }

      final authToken = await WebSocketAuthService.authorize(
        channelName: channel,
        socketId: socketId,
      );

      Logger.info('WebSocketChatMixin: Channel authorization successful', _tag);
      return authToken;
    } catch (e, stackTrace) {
      Logger.error(
        'WebSocketChatMixin: Channel authorization exception',
        _tag,
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Handle WebSocket errors
  void _handleWebSocketError(String error) {
    Logger.error('WebSocket error: $error', _tag);

    if (!mounted) return;

    // Show error dialog for connection errors
    if (error.contains('connection') || error.contains('Connection')) {
      showWebSocketErrorDialog(
        context,
        title: 'Connection Error',
        message: error,
        errorType: 'connection',
        onRetry: () {
          // Trigger reconnection
          _webSocketManager.disconnect().then((_) {
            // Wait a moment before reconnecting
            Future.delayed(const Duration(seconds: 1), () {
              // The reconnection should be handled by WebSocketManager
              // or you can manually trigger it here
            });
          });
        },
      );
    } else {
      // Show snackbar for other errors
      showWebSocketErrorSnackbar(context, message: error);
    }
  }

  /// Send message through WebSocket (optional, for real-time updates)
  void sendMessageViaWebSocket({
    required String channel,
    required String messageContent,
    required String messageId,
  }) {
    _webSocketManager.sendMessage(
      channel: channel,
      event: 'message:send',
      data: {
        'id': messageId,
        'content': messageContent,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Send typing indicator
  void sendTypingIndicator({required String channel}) {
    _webSocketManager.sendMessage(
      channel: channel,
      event: 'typing:start',
      data: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  /// Dispose WebSocket resources
  /// Call this in dispose of your chat screen
  void disposeWebSocket() {
    Logger.info('Disposing WebSocket resources', _tag);
    _eventSubscription.cancel();
    // Don't disconnect here if you want to keep the connection
    // for other screens. Instead, manage connection lifecycle
    // at the app level.
  }
}
