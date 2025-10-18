import 'contact.dart';

/// Partner information in a conversation
class ConversationPartner {
  final int id;
  final String name;
  final String phone;
  final String email;
  final List<String> roles;
  final String createdAt;
  final String updatedAt;

  ConversationPartner({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.roles,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationPartner.fromJson(Map<String, dynamic> json) {
    return ConversationPartner(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      roles: json['roles'] != null
          ? List<String>.from(json['roles'] as List)
          : <String>[],
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'roles': roles,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Convert to Contact model for UI compatibility
  Contact toContact() {
    return Contact(id: id, name: name, phone: phone);
  }
}

/// File attachment in a message
class MessageFile {
  final int id;
  final String name;
  final String size;
  final String mimeType;
  final bool isImage;
  final String url;
  final String? previewUrl;

  MessageFile({
    required this.id,
    required this.name,
    required this.size,
    required this.mimeType,
    required this.isImage,
    required this.url,
    this.previewUrl,
  });

  factory MessageFile.fromJson(Map<String, dynamic> json) {
    return MessageFile(
      id: json['id'] as int,
      name: json['name'] as String,
      size: json['size'] as String,
      mimeType: json['mime_type'] as String,
      isImage: json['is_image'] as bool,
      url: json['url'] as String,
      previewUrl: json['preview_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'size': size,
      'mime_type': mimeType,
      'is_image': isImage,
      'url': url,
      'preview_url': previewUrl,
    };
  }

  /// Get file extension from name
  String get extension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Check if file is downloadable
  bool get isDownloadable => url.isNotEmpty;

  /// Get display size (formatted)
  String get displaySize => size;
}

/// Message sender information
class MessageSender {
  final int id;
  final String name;
  final String phone;
  final String email;
  final List<String> roles;
  final String createdAt;
  final String updatedAt;

  MessageSender({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.roles,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MessageSender.fromJson(Map<String, dynamic> json) {
    return MessageSender(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      roles: json['roles'] != null
          ? List<String>.from(json['roles'] as List)
          : <String>[],
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'roles': roles,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Get display name for UI
  String get displayName => name.isNotEmpty ? name : phone;
}

/// Individual message in conversation details
class ConversationMessage {
  final int id;
  final String body;
  final int conversationId;
  final bool isRead;
  final MessageSender sender;
  final String createdAt;
  final List<MessageFile> files;

  ConversationMessage({
    required this.id,
    required this.body,
    required this.conversationId,
    required this.isRead,
    required this.sender,
    required this.createdAt,
    required this.files,
  });

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      id: json['id'] as int,
      body: json['body'] as String? ?? '',
      conversationId: json['conversation_id'] as int,
      isRead: json['is_read'] as bool? ?? false,
      sender: MessageSender.fromJson(json['sender'] as Map<String, dynamic>),
      createdAt: json['created_at'] as String? ?? '',
      files: (json['files'] as List? ?? [])
          .map((file) => MessageFile.fromJson(file as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'body': body,
      'conversation_id': conversationId,
      'is_read': isRead,
      'sender': sender.toJson(),
      'created_at': createdAt,
      'files': files.map((file) => file.toJson()).toList(),
    };
  }

  /// Parse created_at string to DateTime
  DateTime get sentAt {
    try {
      return DateTime.parse(createdAt);
    } catch (e) {
      // Fallback to current time if parsing fails
      return DateTime.now();
    }
  }

  /// Check if message has attachments
  bool get hasAttachments => files.isNotEmpty;

  /// Check if message has images
  bool get hasImages => files.any((file) => file.isImage);

  /// Get image files only
  List<MessageFile> get imageFiles =>
      files.where((file) => file.isImage).toList();

  /// Get non-image files only
  List<MessageFile> get documentFiles =>
      files.where((file) => !file.isImage).toList();

  /// Get short preview of message content
  String getPreview({int maxLength = 100}) {
    if (body.length <= maxLength) return body;
    return '${body.substring(0, maxLength)}...';
  }
}

/// Conversation details response from API
class ConversationDetails {
  final int id;
  final String type;
  final ConversationPartner partner;
  final List<ConversationMessage> messages;

  ConversationDetails({
    required this.id,
    required this.type,
    required this.partner,
    required this.messages,
  });

  factory ConversationDetails.fromJson(Map<String, dynamic> json) {
    return ConversationDetails(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? 'direct',
      partner: ConversationPartner.fromJson(
        json['partner'] as Map<String, dynamic>,
      ),
      messages:
          (json['messages'] as List?)
              ?.map(
                (message) => ConversationMessage.fromJson(
                  message as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'partner': partner.toJson(),
      'messages': messages.map((message) => message.toJson()).toList(),
    };
  }

  /// Check if conversation is direct type
  bool get isDirect => type == 'direct';

  /// Check if conversation is department/group type
  bool get isDepartment => type == 'department';

  /// Get unread messages count
  int get unreadCount => messages.where((message) => !message.isRead).length;

  /// Get latest message
  ConversationMessage? get latestMessage {
    if (messages.isEmpty) return null;

    // Sort messages by creation date (latest first) and return first
    final sortedMessages = List<ConversationMessage>.from(messages);
    sortedMessages.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return sortedMessages.isNotEmpty ? sortedMessages.first : null;
  }

  /// Get messages count
  int get messagesCount => messages.length;

  /// Check if conversation has any unread messages
  bool get hasUnreadMessages => unreadCount > 0;
}
