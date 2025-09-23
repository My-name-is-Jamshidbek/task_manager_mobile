import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../providers/task_detail_provider.dart';
import '../../../data/models/api_task_models.dart';
import '../../widgets/project_widgets.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<TaskDetailProvider>().load(widget.taskId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('tasks.details'))),
      body: Consumer<TaskDetailProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.task == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 40,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(provider.error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => provider.load(widget.taskId),
                      child: Text(loc.translate('common.retry')),
                    ),
                  ],
                ),
              ),
            );
          }
          final task = provider.task!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(context, theme, task),
                const SizedBox(height: 16),
                _meta(theme, task, loc),
                const SizedBox(height: 16),
                if ((task.description ?? '').trim().isNotEmpty)
                  Text(task.description!, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 24),
                _workers(theme, task, loc),
                const SizedBox(height: 24),
                _files(theme, task, loc),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context, ThemeData theme, ApiTask task) {
    final project = task.project;
    return Row(
      children: [
        const CircleAvatar(child: Icon(Icons.task_alt)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (project != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    InfoPill(icon: Icons.folder, label: project.name),
                    if (task.status?.label != null)
                      InfoPill(icon: Icons.flag, label: task.status!.label!),
                    if (task.timeProgress?.label != null)
                      InfoPill(
                        icon: Icons.timelapse,
                        label: task.timeProgress!.label!,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _meta(ThemeData theme, ApiTask task, AppLocalizations loc) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.translate('tasks.meta'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 6),
                Text(task.deadline != null ? _formatDate(task.deadline!) : '-'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.category, size: 16),
                const SizedBox(width: 6),
                Text(task.taskType?.name ?? '-'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _workers(ThemeData theme, ApiTask task, AppLocalizations loc) {
    if (task.workers.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.translate('tasks.workers'),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: task.workers.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final u = task.workers[index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(u.name ?? '—'),
              subtitle: Text(u.phone ?? ''),
            );
          },
        ),
      ],
    );
  }

  Widget _files(ThemeData theme, ApiTask task, AppLocalizations loc) {
    if (task.files.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.translate('tasks.files'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: task.files.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final f = task.files[index];
            return ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                f.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {},
            );
          },
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
