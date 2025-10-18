/// Response model for find-or-create conversation API
class FindOrCreateConversationResponse {
  final int id;
  final String type;
  final String title;
  final String? avatar;
  final String? lastMessage;
  final String? lastMessageTime;
  final int unreadCount;

  FindOrCreateConversationResponse({
    required this.id,
    required this.type,
    required this.title,
    this.avatar,
    this.lastMessage,
    this.lastMessageTime,
    required this.unreadCount,
  });

  factory FindOrCreateConversationResponse.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num?)?.toInt();
    if (id == null || id <= 0) {
      throw FormatException(
        'Invalid conversation ID in API response: ${json['id']}',
      );
    }

    return FindOrCreateConversationResponse(
      id: id,
      type: json['type']?.toString() ?? 'direct',
      title: json['title']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      lastMessage: json['last_message']?.toString(),
      lastMessageTime: json['last_message_time']?.toString(),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
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

  /// Convert to existing Conversation model for UI compatibility
  /// This requires importing the conversation model
  Map<String, dynamic> toConversationJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'avatar': avatar,
      'last_message': lastMessage != null
          ? {'content': lastMessage, 'created_at': lastMessageTime}
          : null,
      'last_message_time': lastMessageTime,
      'unread_count': unreadCount,
    };
  }

  /// Check if this is a direct conversation
  bool get isDirect => type == 'direct';

  /// Check if this is a department/group conversation
  bool get isDepartment => type == 'department';

  /// Get display title
  String get displayTitle => title;

  /// Check if conversation has unread messages
  bool get hasUnreadMessages => unreadCount > 0;

  /// Get formatted last message preview
  String get lastMessagePreview {
    if (lastMessage == null || lastMessage!.isEmpty) {
      return 'No messages yet';
    }

    // Truncate long messages
    const maxLength = 50;
    if (lastMessage!.length <= maxLength) {
      return lastMessage!;
    }

    return '${lastMessage!.substring(0, maxLength)}...';
  }

  /// Get formatted last message time
  String get formattedLastMessageTime {
    if (lastMessageTime == null || lastMessageTime!.isEmpty) {
      return '';
    }

    // Return as-is since API already provides formatted time
    return lastMessageTime!;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FindOrCreateConversationResponse &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FindOrCreateConversationResponse{id: $id, type: $type, title: $title, unreadCount: $unreadCount}';
  }
}
