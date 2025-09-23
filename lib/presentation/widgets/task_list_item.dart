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
  final VoidCallback? onTap;

  const TaskListItem({
    super.key,
    required this.task,
    this.contentPadding,
    this.showDescription = true,
    this.showStatus = true,
    this.showDeadline = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = task.status?.label ?? '';
    final deadline = task.deadline;

    return ListTile(
      contentPadding:
          contentPadding ?? const EdgeInsets.symmetric(horizontal: 0),
      leading: const Icon(Icons.checklist),
      title: Text(
        task.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showDescription && (task.description ?? '').trim().isNotEmpty)
            Text(
              task.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          Row(
            children: [
              if (showDeadline && deadline != null) ...[
                const Icon(Icons.calendar_today, size: 14),
                const SizedBox(width: 4),
                Text(_formatDate(deadline)),
                const SizedBox(width: 8),
              ],
              if (showStatus && statusLabel.isNotEmpty) ...[
                const Icon(Icons.flag, size: 14),
                const SizedBox(width: 4),
                Text(statusLabel),
              ],
            ],
          ),
        ],
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

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
