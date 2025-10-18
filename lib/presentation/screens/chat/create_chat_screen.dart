import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/chat.dart';
import '../../../data/models/chat_enums.dart';
import '../../../data/models/chat_member.dart';
import '../../../data/models/message.dart';
import '../../../data/models/contact.dart';
import '../../../data/models/find_or_create_conversation_response.dart';
import '../../providers/chat_provider.dart';
import '../../providers/contacts_provider.dart';
import '../chat/chat_conversation_screen.dart';

class CreateChatScreen extends StatefulWidget {
  const CreateChatScreen({super.key});

  @override
  State<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends State<CreateChatScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController =
      TextEditingController();

  final List<String> _selectedParticipants = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadContacts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _groupNameController.dispose();
    _groupDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final contactsProvider = context.read<ContactsProvider>();
    await contactsProvider.loadContacts();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    final contactsProvider = context.read<ContactsProvider>();

    if (query.isEmpty) {
      contactsProvider.clearSearch();
    } else {
      contactsProvider.searchContacts(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('chat.newChat')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: loc.translate('chat.oneToOneChat')),
            Tab(text: loc.translate('chat.groupChat')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildDirectChatTab(context), _buildGroupChatTab(context)],
      ),
    );
  }

  Widget _buildDirectChatTab(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search contacts',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Expanded(
          child: Consumer<ContactsProvider>(
            builder: (context, contactsProvider, child) {
              if (contactsProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (contactsProvider.error != null) {
                return _buildErrorState(contactsProvider.error!);
              }

              return _buildContactsList(
                context,
                contactsProvider.contacts,
                isGroupMode: false,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupChatTab(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _groupNameController,
                decoration: InputDecoration(
                  labelText: loc.translate('chat.groupName'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _groupDescriptionController,
                decoration: InputDecoration(
                  labelText: loc.translate('chat.groupDescription'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: loc.translate('chat.addParticipants'),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              if (_selectedParticipants.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '${loc.translate('chat.members')}: ${_selectedParticipants.length}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _selectedParticipants.map((participantId) {
                    final contactsProvider = context.read<ContactsProvider>();
                    final contact = contactsProvider.contacts.firstWhere(
                      (c) => c.id.toString() == participantId,
                      orElse: () => Contact(
                        id: int.parse(participantId),
                        name: 'Unknown',
                        phone: '',
                      ),
                    );
                    return Chip(
                      label: Text(contact.name),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _removeParticipant(participantId),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: Consumer<ContactsProvider>(
            builder: (context, contactsProvider, child) {
              if (contactsProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (contactsProvider.error != null) {
                return _buildErrorState(contactsProvider.error!);
              }

              return _buildContactsList(
                context,
                contactsProvider.contacts,
                isGroupMode: true,
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _selectedParticipants.length >= 2 &&
                      _groupNameController.text.trim().isNotEmpty
                  ? () => _createGroupChat(context)
                  : null,
              child: Text(loc.translate('chat.createGroup')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactsList(
    BuildContext context,
    List<Contact> contacts, {
    required bool isGroupMode,
  }) {
    final theme = Theme.of(context);

    if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No contacts found',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        final isSelected = _selectedParticipants.contains(contact.id);

        return ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                backgroundImage: contact.avatarUrl != null
                    ? NetworkImage(contact.avatarUrl!)
                    : null,
                child: contact.avatarUrl == null
                    ? Icon(Icons.person, color: theme.colorScheme.primary)
                    : null,
              ),
              if (contact.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(contact.name),
          subtitle: Text(contact.phone),
          trailing: isGroupMode
              ? Checkbox(
                  value: isSelected,
                  onChanged: (bool? value) {
                    if (value == true) {
                      _addParticipant(contact.id.toString());
                    } else {
                      _removeParticipant(contact.id.toString());
                    }
                  },
                )
              : null,
          onTap: () {
            if (isGroupMode) {
              if (isSelected) {
                _removeParticipant(contact.id.toString());
              } else {
                _addParticipant(contact.id.toString());
              }
            } else {
              _createDirectChat(context, contact);
            }
          },
        );
      },
    );
  }

  void _addParticipant(String participantId) {
    setState(() {
      if (!_selectedParticipants.contains(participantId)) {
        _selectedParticipants.add(participantId);
      }
    });
  }

  void _removeParticipant(String participantId) {
    setState(() {
      _selectedParticipants.remove(participantId);
    });
  }

  Future<void> _createDirectChat(BuildContext context, Contact contact) async {
    final contactsProvider = context.read<ContactsProvider>();

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Use find-or-create API to get or create conversation
      final conversationResponse = await contactsProvider
          .findOrCreateConversation(contact.id);

      // Dismiss loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (conversationResponse != null && mounted) {
        // Create a Chat object from the conversation response for UI compatibility
        final chat = await _convertResponseToChat(
          conversationResponse,
          contact,
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ChatConversationScreen(
              chat: chat,
              conversationId: conversationResponse.id,
            ),
          ),
        );
      } else if (mounted) {
        // Show error message
        final error =
            contactsProvider.createConversationError ??
            'Failed to create conversation';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      // Dismiss loading dialog if still showing
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create conversation: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Convert FindOrCreateConversationResponse to Chat object for UI compatibility
  Future<Chat> _convertResponseToChat(
    FindOrCreateConversationResponse response,
    Contact contact,
  ) async {
    // Create last message if available
    Message? lastMessage;
    if (response.lastMessage != null && response.lastMessage!.isNotEmpty) {
      lastMessage = Message(
        id: 'last_${response.id}',
        chatId: response.id.toString(),
        senderId: contact.id.toString(),
        senderName: contact.name,
        content: response.lastMessage!,
        type: MessageType.text,
        sentAt: DateTime.now(), // API doesn't provide exact time
        status: MessageStatus.delivered,
      );
    }

    // Create chat members
    final members = [
      ChatMember(
        userId: contact.id.toString(),
        displayName: contact.name,
        role: ChatMemberRole.member,
        joinedAt: DateTime.now(),
        lastSeenAt: DateTime.now(),
      ),
    ];

    return Chat(
      id: response.id.toString(),
      name: response.title,
      type: response.isDirect ? ChatType.oneToOne : ChatType.group,
      description: null,
      avatarUrl: response.avatar,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      lastMessage: lastMessage,
      unreadCount: response.unreadCount,
      members: members,
      isPinned: false,
      isMuted: false,
      isArchived: false,
      createdBy: null,
    );
  }

  Future<void> _createGroupChat(BuildContext context) async {
    final chatProvider = context.read<ChatProvider>();

    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a group name')));
      return;
    }

    if (_selectedParticipants.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least 2 participants')),
      );
      return;
    }

    try {
      final chat = await chatProvider.createChat(
        name: _groupNameController.text.trim(),
        description: _groupDescriptionController.text.trim().isNotEmpty
            ? _groupDescriptionController.text.trim()
            : null,
        type: ChatType.group,
        memberIds: _selectedParticipants,
      );

      if (mounted && chat != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ChatConversationScreen(chat: chat),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create group: $e')));
      }
    }
  }

  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Failed to load contacts',
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
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final contactsProvider = context.read<ContactsProvider>();
              contactsProvider.refreshContacts();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
