import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/update_service.dart';
import '../../core/utils/logger.dart';

/// Dialog shown when app update is required (mandatory)
class RequiredUpdateDialog extends StatelessWidget {
  final String currentVersion;
  final String latestVersion;
  final String updateTitle;
  final String updateDescription;

  const RequiredUpdateDialog({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    required this.updateTitle,
    required this.updateDescription,
  });

  static Future<void> show({
    required BuildContext context,
    required String currentVersion,
    required String latestVersion,
    required String updateTitle,
    required String updateDescription,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Cannot dismiss required update
      builder: (BuildContext context) {
        return RequiredUpdateDialog(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          updateTitle: updateTitle,
          updateDescription: updateDescription,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return WillPopScope(
      onWillPop: () async => false, // Prevent back button dismiss
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.system_update, color: theme.colorScheme.error, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                loc.translate('app.updateRequired'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              updateTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              updateDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: theme.colorScheme.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.translate('app.updateInstructions'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current: $currentVersion → Latest: $latestVersion',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                Logger.info(
                  '🔄 RequiredUpdateDialog: User tapped update button',
                );
                await UpdateService.openAppStore();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.system_update),
              label: Text(
                loc.translate('app.updateNow'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog shown when app update is available but optional
class OptionalUpdateDialog extends StatelessWidget {
  final String currentVersion;
  final String latestVersion;
  final String updateTitle;
  final String updateDescription;
  final VoidCallback? onUpdateTap;
  final VoidCallback? onLaterTap;

  const OptionalUpdateDialog({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    required this.updateTitle,
    required this.updateDescription,
    this.onUpdateTap,
    this.onLaterTap,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String currentVersion,
    required String latestVersion,
    required String updateTitle,
    required String updateDescription,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return OptionalUpdateDialog(
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          updateTitle: updateTitle,
          updateDescription: updateDescription,
          onUpdateTap: () {
            Navigator.of(context).pop(true); // User chose to update
          },
          onLaterTap: () {
            Navigator.of(context).pop(false); // User chose to skip
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.update, color: theme.colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              loc.translate('app.updateAvailable'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            updateTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            updateDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You can continue using the current version or update now for the latest features.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Current: $currentVersion → Latest: $latestVersion',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Logger.info('⏭️ OptionalUpdateDialog: User chose to skip update');
            if (onLaterTap != null) {
              onLaterTap!();
            } else {
              Navigator.of(context).pop(false);
            }
          },
          child: Text(loc.translate('app.updateLater')),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            Logger.info('🔄 OptionalUpdateDialog: User chose to update');
            if (onUpdateTap != null) {
              onUpdateTap!();
            } else {
              Navigator.of(context).pop(true);
            }
            await UpdateService.openAppStore();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          icon: const Icon(Icons.update),
          label: Text(loc.translate('app.updateNow')),
        ),
      ],
    );
  }
}

/// Loading dialog shown while checking for updates
class UpdateCheckDialog extends StatelessWidget {
  const UpdateCheckDialog({super.key});

  static Future<void> show(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const UpdateCheckDialog();
      },
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            loc.translate('app.checkingUpdates'),
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
