import '../message.dart';
import '../user.dart';

/// Base class for WebSocket events
abstract class WebSocketEvent {
  const WebSocketEvent();

  factory WebSocketEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    final data = json['data'] as Map<String, dynamic>?;

    // Check if message comes from Laravel backend (with "message" field directly)
    if (json.containsKey('message') &&
        json['message'] is Map<String, dynamic>) {
      return MessageSentEvent.fromJson(json);
    }

    switch (type) {
      case 'message':
        return MessageSentEvent.fromJson(data ?? json);
      case 'typing':
        return UserIsTypingEvent.fromJson(data ?? {});
      case 'read':
        return MessagesReadEvent.fromJson(data ?? {});
      default:
        return UnknownEvent(type: type, data: data);
    }
  }
}

/// Event for new message sent
class MessageSentEvent extends WebSocketEvent {
  final Message message;
  final String?
  tempId; // Temporary ID used while sending (for client-side matching)

  const MessageSentEvent({required this.message, this.tempId});

  factory MessageSentEvent.fromJson(Map<String, dynamic> json) {
    // Handle Laravel backend format: {"message": {...}}
    if (json.containsKey('message') &&
        json['message'] is Map<String, dynamic>) {
      return MessageSentEvent(
        message: Message.fromJson(json['message'] as Map<String, dynamic>),
        tempId: json['tempId'] as String?,
      );
    }

    // Handle standard format: {"message": {...}, "tempId": "..."}
    return MessageSentEvent(
      message: Message.fromJson(
        json['message'] as Map<String, dynamic>? ?? json,
      ),
      tempId: json['tempId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'message',
      'data': {'message': message.toJson(), 'tempId': tempId},
    };
  }

  @override
  String toString() => 'MessageSentEvent(message: $message, tempId: $tempId)';
}

/// Event for user is typing
class UserIsTypingEvent extends WebSocketEvent {
  final int conversationId;
  final User user;

  const UserIsTypingEvent({required this.conversationId, required this.user});

  factory UserIsTypingEvent.fromJson(Map<String, dynamic> json) {
    return UserIsTypingEvent(
      conversationId: json['conversation_id'] as int? ?? 0,
      user: User.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'typing',
      'data': {'conversation_id': conversationId, 'user': user.toJson()},
    };
  }

  @override
  String toString() =>
      'UserIsTypingEvent(conversationId: $conversationId, user: $user)';
}

/// Event for messages read
class MessagesReadEvent extends WebSocketEvent {
  final int conversationId;
  final int readerId;
  final List<String> messageIds;

  const MessagesReadEvent({
    required this.conversationId,
    required this.readerId,
    required this.messageIds,
  });

  factory MessagesReadEvent.fromJson(Map<String, dynamic> json) {
    return MessagesReadEvent(
      conversationId: json['conversation_id'] as int? ?? 0,
      readerId: json['reader_id'] as int? ?? 0,
      messageIds:
          (json['message_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'read',
      'data': {
        'conversation_id': conversationId,
        'reader_id': readerId,
        'message_ids': messageIds,
      },
    };
  }

  @override
  String toString() =>
      'MessagesReadEvent(conversationId: $conversationId, readerId: $readerId, messageIds: $messageIds)';
}

/// Unknown event type
class UnknownEvent extends WebSocketEvent {
  final String? type;
  final Map<String, dynamic>? data;

  const UnknownEvent({this.type, this.data});

  @override
  String toString() => 'UnknownEvent(type: $type, data: $data)';
}

/// Pusher protocol events
class PusherConnectionEstablishedEvent extends WebSocketEvent {
  final String socketId;

  const PusherConnectionEstablishedEvent({required this.socketId});

  factory PusherConnectionEstablishedEvent.fromJson(Map<String, dynamic> json) {
    return PusherConnectionEstablishedEvent(
      socketId: json['socket_id'] as String? ?? '',
    );
  }

  @override
  String toString() => 'PusherConnectionEstablishedEvent(socketId: $socketId)';
}

/// Pusher subscription succeeded event
class PusherSubscriptionSucceededEvent extends WebSocketEvent {
  final String channel;

  const PusherSubscriptionSucceededEvent({required this.channel});

  factory PusherSubscriptionSucceededEvent.fromJson(Map<String, dynamic> json) {
    return PusherSubscriptionSucceededEvent(
      channel: json['channel'] as String? ?? '',
    );
  }

  @override
  String toString() => 'PusherSubscriptionSucceededEvent(channel: $channel)';
}
