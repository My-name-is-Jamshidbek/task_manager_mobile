import 'package:flutter/foundation.dart';
import '../../data/models/conversation_details.dart';
import '../../data/models/message.dart';
import '../../data/models/chat_enums.dart';
import '../../data/services/conversation_details_api_service.dart';
import '../../core/utils/logger.dart';

class ConversationDetailsProvider extends ChangeNotifier {
  final ConversationDetailsApiService _apiService;

  ConversationDetailsProvider({ConversationDetailsApiService? apiService})
    : _apiService = apiService ?? ConversationDetailsApiService();

  // Current conversation details state
  ConversationDetails? _currentConversation;
  bool _isLoading = false;
  String? _error;

  // Sending message state
  bool _isSendingMessage = false;
  String? _sendMessageError;

  // Mark as read state
  bool _isMarkingAsRead = false;
  String? _markAsReadError;

  // Getters
  ConversationDetails? get currentConversation => _currentConversation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSendingMessage => _isSendingMessage;
  String? get sendMessageError => _sendMessageError;
  bool get isMarkingAsRead => _isMarkingAsRead;
  String? get markAsReadError => _markAsReadError;

  /// Load conversation details
  Future<void> loadConversationDetails(int conversationId) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Logger.info('📋 Loading conversation details for ID: $conversationId');

      final conversationDetails = await _apiService.getConversationDetails(
        conversationId,
      );

      _currentConversation = conversationDetails;

      Logger.info(
        '✅ Loaded conversation with ${conversationDetails.messagesCount} messages',
      );
    } catch (e) {
      _error = e.toString();
      Logger.error(
        '❌ Failed to load conversation details',
        'ConversationDetailsProvider',
        e,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send a message to the current conversation
  Future<bool> sendMessage({
    required String message,
    List<String>? files,
  }) async {
    if (_isSendingMessage || _currentConversation == null) return false;

    _isSendingMessage = true;
    _sendMessageError = null;
    notifyListeners();

    try {
      Logger.info(
        '📤 Sending message to conversation ID: ${_currentConversation!.id}',
      );

      final sentMessage = await _apiService.sendMessage(
        conversationId: _currentConversation!.id,
        message: message,
        files: files,
      );

      // Add the sent message to the current conversation
      final updatedMessages = List<ConversationMessage>.from(
        _currentConversation!.messages,
      );
      updatedMessages.add(sentMessage);

      _currentConversation = ConversationDetails(
        id: _currentConversation!.id,
        type: _currentConversation!.type,
        partner: _currentConversation!.partner,
        messages: updatedMessages,
      );

      Logger.info('✅ Message sent successfully');
      return true;
    } catch (e) {
      _sendMessageError = e.toString();
      Logger.error(
        '❌ Failed to send message',
        'ConversationDetailsProvider',
        e,
      );
      return false;
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  /// Mark conversation as read
  Future<bool> markAsRead() async {
    if (_isMarkingAsRead || _currentConversation == null) return false;

    _isMarkingAsRead = true;
    _markAsReadError = null;
    notifyListeners();

    try {
      Logger.info(
        '📖 Marking conversation as read - ID: ${_currentConversation!.id}',
      );

      final success = await _apiService.markConversationAsRead(
        _currentConversation!.id,
      );

      if (success) {
        // Update all messages as read in local state
        final updatedMessages = _currentConversation!.messages.map((message) {
          return ConversationMessage(
            id: message.id,
            body: message.body,
            conversationId: message.conversationId,
            isRead: true, // Mark as read
            sender: message.sender,
            createdAt: message.createdAt,
            files: message.files,
          );
        }).toList();

        _currentConversation = ConversationDetails(
          id: _currentConversation!.id,
          type: _currentConversation!.type,
          partner: _currentConversation!.partner,
          messages: updatedMessages,
        );

        Logger.info('✅ Conversation marked as read successfully');
      }

      return success;
    } catch (e) {
      _markAsReadError = e.toString();
      Logger.error(
        '❌ Failed to mark conversation as read',
        'ConversationDetailsProvider',
        e,
      );
      return false;
    } finally {
      _isMarkingAsRead = false;
      notifyListeners();
    }
  }

  /// Refresh conversation details
  Future<void> refreshConversation() async {
    if (_currentConversation != null) {
      await loadConversationDetails(_currentConversation!.id);
    }
  }

  /// Merge an incoming real-time message into the current conversation
  void handleRealtimeMessage(Message message) {
    if (_currentConversation == null) {
      return;
    }

    final currentConversationId = _currentConversation!.id.toString();
    if (message.chatId != currentConversationId) {
      return;
    }

    final incomingMessageId = int.tryParse(message.id);
    final alreadyExists = incomingMessageId != null
        ? _currentConversation!.messages.any(
            (existing) => existing.id == incomingMessageId,
          )
        : false;

    if (alreadyExists) {
      Logger.debug(
        'Realtime message $incomingMessageId already present - skipping merge',
      );
      return;
    }

    final messageSender = MessageSender(
      id: int.tryParse(message.senderId) ?? 0,
      name: message.senderName ?? '',
      phone: '',
      email: '',
      roles: const [],
      createdAt: message.sentAt.toIso8601String(),
      updatedAt: message.sentAt.toIso8601String(),
    );

    final conversationMessage = ConversationMessage(
      id: incomingMessageId ?? DateTime.now().millisecondsSinceEpoch,
      body: message.content,
      conversationId: _currentConversation!.id,
      isRead: message.status == MessageStatus.read,
      sender: messageSender,
      createdAt: message.sentAt.toIso8601String(),
      files: const <MessageFile>[],
    );

    final updatedMessages = List<ConversationMessage>.from(
      _currentConversation!.messages,
    )..add(conversationMessage);

    _currentConversation = ConversationDetails(
      id: _currentConversation!.id,
      type: _currentConversation!.type,
      partner: _currentConversation!.partner,
      messages: updatedMessages,
    );

    Logger.info(
      'Merged realtime message ${conversationMessage.id} into conversation ${_currentConversation!.id}',
    );

    notifyListeners();
  }

  /// Get messages sorted by date (oldest first for chat display)
  List<ConversationMessage> get sortedMessages {
    if (_currentConversation == null) return [];

    final messages = List<ConversationMessage>.from(
      _currentConversation!.messages,
    );
    messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return messages;
  }

  /// Get partner information
  ConversationPartner? get partner => _currentConversation?.partner;

  /// Check if conversation has unread messages
  bool get hasUnreadMessages =>
      _currentConversation?.hasUnreadMessages ?? false;

  /// Get unread messages count
  int get unreadCount => _currentConversation?.unreadCount ?? 0;

  /// Get conversation type
  String? get conversationType => _currentConversation?.type;

  /// Check if conversation is direct
  bool get isDirect => _currentConversation?.isDirect ?? false;

  /// Check if conversation is department/group
  bool get isDepartment => _currentConversation?.isDepartment ?? false;

  /// Clear current conversation (useful when navigating away)
  void clearConversation() {
    _currentConversation = null;
    _error = null;
    _sendMessageError = null;
    _markAsReadError = null;
    notifyListeners();
  }

  /// Clear error states
  void clearErrors() {
    _error = null;
    _sendMessageError = null;
    _markAsReadError = null;
    notifyListeners();
  }

  /// Reset all state (useful for logout)
  void reset() {
    _currentConversation = null;
    _isLoading = false;
    _error = null;
    _isSendingMessage = false;
    _sendMessageError = null;
    _isMarkingAsRead = false;
    _markAsReadError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
