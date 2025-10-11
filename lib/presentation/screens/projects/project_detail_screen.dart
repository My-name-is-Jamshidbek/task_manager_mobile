import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../providers/project_detail_provider.dart';
import '../../../data/models/project_models.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/project_widgets.dart';
import '../../widgets/file_viewer_dialog.dart';
import '../tasks/create_task_screen.dart';
// Removed direct task detail imports; navigation is handled by TaskListItem
import '../../widgets/task_list_item.dart';

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<ProjectDetailProvider>().load(widget.projectId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('common.details')),
        actions: [
          Consumer<ProjectDetailProvider>(
            builder: (context, provider, _) {
              final project = provider.project;
              if (project == null) return const SizedBox.shrink();
              return IconButton(
                tooltip: loc.translate('tasks.addTask'),
                icon: const Icon(Icons.add_task),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreateTaskScreen(
                        projectId: project.id,
                        projectCreatorId: project.creator.id,
                      ),
                    ),
                  );
                  if (!context.mounted) return;
                  // After creating a task, reload project details and refresh tasks
                  context.read<ProjectDetailProvider>().load(project.id);
                  // Reload project to get updated embedded tasks
                  await context.read<ProjectDetailProvider>().load(project.id);
                },
              );
            },
          ),
          Consumer<ProjectDetailProvider>(
            builder: (context, provider, _) {
              final project = provider.project;
              if (project == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  final text =
                      '📁 ${project.name}\n${project.description ?? ''}'.trim();
                  Share.share(text);
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<ProjectDetailProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.project == null) {
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
                      color: theme.colorScheme.error,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(provider.error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => provider.load(widget.projectId),
                      child: Text(loc.translate('common.retry')),
                    ),
                  ],
                ),
              ),
            );
          }
          final project = provider.project!;
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<ProjectDetailProvider>().load(project.id),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header(context, project, provider, theme, loc),
                const SizedBox(height: 16),
                _description(project, theme),
                const SizedBox(height: 24),
                _taskStats(project, theme, loc),
                const SizedBox(height: 24),
                _filesSection(provider, theme, loc),
                const SizedBox(height: 24),
                _projectTasksSection(context, loc, theme, provider),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(
    BuildContext context,
    Project project,
    ProjectDetailProvider provider,
    ThemeData theme,
    AppLocalizations loc,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _avatar(project.creator),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  InfoPill(icon: Icons.person, label: project.creator.name),
                  InfoPill(
                    icon: Icons.calendar_today,
                    label: _formatDate(project.createdAt),
                  ),
                  if (provider.files.isNotEmpty)
                    InfoPill(
                      icon: Icons.attach_file,
                      label: '${provider.files.length}',
                    ),
                  InfoPill(
                    icon: Icons.checklist,
                    label: '${project.taskStats?.total ?? 0}',
                  ),
                  if (project.status != null)
                    ProjectStatusChip(project: project),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _description(Project project, ThemeData theme) {
    if ((project.description ?? '').trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(project.description ?? '', style: theme.textTheme.bodyLarge),
      ],
    );
  }

  Widget _taskStats(Project project, ThemeData theme, AppLocalizations loc) {
    final total = project.taskStats?.total ?? 0;
    final completed =
        project.taskStats?.byStatus
            .firstWhere(
              (s) => s.status == 'completed',
              orElse: () => const ByStatus(status: 'x', label: null, count: 0),
            )
            .count ??
        0;
    final progress = total > 0 ? completed / total : 0;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.translate('projects.progress'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress.toDouble()),
            const SizedBox(height: 8),
            Text('${(progress * 100).toInt()}% • $completed/$total'),
          ],
        ),
      ),
    );
  }

  Widget _filesSection(
    ProjectDetailProvider provider,
    ThemeData theme,
    AppLocalizations loc,
  ) {
    final files = provider.files;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              loc.translate('attachments'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(width: 8),
            if (files.isNotEmpty)
              CircleAvatar(
                radius: 12,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  files.length.toString(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (files.isEmpty)
          Text(
            loc.translate('noAttachments'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: files.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final f = files[index];
              final icon = _fileIconForName(f.name);
              return ListTile(
                leading: Icon(icon),
                title: Text(
                  f.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  f.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => showFileViewer(
                  context,
                  fileId: f.id ?? 0, // Use file ID if available
                  fileName: f.name,
                  fileUrl: f.url,
                ),
              );
            },
          ),
      ],
    );
  }

  IconData _fileIconForName(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'txt':
      case 'md':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _projectTasksSection(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    ProjectDetailProvider provider,
  ) {
    final tasks = provider.tasks;
    final loading = provider.isLoading; // when reloading project
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              loc.translate('projects.tasks'),
              style: theme.textTheme.titleMedium,
            ),
            const Spacer(),
            IconButton(
              tooltip: loc.translate('common.refresh'),
              onPressed: loading
                  ? null
                  : () => provider.load(provider.project!.id),
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (loading && tasks.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (tasks.isEmpty)
          Text(
            loc.translate('tasks.noTasks'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) => TaskListItem(task: tasks[index]),
          ),
      ],
    );
  }

  Widget _avatar(Creator creator) {
    if ((creator.avatarUrl ?? '').isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(creator.avatarUrl!),
      );
    }
    final initials = creator.name.trim().isNotEmpty
        ? creator.name
              .trim()
              .split(RegExp(r"\s+"))
              .map((e) => e[0].toUpperCase())
              .take(2)
              .join()
        : '?';
    return CircleAvatar(radius: 28, child: Text(initials));
  }

  // _chip and _buildStatusChip removed in favor of shared InfoPill and ProjectStatusChip widgets.

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
