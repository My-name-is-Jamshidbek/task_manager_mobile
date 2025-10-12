import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../data/datasources/tasks_api_remote_datasource.dart';
import '../../../data/models/api_task_models.dart';
import '../../../data/models/task_action.dart';
import '../../providers/task_detail_provider.dart';
import '../../widgets/file_viewer_dialog.dart';
import '../../widgets/project_widgets.dart';
import '../../widgets/task_list_item.dart';
import 'create_task_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TasksApiRemoteDataSource _ds = TasksApiRemoteDataSource();
  final List<ApiTask> _parentChain = []; // from root -> immediate parent
  final Map<int, ApiTask> _taskCache = {}; // simple in-memory cache
  bool _loadingParents = false;
  String? _parentError;
  bool _loadingChildren = false;
  List<ApiTask> _childSubtasks = [];
  String? _childrenError;
  int? _lastProcessedTaskId;

  Color _alpha(Color base, double opacity) => base.withValues(alpha: opacity);

  Future<void> _buildParentChain(ApiTask task) async {
    // Clear and rebuild if parent exists
    if (task.parentTaskId == null) {
      if (!mounted) return;
      setState(() {
        _parentChain.clear();
        _parentError = null;
        _loadingParents = false;
      });
      return;
    }
    if (_loadingParents) return;
    if (mounted) {
      setState(() {
        _loadingParents = true;
        _parentError = null;
      });
    }
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
    if (!mounted) return;
    setState(() {
      _loadingParents = false;
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

  Future<void> _loadChildren(ApiTask task) async {
    if (_loadingChildren) return;
    setState(() {
      _loadingChildren = true;
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
    if (mounted) {
      setState(() {
        _loadingChildren = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<TaskDetailProvider>().load(widget.taskId),
    );
  }

  void _ensureTaskSideData(ApiTask task) {
    if (_lastProcessedTaskId == task.id) return;
    _lastProcessedTaskId = task.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _lastProcessedTaskId != task.id) return;
      _buildParentChain(task);
      _loadChildren(task);
    });
  }

  Future<void> _reloadTask(TaskDetailProvider provider, int taskId) async {
    _lastProcessedTaskId = null;
    await provider.load(taskId);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('tasks.details')),
        actions: [
          Consumer<TaskDetailProvider>(
            builder: (context, provider, _) {
              final task = provider.task;
              if (task == null ||
                  task.project?.id == null ||
                  task.project!.id == 0) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: loc.translate('tasks.createSubtask'),
                icon: const Icon(Icons.add_task),
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
                  if (!context.mounted) return;
                  final provider = context.read<TaskDetailProvider>();
                  await _reloadTask(provider, task.id);
                },
              );
            },
          ),
          Consumer<TaskDetailProvider>(
            builder: (context, provider, _) {
              final task = provider.task;
              if (task == null) return const SizedBox.shrink();
              return IconButton(
                tooltip: loc.translate('tasks.share'),
                icon: const Icon(Icons.share),
                onPressed: () {
                  final text = '🗒️ ${task.name}\n${task.description ?? ''}'
                      .trim();
                  Share.share(text);
                },
              );
            },
          ),
        ],
      ),
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
          _ensureTaskSideData(task);
          final actionSection =
              _actionsSection(context, theme, loc, provider, task);
          return RefreshIndicator(
            onRefresh: () => _reloadTask(provider, task.id),
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _header(context, theme, task),
                const SizedBox(height: 16),
                if (actionSection != null) ...[
                  actionSection,
                  const SizedBox(height: 16),
                ],
                _parentSection(theme, loc, task),
                if ((task.description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _descriptionSection(theme, task),
                ],
                const SizedBox(height: 16),
                _metaSection(theme, loc, task),
                const SizedBox(height: 16),
                _workersSection(theme, loc, task),
                const SizedBox(height: 16),
                _filesSection(theme, loc, task),
                const SizedBox(height: 16),
                _subtasksSection(theme, loc, task),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget? _actionsSection(
    BuildContext context,
    ThemeData theme,
    AppLocalizations loc,
    TaskDetailProvider provider,
    ApiTask task,
  ) {
    final actions = _deriveActions(task);
    if (actions.isEmpty) return null;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  loc.translate('tasks.actions.title'),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: actions
                  .map(
                    (action) => _buildActionButton(
                      context,
                      theme,
                      loc,
                      provider,
                      action,
                    ),
                  )
                  .toList(),
            ),
            if (provider.actionError != null && !provider.isActionInProgress)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  provider.actionError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    ThemeData theme,
    AppLocalizations loc,
    TaskDetailProvider provider,
    TaskActionKind action,
  ) {
    final label = loc.translate(action.translationKey);
    final busy = provider.isActionBusy(action);
    final icon = _iconForAction(action);
    final style = _buttonStyleForAction(theme, action);
    return FilledButton(
      style: style,
      onPressed: busy
          ? null
          : () => _handleAction(context, loc, provider, action),
      child: _actionButtonChild(
        label,
        icon,
        busy,
        theme,
        action,
      ),
    );
  }

  Widget _actionButtonChild(
    String label,
    IconData icon,
    bool busy,
    ThemeData theme,
    TaskActionKind action,
  ) {
    final progressColor = _progressColor(theme, action);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (busy)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: progressColor,
            ),
          )
        else
          Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  IconData _iconForAction(TaskActionKind action) {
    switch (action) {
      case TaskActionKind.accept:
        return Icons.task_alt;
      case TaskActionKind.complete:
        return Icons.check_circle_outline;
      case TaskActionKind.reject:
        return Icons.cancel;
      case TaskActionKind.approveCompletion:
        return Icons.verified;
      case TaskActionKind.rework:
        return Icons.restart_alt;
    }
  }

  ButtonStyle? _buttonStyleForAction(ThemeData theme, TaskActionKind action) {
    switch (action) {
      case TaskActionKind.reject:
        return FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.error,
          foregroundColor: theme.colorScheme.onError,
        );
      case TaskActionKind.rework:
        return FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.secondaryContainer,
          foregroundColor: theme.colorScheme.onSecondaryContainer,
        );
      case TaskActionKind.approveCompletion:
        return FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
        );
      case TaskActionKind.accept:
      case TaskActionKind.complete:
        return null;
    }
  }

  Color _progressColor(ThemeData theme, TaskActionKind action) {
    switch (action) {
      case TaskActionKind.reject:
        return theme.colorScheme.onError;
      case TaskActionKind.rework:
        return theme.colorScheme.onSecondaryContainer;
      case TaskActionKind.approveCompletion:
        return theme.colorScheme.onPrimaryContainer;
      case TaskActionKind.accept:
      case TaskActionKind.complete:
        return theme.colorScheme.onPrimary;
    }
  }

  Future<void> _handleAction(
    BuildContext context,
    AppLocalizations loc,
    TaskDetailProvider provider,
    TaskActionKind action,
  ) async {
    String? reason;
    if (action.requiresReason) {
      reason = await _promptForReason(context, loc, action);
      if (reason == null) return;
    } else {
      final confirmed = await _confirmAction(context, loc, action);
      if (!confirmed) return;
    }

    final success = await provider.performAction(action, reason: reason);
    if (!context.mounted) return;
    if (success) {
      final successMessage = loc.translateWithParams(
        'tasks.actions.successMessage',
        {'action': loc.translate(action.translationKey)},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } else {
      final error = provider.actionError ??
          loc.translate('tasks.actions.genericError');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  Future<bool> _confirmAction(
    BuildContext context,
    AppLocalizations loc,
    TaskActionKind action,
  ) async {
    final actionLabel = loc.translate(action.translationKey);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('tasks.actions.confirmTitle')),
        content: Text(
          loc.translateWithParams(
            'tasks.actions.confirmMessage',
            {'action': actionLabel},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.translate('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.translate('tasks.actions.proceed')),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<String?> _promptForReason(
    BuildContext context,
    AppLocalizations loc,
    TaskActionKind action,
  ) async {
    final controller = TextEditingController();
    String? errorText;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(loc.translate(action.translationKey)),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: loc.translate('tasks.actions.reasonLabel'),
              hintText: loc.translate('tasks.actions.reasonHint'),
              errorText: errorText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(loc.translate('common.cancel')),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) {
                  setState(
                    () => errorText =
                        loc.translate('tasks.actions.reasonRequired'),
                  );
                  return;
                }
                Navigator.of(context).pop(text);
              },
              child: Text(loc.translate('tasks.actions.proceed')),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
  }

  List<TaskActionKind> _deriveActions(ApiTask task) {
    final result = <TaskActionKind>[];
    for (final raw in task.availableActions) {
      final action = _mapAction(raw);
      if (action != null && !result.contains(action)) {
        result.add(action);
      }
    }
    if (result.isNotEmpty) {
      return result;
    }

    final statusLabel = (task.status?.label ?? '').toLowerCase();
    void addIfMissing(TaskActionKind action) {
      if (!result.contains(action)) result.add(action);
    }

    if (statusLabel.contains('pending') || statusLabel.contains('await')) {
      addIfMissing(TaskActionKind.accept);
      addIfMissing(TaskActionKind.reject);
    } else if (statusLabel.contains('progress') ||
        statusLabel.contains('accepted')) {
      addIfMissing(TaskActionKind.complete);
    } else if (statusLabel.contains('complete') ||
        statusLabel.contains('approval') ||
        statusLabel.contains('review')) {
      addIfMissing(TaskActionKind.approveCompletion);
      addIfMissing(TaskActionKind.rework);
    }

    return result;
  }

  TaskActionKind? _mapAction(String raw) {
    final normalized = _normalizeActionValue(raw);
    for (final action in TaskActionKind.values) {
      final nameMatch = _normalizeActionValue(action.name);
      final pathMatch = _normalizeActionValue(action.pathSegment);
      if (normalized == nameMatch || normalized == pathMatch) {
        return action;
      }
    }
    return null;
  }

  String _normalizeActionValue(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

  Widget _header(BuildContext context, ThemeData theme, ApiTask task) {
    final project = task.project;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _avatar(task.creator),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (project != null)
                    InfoPill(icon: Icons.folder, label: project.name),
                  if (task.status?.label != null)
                    InfoPill(icon: Icons.flag, label: task.status!.label!),
                  if (task.timeProgress?.label != null)
                    InfoPill(
                      icon: Icons.timelapse,
                      label: task.timeProgress!.label!,
                    ),
                  if (task.deadline != null)
                    InfoPill(
                      icon: Icons.calendar_today,
                      label: _formatDate(task.deadline!),
                    ),
                  if ((task.creator?.name ?? '').isNotEmpty)
                    InfoPill(icon: Icons.person, label: task.creator!.name!),
                  if (task.files.isNotEmpty)
                    InfoPill(
                      icon: Icons.attach_file,
                      label: '${task.files.length}',
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _parentSection(ThemeData theme, AppLocalizations loc, ApiTask task) {
    final hasParents = _parentChain.isNotEmpty;
    if (task.parentTaskId == null && !hasParents && !_loadingParents) {
      return const SizedBox.shrink();
    }
    final fullChain = [..._parentChain, task];
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_tree, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  loc.translate('tasks.parentTask'),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loadingParents)
              const LinearProgressIndicator(minHeight: 2)
            else if (_parentError != null)
              Row(
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
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
                    child: Text(loc.translate('common.retry')),
                  ),
                ],
              )
            else if (fullChain.length == 1)
              Text(
                loc.translate('tasks.noParent'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int i = 0; i < fullChain.length; i++) ...[
                      GestureDetector(
                        onTap: i == fullChain.length - 1
                            ? null
                            : () {
                                final target = fullChain[i];
                                if (target.id == task.id) return;
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => ChangeNotifierProvider(
                                      create: (_) => TaskDetailProvider(),
                                      child: TaskDetailScreen(
                                        taskId: target.id,
                                      ),
                                    ),
                                  ),
                                );
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: i == fullChain.length - 1
                                ? _alpha(theme.colorScheme.primary, 0.12)
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '#${fullChain[i].id}  ${fullChain[i].name}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: i == fullChain.length - 1
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: i == fullChain.length - 1
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      if (i < fullChain.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _descriptionSection(ThemeData theme, ApiTask task) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(task.description!.trim(), style: theme.textTheme.bodyLarge),
      ),
    );
  }

  Widget _metaSection(ThemeData theme, AppLocalizations loc, ApiTask task) {
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
            const SizedBox(height: 12),
            _metaRow(
              theme,
              icon: Icons.calendar_today,
              label: loc.translate('tasks.dueDate'),
              value: task.deadline != null ? _formatDate(task.deadline!) : '-',
            ),
            const SizedBox(height: 8),
            _metaRow(
              theme,
              icon: Icons.category,
              label: loc.translate('tasks.category'),
              value: task.taskType?.name ?? '-',
            ),
            const SizedBox(height: 8),
            _metaRow(
              theme,
              icon: Icons.flag,
              label: loc.translate('tasks.status'),
              value: task.status?.label ?? '-',
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _workersSection(ThemeData theme, AppLocalizations loc, ApiTask task) {
    if (task.workers.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.translate('tasks.workers'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: task.workers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final worker = task.workers[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(worker.name ?? '—'),
                  subtitle: Text(worker.phone ?? ''),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _filesSection(ThemeData theme, AppLocalizations loc, ApiTask task) {
    if (task.files.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.attach_file),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.translate('noAttachments'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  loc.translate('attachments'),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    task.files.length.toString(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: task.files.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final file = task.files[index];
                return ListTile(
                  leading: Icon(_fileIconForName(file.name)),
                  title: Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    file.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    if (file.id != null) {
                      showFileViewer(
                        context,
                        fileId: file.id!,
                        fileName: file.name,
                        fileUrl: file.url,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            loc.translate('files.previewNotAvailable'),
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
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

  Widget _subtasksSection(ThemeData theme, AppLocalizations loc, ApiTask task) {
    if (_loadingChildren) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_childrenError != null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error),
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
          ),
        ),
      );
    }
    if (_childSubtasks.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            loc.translate('tasks.noSubtasks'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.translate('tasks.subtasks'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _childSubtasks.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final st = _childSubtasks[index];
                return TaskListItem(
                  task: st,
                  contentPadding: EdgeInsets.zero,
                  showDescription: false,
                  showStatus: true,
                  showDeadline: true,
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
        ),
      ),
    );
  }

  Widget _avatar(ApiUserRef? creator) {
    if (creator?.avatarUrl != null && creator!.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: NetworkImage(creator.avatarUrl!),
      );
    }
    final name = creator?.name?.trim() ?? '';
    final initials = name.isNotEmpty
        ? name
              .split(RegExp(r"\s+"))
              .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
              .where((e) => e.isNotEmpty)
              .take(2)
              .join()
        : '?';
    return CircleAvatar(radius: 28, child: Text(initials));
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
