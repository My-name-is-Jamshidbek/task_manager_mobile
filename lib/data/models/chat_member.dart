import 'chat_enums.dart';

/// Chat member model
class ChatMember {
  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final ChatMemberRole role;
  final DateTime joinedAt;
  final DateTime? lastSeenAt;
  final bool isOnline;
  final bool isMuted;

  const ChatMember({
    required this.userId,
    this.displayName,
    this.avatarUrl,
    this.role = ChatMemberRole.member,
    required this.joinedAt,
    this.lastSeenAt,
    this.isOnline = false,
    this.isMuted = false,
  });

  factory ChatMember.fromJson(Map<String, dynamic> json) {
    return ChatMember(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: ChatMemberRole.values.firstWhere(
        (e) => e.value == json['role'],
        orElse: () => ChatMemberRole.member,
      ),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'] as String)
          : null,
      isOnline: json['is_online'] as bool? ?? false,
      isMuted: json['is_muted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'role': role.value,
      'joined_at': joinedAt.toIso8601String(),
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'is_online': isOnline,
      'is_muted': isMuted,
    };
  }

  ChatMember copyWith({
    String? userId,
    String? displayName,
    String? avatarUrl,
    ChatMemberRole? role,
    DateTime? joinedAt,
    DateTime? lastSeenAt,
    bool? isOnline,
    bool? isMuted,
  }) {
    return ChatMember(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isOnline: isOnline ?? this.isOnline,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  /// Get display name or fallback to user ID
  String get name => displayName ?? userId;

  /// Check if this member is an admin
  bool get isAdmin => role == ChatMemberRole.admin;

  /// Get last seen status for display
  String getLastSeenStatus() {
    if (isOnline) {
      return 'Online';
    }

    if (lastSeenAt == null) {
      return 'Never';
    }

    final now = DateTime.now();
    final difference = now.difference(lastSeenAt!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return 'Long time ago';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMember &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;
}
