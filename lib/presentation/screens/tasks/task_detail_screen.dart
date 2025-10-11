import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../providers/task_detail_provider.dart';
import '../../../data/models/api_task_models.dart';
import '../../widgets/project_widgets.dart';
import 'create_task_screen.dart';
import '../../../data/datasources/tasks_api_remote_datasource.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TasksApiRemoteDataSource _ds = TasksApiRemoteDataSource();
  final List<ApiTask> _parentChain = []; // from root -> immediate parent
  bool _loadingParents = false;
  final Map<int, ApiTask> _taskCache = {}; // simple in-memory cache
  String? _parentError;
  bool _loadingChildren = false;
  List<ApiTask> _childSubtasks = [];
  String? _childrenError;

  Color _alpha(Color base, double opacity) => base.withValues(alpha: opacity);

  Future<void> _buildParentChain(ApiTask task) async {
    // Clear and rebuild if parent exists
    if (task.parentTaskId == null) {
      setState(() {
        _parentChain.clear();
        _parentError = null;
      });
      return;
    }
    if (_loadingParents) return;
    _loadingParents = true;
    final chain = <ApiTask>[];
    int? currentParentId = task.parentTaskId;
    // Safety depth limit to avoid accidental loops
    int depth = 0;
    String? error;
    try {
      while (currentParentId != null && depth < 10) {
        if (_taskCache.containsKey(currentParentId)) {
          final cached = _taskCache[currentParentId]!;
          chain.insert(0, cached);
          currentParentId = cached.parentTaskId;
          depth++;
          continue;
        }
        final res = await _ds.getTaskById(currentParentId);
        if (!res.isSuccess || res.data == null) {
          error = 'Failed to load parent task #$currentParentId';
          break;
        }
        final parentTask = res.data!;
        _taskCache[parentTask.id] = parentTask;
        chain.insert(0, parentTask); // root-first order
        currentParentId = parentTask.parentTaskId;
        depth++;
      }
    } catch (e) {
      error = e.toString();
    }
    if (mounted) {
      setState(() {
        if (error != null) {
          _parentError = error;
        } else {
          _parentError = null;
        }
        _parentChain
          ..clear()
          ..addAll(chain);
      });
    }
    _loadingParents = false;
  }

  Future<void> _loadChildren(ApiTask task) async {
    if (_loadingChildren) return;
    _loadingChildren = true;
    setState(() {
      _childrenError = null;
      _childSubtasks = [];
    });
    try {
      // Reuse getTasks filtering by project then local filter (API lacks direct parent filter param)
      if (task.project?.id != null) {
        final res = await _ds.getTasks(
          projectId: task.project!.id,
          perPage: 100,
        );
        if (res.isSuccess && res.data != null) {
          final list = res.data!;
          final children = list
              .where((t) => t.parentTaskId == task.id)
              .toList();
          if (mounted) {
            setState(() {
              _childSubtasks = children;
            });
          }
        } else if (mounted) {
          setState(() => _childrenError = 'Failed to load subtasks');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _childrenError = e.toString());
    }
    _loadingChildren = false;
  }

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
          // Build chain + children once task loads (and when task id changes)
          _buildParentChain(task);
          _loadChildren(task);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(context, theme, task),
                if (task.parentTaskId != null) ...[
                  const SizedBox(height: 12),
                  _breadcrumb(theme, task, AppLocalizations.of(context)),
                  if (_parentError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 16,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _parentError!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _buildParentChain(task),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                ],
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
                _childrenSection(theme, task, loc),
                const SizedBox(height: 24),
                if (task.project?.id != null && task.project!.id != 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.call_split),
                      onPressed: () async {
                        final projectId = task.project!.id;
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CreateTaskScreen(
                              projectId: projectId,
                              fixedParentTaskId: task.id,
                            ),
                          ),
                        );
                      },
                      label: Text(loc.translate('tasks.createSubtask')),
                    ),
                  ),
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

  Widget _breadcrumb(ThemeData theme, ApiTask current, AppLocalizations loc) {
    // Combine parent chain + current
    final full = [..._parentChain, current];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < full.length; i++) ...[
            GestureDetector(
              onTap: i == full.length - 1
                  ? null
                  : () {
                      final target = full[i];
                      if (target.id == current.id) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider(
                            create: (_) => TaskDetailProvider(),
                            child: TaskDetailScreen(taskId: target.id),
                          ),
                        ),
                      );
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: i == full.length - 1
                      ? _alpha(theme.colorScheme.primary, 0.1)
                      : _alpha(theme.colorScheme.surfaceContainerHighest, 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '#${full[i].id}  ${full[i].name}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: i == full.length - 1 ? FontWeight.bold : null,
                    color: i == full.length - 1
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            if (i < full.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: _alpha(theme.colorScheme.onSurface, 0.6),
                ),
              ),
          ],
        ],
      ),
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

  Widget _childrenSection(ThemeData theme, ApiTask task, AppLocalizations loc) {
    if (_loadingChildren) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_childrenError != null) {
      return Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _childrenError!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _loadChildren(task),
            child: Text(loc.translate('common.retry')),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.translate('tasks.subtasks'),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (_childSubtasks.isEmpty)
          Text(
            loc.translate('tasks.noSubtasks'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _childSubtasks.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final st = _childSubtasks[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.subdirectory_arrow_right),
                title: Text(st.name),
                subtitle: Text('#${st.id}'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider(
                        create: (_) => TaskDetailProvider(),
                        child: TaskDetailScreen(taskId: st.id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
