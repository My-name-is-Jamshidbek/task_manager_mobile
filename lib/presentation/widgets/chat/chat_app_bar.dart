import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/chat.dart';
import '../../../data/models/chat_member.dart';
import '../../../data/models/chat_enums.dart';
import '../../providers/chat_provider.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Chat chat;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMenuPressed;

  const ChatAppBar({
    super.key,
    required this.chat,
    this.onBackPressed,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatProvider = context.watch<ChatProvider>();
    final displayName = chat.getDisplayName(
      currentUserId: chatProvider.currentUserId,
    );
    final avatarUrl = chat.getAvatarUrl(
      currentUserId: chatProvider.currentUserId,
    );

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Icon(
                    chat.type == ChatType.group ? Icons.group : Icons.person,
                    color: theme.colorScheme.primary,
                    size: 20,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (chat.type == ChatType.group) ...[
                  const SizedBox(height: 2),
                  Text(
                    _getGroupSubtitle(context),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else ...[
                  const SizedBox(height: 2),
                  Text(
                    _getOneToOneSubtitle(context),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (chat.type == ChatType.oneToOne)
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              // TODO: Implement video call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call coming soon!')),
              );
            },
          ),
        if (chat.type == ChatType.oneToOne)
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              // TODO: Implement voice call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice call coming soon!')),
              );
            },
          ),
        IconButton(icon: const Icon(Icons.more_vert), onPressed: onMenuPressed),
      ],
    );
  }

  String _getGroupSubtitle(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final memberCount = chat.members.length;

    if (memberCount <= 1) {
      return loc.translate('chat.members');
    }

    return '$memberCount ${loc.translate('chat.members').toLowerCase()}';
  }

  String _getOneToOneSubtitle(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final chatProvider = context.watch<ChatProvider>();

    // Find the other user in the chat
    if (chat.members.isEmpty) {
      return loc.translate('chat.offline'); // Default to offline if no members
    }

    ChatMember? otherMember;
    try {
      otherMember = chat.members.firstWhere(
        (member) => member.userId != chatProvider.currentUserId,
      );
    } catch (e) {
      // If no other member found, use first member
      otherMember = chat.members.isNotEmpty ? chat.members.first : null;
    }

    if (otherMember?.isOnline == true) {
      return loc.translate('chat.online');
    }

    return '${loc.translate('chat.lastSeen')} ${otherMember?.getLastSeenStatus() ?? ''}';
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
