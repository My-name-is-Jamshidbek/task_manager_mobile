import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';

class ErrorModal extends StatelessWidget {
  final String title;
  final String message;
  final String? details;
  final VoidCallback? onMore;
  final VoidCallback? onClose;

  const ErrorModal({
    super.key,
    required this.title,
    required this.message,
    this.details,
    this.onMore,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final hasDetails = (details != null && details!.trim().isNotEmpty);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onClose?.call();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message, style: theme.textTheme.bodyMedium),
            if (hasDetails) const SizedBox(height: 8),
            if (hasDetails)
              Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: Text(
                    loc.translate('common.details'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        details!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onClose?.call();
                  },
                  child: Text(loc.translate('common.close')),
                ),
                const SizedBox(width: 8),
                if (onMore != null)
                  FilledButton.icon(
                    onPressed: () {
                      onMore!.call();
                    },
                    icon: const Icon(Icons.info_outline),
                    label: Text(loc.translate('common.more')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showErrorModal(
  BuildContext context, {
  required String title,
  required String message,
  String? details,
  VoidCallback? onMore,
  VoidCallback? onClose,
}) async {
  if (!context.mounted) return;
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => ErrorModal(
      title: title,
      message: message,
      details: details,
      onMore: onMore,
      onClose: onClose,
    ),
  );
}
