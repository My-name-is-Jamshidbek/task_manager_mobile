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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Limit dialog content height to avoid vertical overflow
            final screenHeight = MediaQuery.of(context).size.height;
            final hasBoundedHeight =
                constraints.hasBoundedHeight &&
                constraints.maxHeight.isFinite &&
                constraints.maxHeight > 0;
            final availableHeight = hasBoundedHeight
                ? constraints.maxHeight
                : screenHeight * 0.85;
            final double targetMaxHeight = availableHeight.clamp(
              320.0,
              screenHeight * 0.9,
            );
            return ConstrainedBox(
              constraints: BoxConstraints(
                // Respect available height while allowing content to scroll
                maxHeight: targetMaxHeight,
              ),
              child: SingleChildScrollView(
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
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium,
                      softWrap: true,
                    ),
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
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 240),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: SingleChildScrollView(
                                  child: SelectableText(
                                    details!,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
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
          },
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
