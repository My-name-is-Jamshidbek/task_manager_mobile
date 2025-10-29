import 'chat_enums.dart';

/// Message model
class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String? senderName;
  final String? senderAvatarUrl;
  final MessageType type;
  final String content;
  final DateTime sentAt;
  final MessageStatus status;
  final String? replyToId;
  final Message? replyToMessage;
  final List<String>? attachments;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeleted;
  final bool isSending;
  final String? sendError;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.senderName,
    this.senderAvatarUrl,
    required this.type,
    required this.content,
    required this.sentAt,
    this.status = MessageStatus.sent,
    this.replyToId,
    this.replyToMessage,
    this.attachments,
    this.isEdited = false,
    this.editedAt,
    this.isDeleted = false,
    this.isSending = false,
    this.sendError,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Handle Laravel backend format with nested sender
    final sender = json['sender'] as Map<String, dynamic>?;
    final conversationId = json['conversation_id'] ?? json['chat_id'];
    final messageBody = json['body'] ?? json['content'];
    final createdAt = json['created_at'] ?? json['sent_at'];

    return Message(
      id: (json['id'] as dynamic).toString(),
      chatId: (conversationId as dynamic).toString(),
      senderId:
          (sender?['id'] as dynamic)?.toString() ??
          (json['sender_id'] as dynamic)?.toString() ??
          '',
      senderName: sender?['name'] as String? ?? json['sender_name'] as String?,
      senderAvatarUrl:
          sender?['avatar_url'] as String? ??
          json['sender_avatar_url'] as String?,
      type: MessageType.values.firstWhere(
        (e) => e.value == json['type'],
        orElse: () => MessageType.text,
      ),
      content: messageBody as String? ?? '',
      sentAt: DateTime.parse(createdAt as String),
      status: (json['is_read'] as bool?) == true
          ? MessageStatus.read
          : (json['status'] != null
                ? MessageStatus.values.firstWhere(
                    (e) => e.value == json['status'],
                    orElse: () => MessageStatus.sent,
                  )
                : MessageStatus.sent),
      replyToId: json['reply_to_id'] as String?,
      replyToMessage: json['reply_to_message'] != null
          ? Message.fromJson(json['reply_to_message'] as Map<String, dynamic>)
          : null,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isEdited: json['is_edited'] as bool? ?? false,
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'] as String)
          : null,
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar_url': senderAvatarUrl,
      'type': type.value,
      'content': content,
      'sent_at': sentAt.toIso8601String(),
      'status': status.value,
      'reply_to_id': replyToId,
      'reply_to_message': replyToMessage?.toJson(),
      'attachments': attachments,
      'is_edited': isEdited,
      'edited_at': editedAt?.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderAvatarUrl,
    MessageType? type,
    String? content,
    DateTime? sentAt,
    MessageStatus? status,
    String? replyToId,
    Message? replyToMessage,
    List<String>? attachments,
    bool? isEdited,
    DateTime? editedAt,
    bool? isDeleted,
    bool? isSending,
    String? sendError,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      type: type ?? this.type,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
      replyToId: replyToId ?? this.replyToId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      attachments: attachments ?? this.attachments,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isSending: isSending ?? this.isSending,
      sendError: sendError ?? this.sendError,
    );
  }

  /// Check if this message is from the current user
  bool isFromCurrentUser(String currentUserId) {
    return senderId == currentUserId;
  }

  /// Get formatted time for display
  String getFormattedTime() {
    final now = DateTime.now();
    final difference = now.difference(sentAt);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${sentAt.day}/${sentAt.month}/${sentAt.year}';
    }
  }

  /// Get preview text for message list
  String getPreviewText() {
    if (isDeleted) {
      return 'This message was deleted';
    }

    switch (type) {
      case MessageType.text:
        return content;
      case MessageType.image:
        return '📷 Image';
      case MessageType.file:
        return '📄 File';
      case MessageType.audio:
        return '🎵 Audio';
      case MessageType.video:
        return '🎥 Video';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
