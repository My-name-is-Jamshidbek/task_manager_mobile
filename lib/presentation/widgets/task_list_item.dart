import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/api_task_models.dart';
import '../providers/task_detail_provider.dart';
import '../screens/tasks/task_detail_screen.dart';

class TaskListItem extends StatelessWidget {
  final ApiTask task;
  final EdgeInsetsGeometry? contentPadding;
  final bool showDescription;
  final bool showStatus;
  final bool showDeadline;
  final bool showProjectName;
  final bool isCompleted;
  final Widget? leading;
  final Widget? trailing;
  final String? projectNameOverride;
  final String projectPlaceholder;
  final String? deadlineLabel;
  final VoidCallback? onTap;

  const TaskListItem({
    super.key,
    required this.task,
    this.contentPadding,
    this.showDescription = true,
    this.showStatus = true,
    this.showDeadline = true,
    this.showProjectName = false,
    this.isCompleted = false,
    this.leading,
    this.trailing,
    this.projectNameOverride,
    this.projectPlaceholder = '-',
    this.deadlineLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = task.status?.label?.trim() ?? '';
    final deadline = task.deadline;
    final projectName = projectNameOverride ?? task.project?.name ?? '';
    final description = (task.description ?? '').trim();
    final hasDescription = showDescription && description.isNotEmpty;
    final hasDeadline = showDeadline && deadline != null;
    final hasStatus = showStatus && statusLabel.isNotEmpty;
    final hasMetaRow = hasDeadline || hasStatus;
    final hasProjectRow = showProjectName;
    final descriptionMaxLines = (hasDeadline || hasStatus || hasProjectRow)
        ? 1
        : 2;
    final estimatedLines =
        (hasDescription ? descriptionMaxLines : 0) +
        (hasMetaRow ? 1 : 0) +
        (hasProjectRow ? 1 : 0);

    return ListTile(
      contentPadding:
          contentPadding ?? const EdgeInsets.symmetric(horizontal: 0),
      leading: leading ?? const Icon(Icons.checklist),
      isThreeLine: estimatedLines > 2,
      title: Text(
        task.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          decoration: isCompleted ? TextDecoration.lineThrough : null,
          color: isCompleted ? theme.colorScheme.onSurfaceVariant : null,
        ),
      ),
      trailing: trailing,
      subtitle: _buildSubtitle(
        theme: theme,
        description: description,
        hasDescription: hasDescription,
        hasDeadline: hasDeadline,
        hasStatus: hasStatus,
        hasProjectRow: hasProjectRow,
        descriptionMaxLines: descriptionMaxLines,
        statusLabel: statusLabel,
        deadline: deadline,
        projectName: projectName,
      ),
      onTap:
          onTap ??
          () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider(
                  create: (_) => TaskDetailProvider(),
                  child: TaskDetailScreen(taskId: task.id),
                ),
              ),
            );
          },
    );
  }

  Widget? _buildSubtitle({
    required ThemeData theme,
    required String description,
    required bool hasDescription,
    required bool hasDeadline,
    required bool hasStatus,
    required bool hasProjectRow,
    required int descriptionMaxLines,
    required String statusLabel,
    required DateTime? deadline,
    required String projectName,
  }) {
    final children = <Widget>[];

    void addSpacing() {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 6));
      }
    }

    if (hasDescription) {
      children.add(
        Text(
          description,
          maxLines: descriptionMaxLines,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    if (hasDeadline || hasStatus) {
      addSpacing();
      final rowChildren = <Widget>[];
      if (hasDeadline) {
        final deadlineValue = deadline!; // safe due to hasDeadline guard
        rowChildren.addAll([
          const Icon(Icons.calendar_today, size: 14),
          const SizedBox(width: 4),
          Text(
            _formatDeadlineText(deadlineValue),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ]);
      }
      if (hasDeadline && hasStatus) {
        rowChildren.add(const SizedBox(width: 12));
      }
      if (hasStatus) {
        rowChildren.addAll([
          const Icon(Icons.flag, size: 14),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              statusLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]);
      }
      children.add(
        Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: rowChildren,
        ),
      );
    }

    if (hasProjectRow) {
      addSpacing();
      children.add(
        Row(
          children: [
            const Icon(Icons.folder_outlined, size: 14),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                projectName.isNotEmpty ? projectName : projectPlaceholder,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    if (children.isEmpty) {
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _formatDeadlineText(DateTime value) {
    final label = deadlineLabel?.trim();
    if (label != null && label.isNotEmpty) {
      return '$label: ${_formatDate(value)}';
    }
    return _formatDate(value);
  }
}
