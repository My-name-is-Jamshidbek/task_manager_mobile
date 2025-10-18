import 'chat_enums.dart';
import 'message.dart';
import 'chat_member.dart';

/// Chat model
class Chat {
  final String id;
  final String name;
  final ChatType type;
  final String? description;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Message? lastMessage;
  final int unreadCount;
  final List<ChatMember> members;
  final bool isPinned;
  final bool isMuted;
  final bool isArchived;
  final String? createdBy;

  const Chat({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.unreadCount = 0,
    this.members = const [],
    this.isPinned = false,
    this.isMuted = false,
    this.isArchived = false,
    this.createdBy,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ChatType.values.firstWhere(
        (e) => e.value == json['type'],
        orElse: () => ChatType.oneToOne,
      ),
      description: json['description'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastMessage: json['last_message'] != null
          ? Message.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      members:
          (json['members'] as List<dynamic>?)
              ?.map((e) => ChatMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isPinned: json['is_pinned'] as bool? ?? false,
      isMuted: json['is_muted'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.value,
      'description': description,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'members': members.map((e) => e.toJson()).toList(),
      'is_pinned': isPinned,
      'is_muted': isMuted,
      'is_archived': isArchived,
      'created_by': createdBy,
    };
  }

  Chat copyWith({
    String? id,
    String? name,
    ChatType? type,
    String? description,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    Message? lastMessage,
    int? unreadCount,
    List<ChatMember>? members,
    bool? isPinned,
    bool? isMuted,
    bool? isArchived,
    String? createdBy,
  }) {
    return Chat(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      members: members ?? this.members,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
      isArchived: isArchived ?? this.isArchived,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// Get display name for the chat
  String getDisplayName({String? currentUserId}) {
    if (type == ChatType.group) {
      return name;
    }

    // For one-to-one chat, show the other participant's name
    if (currentUserId != null && members.length >= 2) {
      final otherMember = members.firstWhere(
        (member) => member.userId != currentUserId,
        orElse: () => members.isNotEmpty
            ? members.first
            : ChatMember(
                userId: 'unknown',
                displayName: 'Unknown',
                joinedAt: DateTime.now(),
              ),
      );
      return otherMember.displayName ?? otherMember.userId;
    }

    return name;
  }

  /// Get avatar URL for the chat
  String? getAvatarUrl({String? currentUserId}) {
    if (type == ChatType.group || avatarUrl != null) {
      return avatarUrl;
    }

    // For one-to-one chat, show the other participant's avatar
    if (currentUserId != null && members.length >= 2) {
      final otherMember = members.firstWhere(
        (member) => member.userId != currentUserId,
        orElse: () => members.isNotEmpty
            ? members.first
            : ChatMember(
                userId: 'unknown',
                displayName: 'Unknown',
                joinedAt: DateTime.now(),
              ),
      );
      return otherMember.avatarUrl;
    }

    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chat && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
