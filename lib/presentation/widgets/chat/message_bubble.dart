import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/message.dart';
import '../../../data/models/chat_enums.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final Message? previousMessage;
  final Message? nextMessage;
  final String? currentUserId;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCopy;

  const MessageBubble({
    super.key,
    required this.message,
    this.previousMessage,
    this.nextMessage,
    this.currentUserId,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFromCurrentUser = message.isFromCurrentUser(currentUserId ?? '');
    final showSenderName = _shouldShowSenderName();
    final showAvatar = _shouldShowAvatar();
    final showTimestamp = _shouldShowTimestamp();

    return Container(
      margin: EdgeInsets.only(
        bottom: showTimestamp ? 16 : 4,
        top: _shouldAddTopMargin() ? 16 : 0,
      ),
      child: Row(
        mainAxisAlignment: isFromCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromCurrentUser) ...[
            _buildAvatar(theme, showAvatar),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isFromCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (showSenderName && !isFromCurrentUser)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 4),
                    child: Text(
                      message.senderName ?? 'Unknown',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                GestureDetector(
                  onLongPress: () => _showMessageActions(context),
                  child: Stack(
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _getBubbleColor(theme, isFromCurrentUser),
                          borderRadius: _getBorderRadius(isFromCurrentUser),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 1,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.replyToMessage != null)
                              _buildReplyPreview(theme),
                            _buildMessageContent(theme, isFromCurrentUser),
                            if (message.isEdited)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'edited',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isFromCurrentUser
                                        ? Colors.white70
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            // Add invisible spacer to push status icon to bottom right
                            if (isFromCurrentUser) const SizedBox(height: 16),
                          ],
                        ),
                      ),
                      // Status icon positioned at bottom right for current user
                      if (isFromCurrentUser)
                        Positioned(
                          right: 8,
                          bottom: 4,
                          child: Icon(
                            _getStatusIcon(),
                            size: 14,
                            color: _getStatusColor(theme),
                          ),
                        ),
                    ],
                  ),
                ),
                if (showTimestamp)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _getFormattedTime(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isFromCurrentUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(theme, showAvatar, isFromCurrentUser: true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(
    ThemeData theme,
    bool show, {
    bool isFromCurrentUser = false,
  }) {
    if (!show) {
      return const SizedBox(width: 32);
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
      backgroundImage: message.senderAvatarUrl != null
          ? NetworkImage(message.senderAvatarUrl!)
          : null,
      child: message.senderAvatarUrl == null
          ? Icon(Icons.person, size: 18, color: theme.colorScheme.primary)
          : null,
    );
  }

  Widget _buildReplyPreview(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replyToMessage?.senderName ?? 'Unknown',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.replyToMessage?.getPreviewText() ?? '',
            style: theme.textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(ThemeData theme, bool isFromCurrentUser) {
    if (message.isDeleted) {
      return Text(
        'This message was deleted',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isFromCurrentUser
              ? Colors.white70
              : theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isFromCurrentUser
                ? Colors.white
                : theme.colorScheme.onSurface,
          ),
        );
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image, size: 48),
            ),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isFromCurrentUser
                      ? Colors.white
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ],
        );
      case MessageType.file:
        return Row(
          children: [
            Icon(
              Icons.attach_file,
              color: isFromCurrentUser
                  ? Colors.white
                  : theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isFromCurrentUser
                      ? Colors.white
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        );
      case MessageType.audio:
        return Row(
          children: [
            Icon(
              Icons.play_circle_filled,
              color: isFromCurrentUser
                  ? Colors.white
                  : theme.colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voice message',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isFromCurrentUser
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '0:30', // TODO: Get actual duration
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isFromCurrentUser
                          ? Colors.white70
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case MessageType.video:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.play_circle_filled, size: 48),
            ),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isFromCurrentUser
                      ? Colors.white
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ],
        );
    }
  }

  Color _getBubbleColor(ThemeData theme, bool isFromCurrentUser) {
    if (isFromCurrentUser) {
      return theme.colorScheme.primary;
    }
    return theme.colorScheme.surfaceContainerHighest;
  }

  BorderRadius _getBorderRadius(bool isFromCurrentUser) {
    const radius = Radius.circular(16);
    const smallRadius = Radius.circular(4);

    if (isFromCurrentUser) {
      return BorderRadius.only(
        topLeft: radius,
        topRight: radius,
        bottomLeft: radius,
        bottomRight: _shouldRoundBottomRight() ? radius : smallRadius,
      );
    } else {
      return BorderRadius.only(
        topLeft: radius,
        topRight: radius,
        bottomLeft: _shouldRoundBottomLeft() ? radius : smallRadius,
        bottomRight: radius,
      );
    }
  }

  bool _shouldShowSenderName() {
    if (previousMessage == null) return true;
    return previousMessage!.senderId != message.senderId;
  }

  bool _shouldShowAvatar() {
    if (nextMessage == null) return true;
    return nextMessage!.senderId != message.senderId;
  }

  bool _shouldShowTimestamp() {
    if (nextMessage == null) return true;

    final timeDiff = nextMessage!.sentAt.difference(message.sentAt);
    return timeDiff.inMinutes > 5 || nextMessage!.senderId != message.senderId;
  }

  bool _shouldAddTopMargin() {
    if (previousMessage == null) return true;

    final timeDiff = message.sentAt.difference(previousMessage!.sentAt);
    return timeDiff.inMinutes > 5 ||
        previousMessage!.senderId != message.senderId;
  }

  bool _shouldRoundBottomRight() {
    return nextMessage?.senderId != message.senderId;
  }

  bool _shouldRoundBottomLeft() {
    return nextMessage?.senderId != message.senderId;
  }

  String _getFormattedTime() {
    final now = DateTime.now();
    final messageDate = message.sentAt;

    if (now.day == messageDate.day &&
        now.month == messageDate.month &&
        now.year == messageDate.year) {
      // Today - show time
      return '${messageDate.hour.toString().padLeft(2, '0')}:${messageDate.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(messageDate).inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else {
      // Older - show date
      return '${messageDate.day}/${messageDate.month}/${messageDate.year}';
    }
  }

  IconData _getStatusIcon() {
    if (message.isSending) {
      return Icons.schedule;
    }

    if (message.sendError != null) {
      return Icons.error;
    }

    switch (message.status) {
      case MessageStatus.sending:
        return Icons.schedule;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error;
    }
  }

  Color _getStatusColor(ThemeData theme) {
    if (message.isSending) {
      return Colors.white70;
    }

    if (message.sendError != null) {
      return Colors.red.shade300;
    }

    switch (message.status) {
      case MessageStatus.sending:
        return Colors.white70;
      case MessageStatus.sent:
        return Colors.white70;
      case MessageStatus.delivered:
        return Colors.white70;
      case MessageStatus.read:
        return Colors.blue.shade200;
      case MessageStatus.failed:
        return Colors.red.shade300;
    }
  }

  void _showMessageActions(BuildContext context) {
    final loc = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onReply != null)
            ListTile(
              leading: const Icon(Icons.reply),
              title: Text(loc.translate('chat.reply')),
              onTap: () {
                Navigator.pop(context);
                onReply?.call();
              },
            ),
          if (onCopy != null)
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(loc.translate('chat.copy')),
              onTap: () {
                Navigator.pop(context);
                onCopy?.call();
              },
            ),
          if (message.isFromCurrentUser(currentUserId ?? '')) ...[
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(loc.translate('chat.edit')),
                onTap: () {
                  Navigator.pop(context);
                  onEdit?.call();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(loc.translate('common.delete')),
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),
          ],
        ],
      ),
    );
  }
}
