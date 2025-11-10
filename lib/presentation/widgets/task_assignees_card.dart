import 'package:flutter/material.dart';
import '../../data/models/worker_models.dart';
import '../../core/localization/app_localizations.dart';

/// Reusable widget for displaying task assignees/workers with modern UI
/// Used in task detail, create, and edit screens
class TaskAssigneesCard extends StatelessWidget {
  final List<WorkerUser> workers;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRefresh;
  final void Function(WorkerUser worker)? onWorkerTap;
  final String? title;
  final bool showHeader;
  final double maxWidth;
  final Color Function(String statusColor)? getStatusColor;

  const TaskAssigneesCard({
    super.key,
    required this.workers,
    this.isLoading = false,
    this.error,
    this.onRefresh,
    this.onWorkerTap,
    this.title,
    this.showHeader = true,
    this.maxWidth = 130,
    this.getStatusColor,
  });

  Color _defaultGetStatusColor(BuildContext context, String statusColor) {
    final theme = Theme.of(context);
    switch (statusColor.toLowerCase()) {
      case 'primary':
        return theme.colorScheme.primaryContainer;
      case 'secondary':
        return theme.colorScheme.secondaryContainer;
      case 'tertiary':
        return theme.colorScheme.tertiaryContainer;
      case 'success':
      case 'green':
        return Colors.green.withOpacity(0.2);
      case 'error':
      case 'danger':
      case 'red':
        return Colors.red.withOpacity(0.2);
      case 'warning':
      case 'yellow':
      case 'orange':
        return Colors.orange.withOpacity(0.2);
      case 'info':
      case 'blue':
        return Colors.blue.withOpacity(0.2);
      default:
        return theme.colorScheme.secondaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final displayTitle = title ?? loc.translate('tasks.workers');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              Row(
                children: [
                  Text(displayTitle, style: theme.textTheme.titleMedium),
                  const Spacer(),
                  if (onRefresh != null)
                    IconButton(
                      tooltip: loc.translate('common.refresh'),
                      icon: isLoading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : const Icon(Icons.refresh),
                      onPressed: isLoading ? null : onRefresh,
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (isLoading && workers.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (error != null && workers.isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (onRefresh != null)
                    OutlinedButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh),
                      label: Text(loc.translate('common.retry')),
                    ),
                ],
              )
            else if (workers.isEmpty)
              Text(
                loc.translate('workers.noneAssigned'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: workers.map((worker) {
                  final statusColor = worker.statusColor != null
                      ? (getStatusColor?.call(worker.statusColor!) ??
                            _defaultGetStatusColor(
                              context,
                              worker.statusColor!,
                            ))
                      : null;

                  return GestureDetector(
                    onTap: onWorkerTap != null
                        ? () => onWorkerTap!(worker)
                        : null,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Avatar with initials
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary.withOpacity(0.8),
                                    theme.colorScheme.secondary.withOpacity(
                                      0.8,
                                    ),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  worker.name.isNotEmpty
                                      ? worker.name[0].toUpperCase()
                                      : '?',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: theme.colorScheme.onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Name
                            Text(
                              worker.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Status Badge
                            if (worker.statusLabel != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      statusColor ??
                                      theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  worker.statusLabel!,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color:
                                        theme.colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 6),
                            // Department/Meta
                            if (worker.departments.isNotEmpty)
                              Text(
                                worker.departments
                                    .map((d) => d.name)
                                    .join(', '),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            // Phone
                            if (worker.phone != null &&
                                worker.phone!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.phone,
                                      size: 12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        worker.phone!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
