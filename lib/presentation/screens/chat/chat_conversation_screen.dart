import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/managers/websocket_manager.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/chat.dart';
import '../../../data/models/message.dart';
import '../../../data/models/conversation_details.dart';
import '../../../data/models/chat_enums.dart';
import '../../../data/models/realtime/websocket_event_models.dart';
import '../../providers/chat_provider.dart';
import '../../providers/conversation_details_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/message_input.dart';
import '../../widgets/chat/chat_app_bar.dart';

class ChatConversationScreen extends StatefulWidget {
  final Chat chat;
  final int? conversationId; // Optional API conversation ID

  const ChatConversationScreen({
    super.key,
    required this.chat,
    this.conversationId,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = true;
  bool _showScrollToBottom = false;
  late final WebSocketManager _webSocketManager;
  StreamSubscription<WebSocketEvent>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _webSocketManager = context.read<WebSocketManager>();
    _scrollController.addListener(_handleScroll);
    _attachWebSocketListeners();
    _loadMessages();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _attachWebSocketListeners() {
    final conversationKey = widget.conversationId?.toString() ?? widget.chat.id;

    _eventSubscription = _webSocketManager.eventStream.listen((event) {
      if (!mounted) {
        return;
      }

      if (event is MessageSentEvent) {
        final incomingChatId = event.message.chatId;
        if (incomingChatId != conversationKey) {
          Logger.debug(
            'Realtime event for chat $incomingChatId ignored by conversation $conversationKey',
          );
          return;
        }

        if (widget.conversationId != null) {
          context.read<ConversationDetailsProvider>().handleRealtimeMessage(
            event.message,
            tempId: event.tempId,
          );
        } else {
          context.read<ChatProvider>().handleRealtimeMessage(
            event.message,
            tempId: event.tempId,
          );
        }

        final currentUserId = context.read<AuthProvider?>()?.currentUser?.id;
        if (currentUserId != null &&
            event.message.senderId != currentUserId.toString()) {
          unawaited(_markMessagesAsRead([event.message.id]));
        }

        if (!_showScrollToBottom) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _scrollToBottom();
            }
          });
        }
        return;
      }

      if (event is MessagesReadEvent) {
        final incomingConversationId = event.conversationId.toString();
        if (incomingConversationId != conversationKey) {
          return;
        }

        final messageIds = event.messageIds.map((id) => id.toString()).toList();
        if (messageIds.isEmpty) {
          return;
        }

        if (widget.conversationId != null) {
          context.read<ConversationDetailsProvider>().handleMessagesRead(
            messageIds,
            event.readerId,
          );
        }

        context.read<ChatProvider>().handleMessagesRead(
          conversationKey,
          messageIds,
          readerId: event.readerId,
        );
      }
    });
  }

  Future<void> _loadMessages() async {
    try {
      if (widget.conversationId != null) {
        // Use conversation details API for real data
        final conversationDetailsProvider = context
            .read<ConversationDetailsProvider>();
        final authProvider = context.read<AuthProvider>();
        final currentUserId = authProvider.currentUser?.id;

        Logger.info('📖 Loading conversation ${widget.conversationId}');

        await conversationDetailsProvider.loadConversationDetails(
          widget.conversationId!,
        );

        // Mark only OTHER users' unread messages as read
        if (currentUserId != null) {
          final unreadFromOthers =
              conversationDetailsProvider.currentConversation?.messages
                  .where((msg) => msg.sender.id != currentUserId && !msg.isRead)
                  .map((msg) => msg.id.toString())
                  .toList() ??
              [];

          Logger.info(
            '📖 Found ${unreadFromOthers.length} unread messages from others',
          );

          if (unreadFromOthers.isNotEmpty) {
            await _markMessagesAsRead(unreadFromOthers);
          }
        } else {
          Logger.warning('⚠️ Current user ID is null, skipping read marking');
        }
      } else {
        // Fallback to existing chat provider for sample data
        final chatProvider = context.read<ChatProvider>();
        await chatProvider.loadMessages(widget.chat.id);
        final authProvider = context.read<AuthProvider>();
        final currentUserId = authProvider.currentUser?.id;

        // Mark only OTHER users' unread messages as read
        if (currentUserId != null) {
          final messages = chatProvider.chatMessages[widget.chat.id] ?? [];
          final unreadFromOthers = messages
              .where(
                (msg) =>
                    msg.senderId != currentUserId.toString() &&
                    msg.status != MessageStatus.read,
              )
              .map((msg) => msg.id)
              .toList();

          if (unreadFromOthers.isNotEmpty) {
            await chatProvider.markMessagesAsRead(
              widget.chat.id,
              messageIds: unreadFromOthers,
            );
          }
        }
      }
    } catch (e, stackTrace) {
      Logger.error(
        '❌ Error loading messages or marking as read',
        'ChatConversationScreen',
        e,
        stackTrace,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Scroll to bottom after layout is complete
        // Use multiple callbacks to ensure the ListView is fully laid out
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scrollToBottom();
          }
        });

        // Add a slight delay and try again to ensure we reach the actual bottom
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _scrollController.hasClients) {
            _scrollToBottom();
          }
        });
      }
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      Logger.debug('ScrollController has no clients yet');
      return;
    }

    try {
      final target = _scrollController.position.maxScrollExtent;

      _scrollController
          .animateTo(
            target,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          )
          .catchError((error) {
            // Fallback to jumpTo if animation fails
            Logger.debug('Scroll animation failed, jumping to bottom: $error');
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(
                _scrollController.position.maxScrollExtent,
              );
            }
          });

      if (mounted && _showScrollToBottom) {
        setState(() {
          _showScrollToBottom = false;
        });
      }
    } catch (e) {
      Logger.warning('Error scrolling to bottom: $e');
    }
  }

  void _handleScroll() {
    if (!mounted || !_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final maxExtent = position.maxScrollExtent;
    final offset = position.pixels;
    final distanceFromBottom = maxExtent - offset;

    final shouldShow = offset > 50 && distanceFromBottom > 120;

    if (_showScrollToBottom != shouldShow) {
      setState(() {
        _showScrollToBottom = shouldShow;
      });
    }

    // Mark visible unread messages as read
    _markVisibleMessagesAsRead();
  }

  /// Mark unread messages that are in viewport as read
  void _markVisibleMessagesAsRead() {
    if (widget.conversationId == null) {
      return; // Only for API conversations
    }

    final conversationDetailsProvider = context
        .read<ConversationDetailsProvider>();
    final messages = conversationDetailsProvider.sortedMessages;
    final currentUserId = context.read<AuthProvider?>()?.currentUser?.id;

    Logger.debug(
      '🔍 _markVisibleMessagesAsRead: ${messages.length} messages, currentUserId: $currentUserId',
    );

    if (messages.isEmpty || currentUserId == null) {
      Logger.debug('⚠️ No messages or currentUserId is null');
      return;
    }

    final controller = _scrollController;
    if (!controller.hasClients) {
      Logger.debug('⚠️ Scroll controller has no clients');
      return;
    }

    final viewportHeight = MediaQuery.of(context).size.height;
    final scrollOffset = controller.offset;
    final viewportTop = scrollOffset;
    final viewportBottom = scrollOffset + viewportHeight;

    Logger.debug(
      '📏 Viewport: top=$viewportTop, bottom=$viewportBottom, height=$viewportHeight',
    );

    // Find unread messages from other users that are in the viewport
    final visibleUnreadMessageIds = <String>[];

    // Estimate item height (approximate)
    const itemHeight = 80.0;

    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];

      // Only mark messages from other users as read
      if (message.sender.id == currentUserId) {
        Logger.debug('⏭️ Message $i from current user, skipping');
        continue;
      }

      // Skip if already read
      if (message.isRead) {
        Logger.debug('✅ Message $i already read, skipping');
        continue;
      }

      // Calculate approximate position of this item
      final itemTop = i * itemHeight + 16; // 16 = top padding
      final itemBottom = itemTop + itemHeight;

      Logger.debug(
        '📍 Message $i (ID: ${message.id}): top=$itemTop, bottom=$itemBottom',
      );

      // Check if item is in viewport
      if (itemBottom > viewportTop && itemTop < viewportBottom) {
        Logger.info('📖 Message $i (ID: ${message.id}) is VISIBLE and UNREAD');
        visibleUnreadMessageIds.add(message.id.toString());
      } else {
        Logger.debug('❌ Message $i not in viewport');
      }
    }

    Logger.info(
      '📊 Found ${visibleUnreadMessageIds.length} visible unread messages: $visibleUnreadMessageIds',
    );

    // Mark visible unread messages as read
    if (visibleUnreadMessageIds.isNotEmpty) {
      Logger.info(
        '🚀 Calling _markMessagesAsRead with ${visibleUnreadMessageIds.length} IDs',
      );
      unawaited(_markMessagesAsRead(visibleUnreadMessageIds));
    } else {
      Logger.debug('ℹ️ No visible unread messages to mark');
    }
  }

  Future<void> _markMessagesAsRead(List<String> messageIds) async {
    if (messageIds.isEmpty) {
      Logger.debug('⚠️ _markMessagesAsRead called with empty list');
      return;
    }

    Logger.info(
      '📤 _markMessagesAsRead called with ${messageIds.length} messages: $messageIds',
    );

    try {
      if (widget.conversationId != null) {
        Logger.info('📡 Using ConversationDetailsProvider API path');
        final success = await context
            .read<ConversationDetailsProvider>()
            .markMessagesAsRead(messageIds);

        Logger.info('API Response: success=$success');

        if (success) {
          Logger.info('✅ API succeeded, syncing with ChatProvider');
          await context.read<ChatProvider>().markMessagesAsRead(
            widget.chat.id,
            messageIds: messageIds,
            syncWithServer: false,
          );
          Logger.info('✅ ChatProvider synced');
        } else {
          Logger.warning('⚠️ API call failed');
        }
      } else {
        Logger.info('📡 Using ChatProvider direct path');
        await context.read<ChatProvider>().markMessagesAsRead(
          widget.chat.id,
          messageIds: messageIds,
        );
      }
    } catch (e, stackTrace) {
      Logger.error(
        '❌ Error in _markMessagesAsRead: $e',
        'ChatConversationScreen',
        e,
        stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(
        chat: widget.chat,
        onBackPressed: () => Navigator.of(context).pop(),
        onMenuPressed: () => _showChatMenu(context),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMessagesList(context),
          ),
          MessageInput(
            controller: _messageController,
            onSend: _sendMessage,
            onAttachment: () => _showAttachmentMenu(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context) {
    if (widget.conversationId != null) {
      // Use conversation details provider for real API data
      return Consumer<ConversationDetailsProvider>(
        builder: (context, conversationDetailsProvider, child) {
          if (conversationDetailsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (conversationDetailsProvider.error != null) {
            return _buildErrorState(
              context,
              conversationDetailsProvider.error!,
            );
          }

          final conversationMessages = _sortConversationMessagesById(
            _deduplicateConversationMessages(
              conversationDetailsProvider.sortedMessages,
            ),
          );
          final currentUserId = context
              .watch<AuthProvider?>()
              ?.currentUser
              ?.id
              ?.toString();

          if (conversationMessages.isEmpty) {
            return _buildEmptyState(context);
          }

          return Stack(
            children: [
              ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 16,
                ),
                itemCount: conversationMessages.length,
                itemBuilder: (context, index) {
                  final conversationMessage = conversationMessages[index];
                  final previousMessage = index > 0
                      ? conversationMessages[index - 1]
                      : null;
                  final nextMessage = index < conversationMessages.length - 1
                      ? conversationMessages[index + 1]
                      : null;

                  // Convert ConversationMessage to Message for UI compatibility
                  final message = _convertConversationMessageToMessage(
                    conversationMessage,
                  );
                  final prevMsg = previousMessage != null
                      ? _convertConversationMessageToMessage(previousMessage)
                      : null;
                  final nextMsg = nextMessage != null
                      ? _convertConversationMessageToMessage(nextMessage)
                      : null;

                  return MessageBubble(
                    message: message,
                    previousMessage: prevMsg,
                    nextMessage: nextMsg,
                    currentUserId: currentUserId,
                    onReply: () => _replyToMessage(message),
                    onEdit: () => _editMessage(message),
                    onDelete: () => _deleteMessage(message),
                    onCopy: () => _copyMessage(message),
                  );
                },
              ),
              if (_showScrollToBottom)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'scroll_to_bottom_conversation',
                    onPressed: _scrollToBottom,
                    child: const Icon(Icons.arrow_downward),
                  ),
                ),
            ],
          );
        },
      );
    } else {
      // Fallback to chat provider for existing functionality
      return Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final messages = _sortMessagesById(
            _deduplicateMessages(
              chatProvider.getMessagesForChat(widget.chat.id),
            ),
          );
          final currentUserId = context
              .watch<AuthProvider?>()
              ?.currentUser
              ?.id
              ?.toString();

          if (messages.isEmpty) {
            return _buildEmptyState(context);
          }

          return Stack(
            children: [
              ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 16,
                ),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final previousMessage = index > 0
                      ? messages[index - 1]
                      : null;
                  final nextMessage = index < messages.length - 1
                      ? messages[index + 1]
                      : null;

                  return MessageBubble(
                    message: message,
                    previousMessage: previousMessage,
                    nextMessage: nextMessage,
                    currentUserId: currentUserId,
                    onReply: () => _replyToMessage(message),
                    onEdit: () => _editMessage(message),
                    onDelete: () => _deleteMessage(message),
                    onCopy: () => _copyMessage(message),
                  );
                },
              ),
              if (_showScrollToBottom)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'scroll_to_bottom_chat',
                    onPressed: _scrollToBottom,
                    child: const Icon(Icons.arrow_downward),
                  ),
                ),
            ],
          );
        },
      );
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            loc.translate('chat.noMessages'),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.translate('chat.startConversation'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(
    String content, {
    MessageType type = MessageType.text,
  }) async {
    if (content.trim().isEmpty) return;

    if (widget.conversationId != null) {
      // Use conversation details API for real message sending
      final conversationDetailsProvider = context
          .read<ConversationDetailsProvider>();
      final chatProvider = context.read<ChatProvider>();

      // Create a temporary message with sending state
      final tempMessageId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final tempMessage = Message(
        id: tempMessageId,
        chatId: widget.chat.id,
        senderId:
            context.read<AuthProvider?>()?.currentUser?.id.toString() ?? '',
        senderName: 'You',
        type: type,
        content: content.trim(),
        sentAt: DateTime.now(),
        status: MessageStatus.sending,
        isSending: true,
      );

      // Add to chat provider temporarily
      chatProvider.addTemporaryMessage(widget.chat.id, tempMessage);

      _messageController.clear();

      try {
        Logger.info('📤 Sending message...');

        final success = await conversationDetailsProvider.sendMessage(
          message: content.trim(),
        );

        if (success) {
          // Remove temp message and refresh will show real message
          chatProvider.removeTemporaryMessage(widget.chat.id, tempMessageId);
          Logger.info('✅ Message sent successfully');
        } else {
          // Mark message as failed
          chatProvider.markMessageAsFailed(
            widget.chat.id,
            tempMessageId,
            conversationDetailsProvider.sendMessageError ?? 'Send failed',
          );

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                conversationDetailsProvider.sendMessageError ??
                    'Failed to send message',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        Logger.error('❌ Error sending message', 'ChatConversationScreen', e);
        chatProvider.markMessageAsFailed(
          widget.chat.id,
          tempMessageId,
          e.toString(),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Fallback to chat provider for existing functionality
      final chatProvider = context.read<ChatProvider>();

      await chatProvider.sendMessage(
        chatId: widget.chat.id,
        content: content.trim(),
        type: type,
      );

      _messageController.clear();
    }

    // Scroll to bottom after sending message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  /// Convert ConversationMessage to Message for UI compatibility
  Message _convertConversationMessageToMessage(
    ConversationMessage conversationMessage,
  ) {
    return Message(
      id: conversationMessage.id.toString(),
      chatId: widget.chat.id,
      senderId: conversationMessage.sender.id.toString(),
      senderName: conversationMessage.sender.displayName,
      content: conversationMessage.body,
      type: MessageType.text, // TODO: Determine type based on files/content
      sentAt: conversationMessage.sentAt,
      status: conversationMessage.isRead
          ? MessageStatus.read
          : MessageStatus.delivered,
      attachments: conversationMessage.files.map((file) => file.url).toList(),
    );
  }

  List<ConversationMessage> _deduplicateConversationMessages(
    List<ConversationMessage> messages,
  ) {
    if (messages.isEmpty) {
      return messages;
    }

    final seenIds = <int>{};
    final deduplicated = <ConversationMessage>[];

    for (final message in messages) {
      if (seenIds.add(message.id)) {
        deduplicated.add(message);
      }
    }

    return deduplicated;
  }

  List<Message> _deduplicateMessages(List<Message> messages) {
    if (messages.isEmpty) {
      return messages;
    }

    final seenIds = <String>{};
    final deduplicated = <Message>[];

    for (final message in messages) {
      if (seenIds.add(message.id)) {
        deduplicated.add(message);
      }
    }

    return deduplicated;
  }

  List<ConversationMessage> _sortConversationMessagesById(
    List<ConversationMessage> messages,
  ) {
    if (messages.length <= 1) {
      return messages;
    }

    final sorted = List<ConversationMessage>.from(messages)
      ..sort((a, b) => a.id.compareTo(b.id));
    return sorted;
  }

  List<Message> _sortMessagesById(List<Message> messages) {
    if (messages.length <= 1) {
      return messages;
    }

    final sorted = List<Message>.from(messages)
      ..sort((a, b) => _compareMessageIds(a.id, b.id));
    return sorted;
  }

  int _compareMessageIds(String a, String b) {
    final aNum = int.tryParse(a);
    final bNum = int.tryParse(b);

    if (aNum != null && bNum != null) {
      return aNum.compareTo(bNum);
    }

    if (aNum != null) {
      return -1; // Numeric IDs come first for stability.
    }

    if (bNum != null) {
      return 1;
    }

    return a.compareTo(b);
  }

  /// Build error state widget
  Widget _buildErrorState(BuildContext context, String error) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            loc.translate('common.error'),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadMessages,
            icon: const Icon(Icons.refresh),
            label: Text(loc.translate('common.retry')),
          ),
        ],
      ),
    );
  }

  void _replyToMessage(Message message) {
    // TODO: Implement reply functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reply functionality coming soon!')),
    );
  }

  void _editMessage(Message message) {
    // TODO: Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon!')),
    );
  }

  void _deleteMessage(Message message) {
    // TODO: Implement delete functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delete functionality coming soon!')),
    );
  }

  void _copyMessage(Message message) {
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Copied: ${message.content}')));
  }

  void _showChatMenu(BuildContext context) {
    final loc = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(loc.translate('chat.chatInfo')),
            onTap: () {
              Navigator.pop(context);
              _showChatInfo(context);
            },
          ),
          ListTile(
            leading: Icon(
              widget.chat.isMuted
                  ? Icons.notifications
                  : Icons.notifications_off,
            ),
            title: Text(
              widget.chat.isMuted
                  ? loc.translate('chat.unmute')
                  : loc.translate('chat.mute'),
            ),
            onTap: () {
              Navigator.pop(context);
              _toggleMute();
            },
          ),
          ListTile(
            leading: Icon(
              widget.chat.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
            ),
            title: Text(
              widget.chat.isPinned
                  ? loc.translate('chat.unpin')
                  : loc.translate('chat.pin'),
            ),
            onTap: () {
              Navigator.pop(context);
              _togglePin();
            },
          ),
          if (widget.chat.type == ChatType.group) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: Text(loc.translate('chat.leaveGroup')),
              onTap: () {
                Navigator.pop(context);
                _showLeaveGroupDialog(context);
              },
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text(loc.translate('chat.deleteChat')),
            onTap: () {
              Navigator.pop(context);
              _showDeleteChatDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showAttachmentMenu(BuildContext context) {
    final loc = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: Text(loc.translate('chat.camera')),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement camera
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: Text(loc.translate('chat.gallery')),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement gallery
            },
          ),
          ListTile(
            leading: const Icon(Icons.insert_drive_file),
            title: Text(loc.translate('chat.document')),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement document picker
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(loc.translate('chat.location')),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement location sharing
            },
          ),
        ],
      ),
    );
  }

  void _showChatInfo(BuildContext context) {
    // TODO: Navigate to chat info screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat info screen coming soon!')),
    );
  }

  void _toggleMute() {
    final chatProvider = context.read<ChatProvider>();
    chatProvider.toggleChatMute(widget.chat.id);
  }

  void _togglePin() {
    final chatProvider = context.read<ChatProvider>();
    chatProvider.toggleChatPin(widget.chat.id);
  }

  void _showLeaveGroupDialog(BuildContext context) {
    final loc = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('chat.leaveGroup')),
        content: Text(loc.translate('chat.leaveGroupConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.translate('common.cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement leave group
            },
            child: Text(loc.translate('chat.leave')),
          ),
        ],
      ),
    );
  }

  void _showDeleteChatDialog(BuildContext context) {
    final loc = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('chat.deleteChat')),
        content: Text(loc.translate('chat.deleteChatConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.translate('common.cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to chat list
              final chatProvider = context.read<ChatProvider>();
              chatProvider.deleteChat(widget.chat.id);
            },
            child: Text(loc.translate('common.delete')),
          ),
        ],
      ),
    );
  }
}
