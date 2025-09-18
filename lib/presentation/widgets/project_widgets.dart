import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/models/project_models.dart';

/// A pill-style informational chip with optional tap callback.
class InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  const InfoPill({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        // Use alpha blend rather than withOpacity for better future-proofing with Material 3 tokens
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(128), // ~50%
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return container;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: container,
      ),
    );
  }
}

/// Status chip mapping project.status codes to color + icon + label.
class ProjectStatusChip extends StatelessWidget {
  final Project project;
  const ProjectStatusChip({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    if (project.status == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final code = project.status ?? 0;
    late final String label;
    late final Color color;
    late final IconData icon;
    switch (code) {
      case 1:
        label = project.statusLabel ?? loc.translate('projects.status.active');
        color = Colors.blue;
        icon = Icons.play_circle_fill;
        break;
      case 2:
        label =
            project.statusLabel ?? loc.translate('projects.status.completed');
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 3:
        label = project.statusLabel ?? loc.translate('projects.status.expired');
        color = Colors.orange;
        icon = Icons.timer;
        break;
      case 4:
        label =
            project.statusLabel ?? loc.translate('projects.status.rejected');
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        label = project.statusLabel ?? loc.translate('projects.status.all');
        color = theme.colorScheme.outline;
        icon = Icons.info_outline;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(31), // 12% approx (0.12*255 ≈ 30.6)
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withAlpha(77)), // 30% ≈ 76.5
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
