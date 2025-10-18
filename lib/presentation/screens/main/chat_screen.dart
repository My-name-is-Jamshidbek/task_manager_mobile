import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/chat.dart';
import '../../../data/models/chat_enums.dart';
import '../../providers/chat_provider.dart';
import '../../providers/conversations_provider.dart';
import '../../providers/auth_provider.dart';
import '../chat/chat_conversation_screen.dart';
import '../chat/create_chat_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize chat and conversations providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider?>();
      final chatProvider = context.read<ChatProvider>();
      final conversationsProvider = context.read<ConversationsProvider>();

      if (authProvider?.currentUser?.id != null) {
        chatProvider.initialize(authProvider!.currentUser!.id.toString());

        // Load conversations for the tabs
        conversationsProvider.loadDirectConversations();
        conversationsProvider.loadDepartmentConversations();
        conversationsProvider.loadAllConversations();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          if (_isSearching) _buildSearchBar(context, loc, theme),
          _buildTabBar(context, loc, theme),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllChatsTab(context),
                _buildDirectChatsTab(context),
                _buildGroupChatsTab(context),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context, loc, theme),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: loc.translate('chat.searchChats'),
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildTabBar(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 18),
                const SizedBox(width: 8),
                Text(loc.translate('common.all')),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline, size: 18),
                const SizedBox(width: 8),
                Text(loc.translate('chat.oneToOneChat').split(' ').first),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.group_outlined, size: 18),
                const SizedBox(width: 8),
                Text(loc.translate('chat.groupChat').split(' ').first),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllChatsTab(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (chatProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (chatProvider.error != null) {
          return _buildErrorState(context, chatProvider.error!);
        }

        final chats = _searchQuery.isEmpty
            ? chatProvider.chats
            : chatProvider.searchChats(_searchQuery);

        if (chats.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildChatList(context, chats);
      },
    );
  }

  Widget _buildDirectChatsTab(BuildContext context) {
    return Consumer2<ChatProvider, ConversationsProvider>(
      builder: (context, chatProvider, conversationsProvider, child) {
        // Show loading if either provider is loading
        if (chatProvider.isLoading || conversationsProvider.isLoadingDirect) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show error if either provider has an error
        final error = chatProvider.error ?? conversationsProvider.directError;
        if (error != null) {
          return _buildErrorState(context, error);
        }

        // Use conversations provider for direct chats for better API integration
        final directConversations = conversationsProvider.directConversations;
        final directChats = directConversations
            .map((conv) => conv.toChat())
            .toList();

        final filteredChats = _searchQuery.isEmpty
            ? directChats
            : directChats.where((chat) {
                final name = chat
                    .getDisplayName(currentUserId: chatProvider.currentUserId)
                    .toLowerCase();
                return name.contains(_searchQuery.toLowerCase());
              }).toList();

        if (filteredChats.isEmpty) {
          return _buildEmptyState(context, isDirectChat: true);
        }

        return _buildChatList(context, filteredChats);
      },
    );
  }

  Widget _buildGroupChatsTab(BuildContext context) {
    return Consumer2<ChatProvider, ConversationsProvider>(
      builder: (context, chatProvider, conversationsProvider, child) {
        // Show loading if either provider is loading
        if (chatProvider.isLoading ||
            conversationsProvider.isLoadingDepartment) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show error if either provider has an error
        final error =
            chatProvider.error ?? conversationsProvider.departmentError;
        if (error != null) {
          return _buildErrorState(context, error);
        }

        // Use conversations provider for department (group) chats
        final departmentConversations =
            conversationsProvider.departmentConversations;
        final groupChats = departmentConversations
            .map((conv) => conv.toChat())
            .toList();

        final filteredChats = _searchQuery.isEmpty
            ? groupChats
            : groupChats.where((chat) {
                final name = chat
                    .getDisplayName(currentUserId: chatProvider.currentUserId)
                    .toLowerCase();
                return name.contains(_searchQuery.toLowerCase());
              }).toList();

        if (filteredChats.isEmpty) {
          return _buildEmptyState(context, isGroupChat: true);
        }

        return _buildChatList(context, filteredChats);
      },
    );
  }

  Widget _buildChatList(BuildContext context, List<Chat> chats) {
    return RefreshIndicator(
      onRefresh: () async {
        final chatProvider = context.read<ChatProvider>();
        final conversationsProvider = context.read<ConversationsProvider>();

        // Refresh both providers
        await Future.wait([
          chatProvider.loadChats(),
          conversationsProvider.refreshAllConversations(),
        ]);
      },
      child: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return _buildChatItem(context, chat);
        },
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, Chat chat) {
    final theme = Theme.of(context);
    final chatProvider = context.read<ChatProvider>();
    final displayName = chat.getDisplayName(
      currentUserId: chatProvider.currentUserId,
    );
    final avatarUrl = chat.getAvatarUrl(
      currentUserId: chatProvider.currentUserId,
    );

    return Dismissible(
      key: Key(chat.id),
      background: Container(
        color: theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Icon(
              chat.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              color: theme.colorScheme.onPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              chat.isPinned ? 'Unpin' : 'Pin',
              style: TextStyle(color: theme.colorScheme.onPrimary),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: theme.colorScheme.error,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Delete', style: TextStyle(color: theme.colorScheme.onError)),
            const SizedBox(width: 8),
            Icon(Icons.delete, color: theme.colorScheme.onError),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Pin/Unpin
          await chatProvider.toggleChatPin(chat.id);
          return false;
        } else {
          // Delete
          return await _showDeleteConfirmation(context, chat);
        }
      },
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? Icon(
                      chat.type == ChatType.group ? Icons.group : Icons.person,
                      color: theme.colorScheme.primary,
                    )
                  : null,
            ),
            if (chat.unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(),
                    style: TextStyle(
                      color: theme.colorScheme.onError,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            if (chat.isPinned) ...[
              Icon(Icons.push_pin, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                displayName,
                style: TextStyle(
                  fontWeight: chat.unreadCount > 0
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (chat.isMuted)
              Icon(
                Icons.notifications_off,
                size: 16,
                color: theme.colorScheme.outline,
              ),
          ],
        ),
        subtitle: Row(
          children: [
            if (chat.lastMessage != null) ...[
              if (chat.lastMessage!.senderId == chatProvider.currentUserId)
                Icon(
                  _getStatusIcon(chat.lastMessage!.status),
                  size: 14,
                  color: _getStatusColor(chat.lastMessage!.status, theme),
                ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  chat.lastMessage!.getPreviewText(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: chat.unreadCount > 0
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: chat.unreadCount > 0
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              ),
            ] else
              Expanded(
                child: Text(
                  'No messages yet',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
        trailing: chat.lastMessage != null
            ? Text(
                chat.lastMessage!.getFormattedTime(),
                style: TextStyle(
                  color: chat.unreadCount > 0
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: chat.unreadCount > 0
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              )
            : null,
        onTap: () {
          // Parse conversation ID from chat ID if it's from API
          int? conversationId;
          try {
            conversationId = int.tryParse(chat.id);
          } catch (e) {
            // If parsing fails, it might be a sample chat, leave conversationId as null
            conversationId = null;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatConversationScreen(
                chat: chat,
                conversationId: conversationId,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    bool isDirectChat = false,
    bool isGroupChat = false,
  }) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    String title = loc.translate('chat.noChats');
    String subtitle = loc.translate('chat.startConversation');
    IconData icon = Icons.chat_bubble_outline;

    if (isDirectChat) {
      title = 'No direct chats';
      subtitle = 'Start a conversation with someone';
      icon = Icons.person_outline;
    } else if (isGroupChat) {
      title = 'No group chats';
      subtitle = 'Create a group to chat with multiple people';
      icon = Icons.group_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final theme = Theme.of(context);
    final chatProvider = context.read<ChatProvider>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Error loading chats',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => chatProvider.loadChats(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateChatScreen()),
        );
      },
      child: const Icon(Icons.chat),
    );
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
    }
  }

  Color _getStatusColor(MessageStatus status, ThemeData theme) {
    switch (status) {
      case MessageStatus.sent:
        return theme.colorScheme.onSurfaceVariant;
      case MessageStatus.delivered:
        return theme.colorScheme.onSurfaceVariant;
      case MessageStatus.read:
        return theme.colorScheme.primary;
    }
  }

  Future<bool> _showDeleteConfirmation(BuildContext context, Chat chat) async {
    final loc = AppLocalizations.of(context);

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(loc.translate('chat.deleteChat')),
            content: Text(loc.translate('chat.deleteChatConfirm')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(loc.translate('common.cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(loc.translate('common.delete')),
              ),
            ],
          ),
        ) ??
        false;
  }
}
