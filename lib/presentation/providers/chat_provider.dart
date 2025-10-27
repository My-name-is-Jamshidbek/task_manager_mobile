import 'package:flutter/foundation.dart';
import '../../data/models/chat.dart';
import '../../data/models/message.dart';
import '../../data/models/chat_member.dart';
import '../../data/models/chat_enums.dart';
import '../../data/services/conversations_api_service.dart';
import '../../core/utils/logger.dart';

/// Chat provider for managing chat state and operations
class ChatProvider extends ChangeNotifier {
  List<Chat> _chats = [];
  final Map<String, List<Message>> _chatMessages = {};
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;
  ConversationsApiService? _conversationsService;

  // Getters
  List<Chat> get chats => _chats;
  Map<String, List<Message>> get chatMessages => _chatMessages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentUserId => _currentUserId;

  /// Initialize provider with current user ID
  void initialize(String userId) {
    _currentUserId = userId;
    _conversationsService = ConversationsApiService();
    loadChats();
  }

  /// Load all chats for the current user
  Future<void> loadChats() async {
    if (_currentUserId == null || _conversationsService == null) return;

    _setLoading(true);
    _error = null;

    try {
      Logger.info('📱 Loading chats from conversations API...');

      // Load conversations from API and convert to chats
      final conversations = await _conversationsService!.getAllConversations();

      // Convert conversations to chats
      _chats = conversations
          .map((conversation) => conversation.toChat())
          .toList();

      Logger.info('📱 Loaded ${_chats.length} chats from API');
    } catch (e) {
      // Fallback to sample data if API fails
      Logger.warning('⚠️ API failed, using sample data: $e');
      _chats = _generateSampleChats();
      _error = 'Using sample data - API unavailable';
    } finally {
      _setLoading(false);
    }
  }

