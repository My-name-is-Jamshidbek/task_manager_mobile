import 'chat.dart';
import 'message.dart';
import 'chat_enums.dart';

class Conversation {
  final int id;
  final String type;
  final String title;
  final String? avatar;
  final String? lastMessage;
  final String? lastMessageTime;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.type,
    required this.title,
    this.avatar,
    this.lastMessage,
    this.lastMessageTime,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      avatar: json['avatar'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageTime: json['last_message_time'] as String?,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'avatar': avatar,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime,
      'unread_count': unreadCount,
    };
  }

  /// Convert to Chat model for compatibility with existing UI
  Chat toChat() {
    return Chat(
      id: id.toString(),
      name: title,
      type: type == 'direct' ? ChatType.oneToOne : ChatType.group,
      description: null,
      avatarUrl: avatar,
      createdAt: DateTime.now(), // API doesn't provide this
      updatedAt: DateTime.now(), // API doesn't provide this
      members: [], // Will be loaded separately if needed
      lastMessage: lastMessage != null
          ? Message(
              id: 'last_$id',
              chatId: id.toString(),
              senderId: 'api_sender', // API doesn't provide specific sender ID
              senderName: _extractSenderName(lastMessage!),
              content: _extractMessageContent(lastMessage!),
              type: MessageType.text,
              sentAt: _parseLastMessageTime(lastMessageTime),
              status: MessageStatus.delivered,
            )
          : null,
      unreadCount: unreadCount,
      isPinned: false, // API doesn't provide this
      isMuted: false, // API doesn't provide this
    );
  }

  /// Extract sender name from last message (format: "Sender: message")
  String? _extractSenderName(String lastMessage) {
    if (lastMessage.contains(':')) {
      return lastMessage.split(':').first.trim();
    }
    return null;
  }

  /// Extract message content from last message
  String _extractMessageContent(String lastMessage) {
    if (lastMessage.contains(':')) {
      return lastMessage.split(':').skip(1).join(':').trim();
    }
    return lastMessage;
  }

  /// Parse last message time to DateTime
  DateTime _parseLastMessageTime(String? timeStr) {
    if (timeStr == null) return DateTime.now();

    // Handle relative time formats like "5 daqiqa avval", "2 soat avval"
    final now = DateTime.now();

    if (timeStr.contains('daqiqa avval')) {
      final minutes =
          int.tryParse(timeStr.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
      return now.subtract(Duration(minutes: minutes));
    } else if (timeStr.contains('soat avval')) {
      final hours = int.tryParse(timeStr.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
      return now.subtract(Duration(hours: hours));
    } else if (timeStr.contains('kun avval')) {
      final days = int.tryParse(timeStr.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
      return now.subtract(Duration(days: days));
    }

    // Fallback to current time
    return now;
  }

  /// Create a copy with modified fields
  Conversation copyWith({
    int? id,
    String? type,
    String? title,
    String? avatar,
    String? lastMessage,
    String? lastMessageTime,
    int? unreadCount,
  }) {
    return Conversation(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      avatar: avatar ?? this.avatar,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Conversation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Conversation{id: $id, type: $type, title: $title, unreadCount: $unreadCount}';
  }
}

class ConversationsResponse {
  final List<Conversation> data;
  final Map<String, dynamic> links;
  final ConversationsMeta meta;

  ConversationsResponse({
    required this.data,
    required this.links,
    required this.meta,
  });

  factory ConversationsResponse.fromJson(Map<String, dynamic> json) {
    return ConversationsResponse(
      data: (json['data'] as List)
          .map((item) => Conversation.fromJson(item as Map<String, dynamic>))
          .toList(),
      links: json['links'] as Map<String, dynamic>? ?? {},
      meta: ConversationsMeta.fromJson(
        json['meta'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((conversation) => conversation.toJson()).toList(),
      'links': links,
      'meta': meta.toJson(),
    };
  }
}

class ConversationsMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  ConversationsMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory ConversationsMeta.fromJson(Map<String, dynamic> json) {
    return ConversationsMeta(
      currentPage: json['current_page'] as int? ?? 1,
      lastPage: json['last_page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 15,
      total: json['total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'last_page': lastPage,
      'per_page': perPage,
      'total': total,
    };
  }

  bool get hasMorePages => currentPage < lastPage;
}
