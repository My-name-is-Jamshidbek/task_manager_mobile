import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../managers/websocket_manager.dart';
import '../utils/logger.dart';
import 'websocket_auth_service.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../data/models/realtime/websocket_event_models.dart';

/// Lightweight class that mirrors the debug console behaviour so features can
/// reuse the same connect/subscribe/send flows without duplicating UI code.
class WebSocketRunner {
  final BuildContext context;

  StreamSubscription<WebSocketEvent>? _eventSubscription;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  final ValueNotifier<String?> lastEventSummary = ValueNotifier<String?>(null);
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);
  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);

  WebSocketRunner({required this.context});

  WebSocketManager get _webSocketManager => context.read<WebSocketManager>();

  /// Attach listeners to mirror debug screen logging hooks.
  void attachListeners({void Function(WebSocketEvent event)? onEvent}) {
    _eventSubscription?.cancel();
    _errorSubscription?.cancel();
    _connectionSubscription?.cancel();

    _eventSubscription = _webSocketManager.eventStream.listen((event) {
      lastEventSummary.value = event.runtimeType.toString();
      onEvent?.call(event);
    });

    _errorSubscription = _webSocketManager.errorStream.listen((error) {
      lastError.value = error;
    });

    _connectionSubscription = _webSocketManager.connectionStateStream.listen((
      connected,
    ) {
      isConnected.value = connected;
    });
  }

  /// Clear listeners to avoid leaks.
  void detachListeners() {
    _eventSubscription?.cancel();
    _errorSubscription?.cancel();
    _connectionSubscription?.cancel();
    _eventSubscription = null;
    _errorSubscription = null;
    _connectionSubscription = null;
  }

  /// Connect using current authenticated user session.
  Future<bool> connectWebSocket() async {
    final authProvider = context.read<AuthProvider?>();
    final token = authProvider?.authToken;
    final userId = authProvider?.currentUser?.id;

    if (token == null || userId == null) {
      Logger.warning(
        'WebSocketRunner: connect aborted - missing auth token or user id',
      );
      return false;
    }

    final connected = await _webSocketManager.connect(
      token: token,
      userId: userId,
    );
    if (!connected) {
      Logger.warning(
        'WebSocketRunner: WebSocket connect failed: ${_webSocketManager.lastError}',
      );
    }
    return connected;
  }

  /// Disconnect the underlying WebSocket.
  Future<void> disconnectWebSocket() async {
    await _webSocketManager.disconnect();
  }

  /// Subscribe to a private channel using the same auth flow as debug screen.
  Future<bool> subscribeChannel(String channelName) async {
    final trimmedName = channelName.trim();
    if (trimmedName.isEmpty) {
      Logger.warning('WebSocketRunner: subscribe aborted - channel empty');
      return false;
    }

    final socketId = _webSocketManager.socketId;
    if (socketId == null || socketId.isEmpty) {
      Logger.warning(
        'WebSocketRunner: subscribe aborted - socketId missing (connect first)',
      );
      return false;
    }

    return _webSocketManager.subscribeToChannel(
      channelName: trimmedName,
      onAuthRequired: (name) async {
        final currentSocketId = _webSocketManager.socketId;
        if (currentSocketId == null || currentSocketId.isEmpty) {
          throw Exception('Socket ID unavailable for authorization');
        }
        return WebSocketAuthService.authorize(
          channelName: name,
          socketId: currentSocketId,
        );
      },
    );
  }

  /// Relay sendMessage just like the debug screen.
  void sendMessage({
    required String channel,
    required String event,
    required Map<String, dynamic> data,
  }) {
    _webSocketManager.sendMessage(channel: channel, event: event, data: data);
  }

  /// Dispose runner resources.
  void dispose() {
    detachListeners();
    lastEventSummary.dispose();
    lastError.dispose();
    isConnected.dispose();
  }
}
