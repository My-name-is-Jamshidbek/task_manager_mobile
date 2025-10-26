import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';

/// WebSocket Error Dialog - Displays WebSocket connection and event errors
class WebSocketErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? errorType; // 'connection', 'subscription', 'event', etc.
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const WebSocketErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.errorType,
    this.onRetry,
    this.onDismiss,
  });

  /// Get icon based on error type
  IconData _getErrorIcon() {
    switch (errorType?.toLowerCase()) {
      case 'connection':
        return Icons.cloud_off;
      case 'subscription':
        return Icons.link_off;
      case 'event':
        return Icons.error_outline;
      default:
        return Icons.warning_amber;
    }
  }

  /// Get color based on error type
  Color _getErrorColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (errorType?.toLowerCase()) {
      case 'connection':
        return Colors.deepOrange;
      case 'subscription':
        return Colors.orange;
      default:
        return theme.colorScheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final errorColor = _getErrorColor(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = MediaQuery.of(context).size.height;
            final hasBoundedHeight =
                constraints.hasBoundedHeight &&
                constraints.maxHeight.isFinite &&
                constraints.maxHeight > 0;
            final availableHeight = hasBoundedHeight
                ? constraints.maxHeight
                : screenHeight * 0.85;
            final double targetMaxHeight = availableHeight.clamp(
              300.0,
              screenHeight * 0.9,
            );

            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: targetMaxHeight),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icon and title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getErrorIcon(),
                            color: errorColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              if (errorType != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  errorType!.replaceAll('_', ' ').toUpperCase(),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: errorColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            onDismiss?.call();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Message
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: errorColor.withOpacity(0.05),
                        border: Border.all(
                          color: errorColor.withOpacity(0.2),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onDismiss?.call();
                          },
                          child: Text(loc.translate('common.dismiss')),
                        ),
                        const SizedBox(width: 8),
                        if (onRetry != null)
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onRetry?.call();
                            },
                            icon: const Icon(Icons.refresh),
                            label: Text(loc.translate('common.retry')),
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

/// Show WebSocket error dialog
Future<void> showWebSocketErrorDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? errorType,
  VoidCallback? onRetry,
  VoidCallback? onDismiss,
}) async {
  if (!context.mounted) return;
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => WebSocketErrorDialog(
      title: title,
      message: message,
      errorType: errorType,
      onRetry: onRetry,
      onDismiss: onDismiss,
    ),
  );
}

/// Snackbar for WebSocket errors
void showWebSocketErrorSnackbar(
  BuildContext context, {
  required String message,
  Duration duration = const Duration(seconds: 5),
  VoidCallback? onRetry,
}) {
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
      backgroundColor: Colors.deepOrange,
      action: onRetry != null
          ? SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
    ),
  );
}
