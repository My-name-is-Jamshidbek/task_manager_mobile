import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/models/chat_enums.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String, {MessageType type}) onSend;
  final VoidCallback? onAttachment;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.onAttachment,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final isTyping = widget.controller.text.trim().isNotEmpty;
    if (isTyping != _isTyping) {
      setState(() {
        _isTyping = isTyping;
      });
    }
  }

  void _sendMessage() {
    final text = widget.controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (widget.onAttachment != null)
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: widget.onAttachment,
                color: theme.colorScheme.primary,
              ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    0.3,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: TextField(
                  controller: widget.controller,
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: loc.translate('chat.typeMessage'),
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.7,
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: theme.textTheme.bodyMedium,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: IconButton(
                onPressed: _isTyping ? _sendMessage : null,
                icon: Icon(
                  _isTyping ? Icons.send : Icons.mic,
                  color: _isTyping
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: _isTyping
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : Colors.transparent,
                  shape: const CircleBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