  /// Load messages for a specific chat
  Future<void> loadMessages(String chatId) async {
    if (_chatMessages.containsKey(chatId)) return;

    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 300));

      _chatMessages[chatId] = _generateSampleMessages(chatId);
      notifyListeners();

      Logger.info(
        '📱 Loaded ${_chatMessages[chatId]?.length ?? 0} messages for chat $chatId',
      );
    } catch (e) {
      Logger.error(
        '❌ Failed to load messages for chat $chatId',
        'ChatProvider',
        e,
      );
    }
  }

  /// Send a new message
  Future<void> sendMessage({
    required String chatId,
    required String content,
    MessageType type = MessageType.text,
    String? replyToId,
    List<String>? attachments,
  }) async {
    if (_currentUserId == null) return;

    try {
      final message = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        chatId: chatId,
        senderId: _currentUserId!,
        senderName: 'You', // TODO: Get from user profile
        type: type,
        content: content,
        sentAt: DateTime.now(),
        status: MessageStatus.sent,
        replyToId: replyToId,
        attachments: attachments,
      );

      // Add to local list
      if (!_chatMessages.containsKey(chatId)) {
        _chatMessages[chatId] = [];
      }
      _chatMessages[chatId]!.add(message);

      // Update chat's last message
      final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
      if (chatIndex != -1) {
        _chats[chatIndex] = _chats[chatIndex].copyWith(
          lastMessage: message,
          updatedAt: DateTime.now(),
        );
      }

      notifyListeners();

      // TODO: Send to API
      Logger.info('📤 Sent message to chat $chatId');
    } catch (e) {
      Logger.error('❌ Failed to send message', 'ChatProvider', e);
    }
  }

  /// Create a new chat
  Future<Chat?> createChat({
    required String name,
    required ChatType type,
    String? description,
    List<String>? memberIds,
  }) async {
    if (_currentUserId == null) return null;

    try {
      final chat = Chat(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        type: type,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        members: [
          ChatMember(
            userId: _currentUserId!,
            displayName: 'You', // TODO: Get from user profile
            role: ChatMemberRole.admin,
            joinedAt: DateTime.now(),
            isOnline: true,
          ),
          ...(memberIds ?? []).map(
            (userId) => ChatMember(
              userId: userId,
              displayName: 'User $userId', // TODO: Get from user API
              role: ChatMemberRole.member,
              joinedAt: DateTime.now(),
            ),
          ),
        ],
        createdBy: _currentUserId,
      );

      _chats.insert(0, chat);
      notifyListeners();

      Logger.info('📱 Created new ${type.value} chat: $name');
      return chat;
    } catch (e) {
      Logger.error('❌ Failed to create chat', 'ChatProvider', e);
      return null;
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    if (!_chatMessages.containsKey(chatId)) return;

    try {
      // Update local messages status
      final messages = _chatMessages[chatId]!;
      for (int i = 0; i < messages.length; i++) {
        if (messages[i].senderId != _currentUserId &&
            messages[i].status != MessageStatus.read) {
          messages[i] = messages[i].copyWith(status: MessageStatus.read);
        }
      }

      // Clear unread count for chat
      final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
      if (chatIndex != -1) {
        _chats[chatIndex] = _chats[chatIndex].copyWith(unreadCount: 0);
      }

      notifyListeners();

      // TODO: Send read status to API
      Logger.info('✅ Marked messages as read for chat $chatId');
    } catch (e) {
      Logger.error('❌ Failed to mark messages as read', 'ChatProvider', e);
    }
  }

  /// Get messages for a specific chat
  List<Message> getMessagesForChat(String chatId) {
    return _chatMessages[chatId] ?? [];
  }

  /// Get unread count for all chats
  int get totalUnreadCount {
    return _chats.fold(0, (sum, chat) => sum + chat.unreadCount);
  }

  /// Filter chats by type
  List<Chat> getChatsByType(ChatType type) {
    return _chats.where((chat) => chat.type == type).toList();
  }

  /// Merge a real-time message into chat state
  void handleRealtimeMessage(Message message) {
    final chatId = message.chatId;
    final isFromCurrentUser = message.senderId == _currentUserId;

    final messages = _chatMessages.putIfAbsent(chatId, () => []);
    final exists = messages.any((existing) => existing.id == message.id);
    if (!exists) {
      messages.add(message);
    }

    final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      final chat = _chats[chatIndex];
      final updatedUnread = isFromCurrentUser
          ? chat.unreadCount
          : chat.unreadCount + (exists ? 0 : 1);

      _chats[chatIndex] = chat.copyWith(
        lastMessage: message,
        unreadCount: updatedUnread,
        updatedAt: message.sentAt,
      );
    }

    notifyListeners();
  }

  /// Search chats by name
  List<Chat> searchChats(String query) {
    if (query.isEmpty) return _chats;

    return _chats.where((chat) {
      final name = chat
          .getDisplayName(currentUserId: _currentUserId)
          .toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();
  }

  /// Pin/Unpin a chat
  Future<void> toggleChatPin(String chatId) async {
    final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex == -1) return;

    try {
      final chat = _chats[chatIndex];
      _chats[chatIndex] = chat.copyWith(isPinned: !chat.isPinned);

      // Sort chats (pinned first)
      _chats.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });

      notifyListeners();

      // TODO: Send to API
      Logger.info('📌 Toggled pin for chat $chatId');
    } catch (e) {
      Logger.error('❌ Failed to toggle pin', 'ChatProvider', e);
    }
  }

  /// Mute/Unmute a chat
  Future<void> toggleChatMute(String chatId) async {
    final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex == -1) return;

    try {
      final chat = _chats[chatIndex];
      _chats[chatIndex] = chat.copyWith(isMuted: !chat.isMuted);
      notifyListeners();

      // TODO: Send to API
      Logger.info('🔇 Toggled mute for chat $chatId');
    } catch (e) {
      Logger.error('❌ Failed to toggle mute', 'ChatProvider', e);
    }
  }

  /// Delete a chat
  Future<void> deleteChat(String chatId) async {
    try {
      _chats.removeWhere((chat) => chat.id == chatId);
      _chatMessages.remove(chatId);
      notifyListeners();

      // TODO: Send to API
      Logger.info('🗑️ Deleted chat $chatId');
    } catch (e) {
      Logger.error('❌ Failed to delete chat', 'ChatProvider', e);
    }
  }

  /// Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Generate sample chats for demo
  List<Chat> _generateSampleChats() {
    return [
      Chat(
        id: '1',
        name: 'John Doe',
        type: ChatType.oneToOne,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        lastMessage: Message(
          id: 'msg1',
          chatId: '1',
          senderId: 'user2',
          senderName: 'John Doe',
          type: MessageType.text,
          content: 'Hey! How are you doing?',
          sentAt: DateTime.now().subtract(const Duration(minutes: 15)),
          status: MessageStatus.delivered,
        ),
        unreadCount: 2,
        members: [
          ChatMember(
            userId: _currentUserId!,
            displayName: 'You',
            role: ChatMemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 2)),
            isOnline: true,
          ),
          ChatMember(
            userId: 'user2',
            displayName: 'John Doe',
            role: ChatMemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 2)),
            isOnline: false,
            lastSeenAt: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ],
      ),
      Chat(
        id: '2',
        name: 'Project Team',
        type: ChatType.group,
        description: 'Task Manager Project Discussion',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        lastMessage: Message(
          id: 'msg2',
          chatId: '2',
          senderId: 'user3',
          senderName: 'Alice Smith',
          type: MessageType.text,
          content: 'Great work on the new features!',
          sentAt: DateTime.now().subtract(const Duration(hours: 2)),
          status: MessageStatus.read,
        ),
        unreadCount: 0,
        isPinned: true,
        members: [
          ChatMember(
            userId: _currentUserId!,
            displayName: 'You',
            role: ChatMemberRole.admin,
            joinedAt: DateTime.now().subtract(const Duration(days: 5)),
            isOnline: true,
          ),
          ChatMember(
            userId: 'user3',
            displayName: 'Alice Smith',
            role: ChatMemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 4)),
            isOnline: true,
          ),
          ChatMember(
            userId: 'user4',
            displayName: 'Bob Johnson',
            role: ChatMemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 3)),
            isOnline: false,
            lastSeenAt: DateTime.now().subtract(const Duration(hours: 6)),
          ),
        ],
        createdBy: _currentUserId,
      ),
      Chat(
        id: '3',
        name: 'Sarah Wilson',
        type: ChatType.oneToOne,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 8)),
        lastMessage: Message(
          id: 'msg3',
          chatId: '3',
          senderId: _currentUserId!,
          senderName: 'You',
          type: MessageType.text,
          content: 'Thanks for the update!',
          sentAt: DateTime.now().subtract(const Duration(hours: 8)),
          status: MessageStatus.read,
        ),
        unreadCount: 0,
        members: [
          ChatMember(
            userId: _currentUserId!,
            displayName: 'You',
            role: ChatMemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 1)),
            isOnline: true,
          ),
          ChatMember(
            userId: 'user5',
            displayName: 'Sarah Wilson',
            role: ChatMemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 1)),
            isOnline: true,
          ),
        ],
      ),
    ];
  }

  /// Generate sample messages for demo
  List<Message> _generateSampleMessages(String chatId) {
    switch (chatId) {
      case '1':
        return [
          Message(
            id: 'msg1_1',
            chatId: chatId,
            senderId: _currentUserId!,
            senderName: 'You',
            type: MessageType.text,
            content: 'Hello! How are you?',
            sentAt: DateTime.now().subtract(const Duration(hours: 2)),
            status: MessageStatus.read,
          ),
          Message(
            id: 'msg1_2',
            chatId: chatId,
            senderId: 'user2',
            senderName: 'John Doe',
            type: MessageType.text,
            content: 'Hey! I\'m doing great, thanks for asking!',
            sentAt: DateTime.now().subtract(const Duration(minutes: 90)),
            status: MessageStatus.delivered,
          ),
          Message(
            id: 'msg1_3',
            chatId: chatId,
            senderId: 'user2',
            senderName: 'John Doe',
            type: MessageType.text,
            content: 'How about you? Working on anything interesting?',
            sentAt: DateTime.now().subtract(const Duration(minutes: 15)),
            status: MessageStatus.delivered,
          ),
        ];
      case '2':
        return [
          Message(
            id: 'msg2_1',
            chatId: chatId,
            senderId: _currentUserId!,
            senderName: 'You',
            type: MessageType.text,
            content: 'Hey team! How\'s the progress on the new features?',
            sentAt: DateTime.now().subtract(const Duration(hours: 4)),
            status: MessageStatus.read,
          ),
          Message(
            id: 'msg2_2',
            chatId: chatId,
            senderId: 'user3',
            senderName: 'Alice Smith',
            type: MessageType.text,
            content: 'Looking good! I just finished the UI updates.',
            sentAt: DateTime.now().subtract(const Duration(hours: 3)),
            status: MessageStatus.read,
          ),
          Message(
            id: 'msg2_3',
            chatId: chatId,
            senderId: 'user4',
            senderName: 'Bob Johnson',
            type: MessageType.text,
            content:
                'API integration is almost complete. Should be ready by tomorrow.',
            sentAt: DateTime.now().subtract(
              const Duration(hours: 2, minutes: 30),
            ),
            status: MessageStatus.read,
          ),
          Message(
            id: 'msg2_4',
            chatId: chatId,
            senderId: 'user3',
            senderName: 'Alice Smith',
            type: MessageType.text,
            content: 'Great work on the new features!',
            sentAt: DateTime.now().subtract(const Duration(hours: 2)),
            status: MessageStatus.read,
          ),
        ];
      case '3':
        return [
          Message(
            id: 'msg3_1',
            chatId: chatId,
            senderId: 'user5',
            senderName: 'Sarah Wilson',
            type: MessageType.text,
            content: 'Hi! Just wanted to update you on the project status.',
            sentAt: DateTime.now().subtract(const Duration(hours: 9)),
            status: MessageStatus.read,
          ),
          Message(
            id: 'msg3_2',
            chatId: chatId,
            senderId: _currentUserId!,
            senderName: 'You',
            type: MessageType.text,
            content: 'Thanks for the update!',
            sentAt: DateTime.now().subtract(const Duration(hours: 8)),
            status: MessageStatus.read,
          ),
        ];
      default:
        return [];
    }
  }
}
