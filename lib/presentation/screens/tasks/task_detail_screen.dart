import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../data/datasources/tasks_api_remote_datasource.dart';
import '../../../data/models/api_task_models.dart';
import '../../../data/models/file_models.dart';
import '../../../data/models/project_models.dart'
    as project_models
    show FileAttachment;
import '../../../data/models/task_action.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_detail_provider.dart';
import '../../widgets/file_group_attachments_card.dart';
import '../../widgets/task_assignees_card.dart';
import '../../widgets/task_list_item.dart';
import '../../utils/task_action_helper.dart';
import 'create_task_screen.dart';
import 'edit_task_screen.dart';
import 'task_completion_screen.dart';
import 'task_rejection_screen.dart';
import 'task_worker_detail_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _MetaInfo {
  final IconData icon;
  final String label;
  final String value;
  const _MetaInfo({
    required this.icon,
    required this.label,
    required this.value,
  });
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
        chain.insert(0, parentTask);
        currentParentId = parentTask.parentTaskId;
        depth++;
      }
    } catch (e) {
      error = e.toString();
    }

    if (!mounted) return;
    setState(() {
      _loadingParents = false;
      _parentError = error;
      if (error == null) {
        _parentChain
          ..clear()
          ..addAll(chain);
      }
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
          Consumer2<TaskDetailProvider, AuthProvider>(
            builder: (context, detailProvider, authProvider, _) {
              final task = detailProvider.task;
              final currentUserId = authProvider.currentUser?.id;
              if (task == null || currentUserId == null) {
                return const SizedBox.shrink();
              }
              final canEdit = task.creator?.id == currentUserId;
              if (!canEdit) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: loc.translate('tasks.editTask'),
                icon: const Icon(Icons.edit_note),
                onPressed: () async {
                  final updated = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditTaskScreen(task: task),
                    ),
                  );
                  if (!context.mounted) return;
                  if (updated == true) {
                    await _reloadTask(detailProvider, task.id);
                  }
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
          final List<FileAttachment> initialAttachments =
              provider.attachments.isNotEmpty
              ? provider.attachments
              : _convertProjectFiles(task.files);
          final actionSection = _actionsSection(
            context,
            theme,
            loc,
            provider,
            task,
          );
          return RefreshIndicator(
            onRefresh: () => _reloadTask(provider, task.id),
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _overviewCard(context, theme, loc, task),
                const SizedBox(height: 18),
                if (actionSection != null) ...[
                  actionSection,
                  const SizedBox(height: 18),
                ],
                _metaSection(theme, loc, task),
                if ((task.description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _descriptionSection(theme, task),
                ],
                const SizedBox(height: 18),
                _workersSection(theme, loc, provider, task),
                const SizedBox(height: 18),
                FileGroupAttachmentsCard(
                  fileGroupId: task.fileGroupId,
                  title: loc.translate('attachments'),
                  groupName: 'Task Files',
                  allowEditing: _canEditTask(task),
                  initialFiles: initialAttachments,
                ),
                const SizedBox(height: 18),
                _parentSection(theme, loc, task),
                const SizedBox(height: 18),
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
    final currentUserId = context.read<AuthProvider?>()?.currentUser?.id;
    final actions = TaskActionHelper.deriveActions(task, currentUserId);
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
    final style = TaskActionHelper.buttonStyleForAction(theme, action);
    return FilledButton(
      style: style,
      onPressed: busy
          ? null
          : () => _handleAction(context, loc, provider, action),
      child: _actionButtonChild(label, busy, theme, action),
    );
  }

  Widget _actionButtonChild(
    String label,
    bool busy,
    ThemeData theme,
    TaskActionKind action,
  ) {
    final progressColor = TaskActionHelper.progressColor(theme, action);
    final icon = TaskActionHelper.iconForAction(action);
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

  Future<void> _handleAction(
    BuildContext context,
    AppLocalizations loc,
    TaskDetailProvider provider,
    TaskActionKind action,
  ) async {
    String? reason;
    int? fileGroupId;

    // Use specialized screen for task completion
    if (action == TaskActionKind.complete) {
      final task = provider.task;
      if (task == null) return;

      // Navigate to completion screen
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) =>
              TaskCompletionScreen(task: task, taskProvider: provider),
        ),
      );

      // If screen returned true, refresh was successful
      if (result == true && context.mounted) {
        final successMessage = TaskActionHelper.buildSuccessMessage(
          loc,
          action,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      }
      return;
    } else if (action == TaskActionKind.reject) {
      final task = provider.task;
      if (task == null) return;

      // Navigate to rejection screen
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) =>
              TaskRejectionScreen(task: task, taskProvider: provider),
        ),
      );

      // If screen returned true, refresh was successful
      if (result == true && context.mounted) {
        final successMessage = TaskActionHelper.buildSuccessMessage(
          loc,
          action,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      }
      return;
    } else if (action.requiresReason) {
      reason = await TaskActionHelper.promptForReason(context, loc, action);
      if (reason == null) return;
    } else {
      final confirmed = await TaskActionHelper.confirmAction(
        context,
        loc,
        action,
      );
      if (!confirmed) return;
    }

    final success = await provider.performAction(
      action,
      reason: reason,
      fileGroupId: fileGroupId,
    );
    if (!context.mounted) return;
    if (success) {
      final successMessage = TaskActionHelper.buildSuccessMessage(loc, action);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } else {
      final error =
          provider.actionError ?? loc.translate('tasks.actions.genericError');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Widget _overviewCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations loc,
    ApiTask task,
  ) {
    final projectName = task.project?.name ?? '—';
    final dueDateLabel = task.deadline != null
        ? _formatDate(task.deadline!)
        : loc.translate('tasks.dueDate');
    final priorityLabel =
        task.taskType?.name ?? loc.translate('priority.medium');
    final timeLabel = task.timeProgress?.label;
    final creatorName = task.creator?.name;
    final surfaceText = theme.colorScheme.onPrimaryContainer;
    final gradient = LinearGradient(
      colors: [
        theme.colorScheme.primaryContainer,
        theme.colorScheme.secondaryContainer,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _avatar(task.creator),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: surfaceText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if ((task.status?.label ?? '').isNotEmpty)
                          _buildTagChip(
                            theme,
                            icon: Icons.flag,
                            label: task.status!.label!,
                          ),
                        _buildTagChip(
                          theme,
                          icon: Icons.calendar_today,
                          label: dueDateLabel,
                        ),
                        _buildTagChip(
                          theme,
                          icon: Icons.tune,
                          label: priorityLabel,
                        ),
                        if ((timeLabel ?? '').isNotEmpty)
                          _buildTagChip(
                            theme,
                            icon: Icons.timelapse,
                            label: timeLabel!,
                          ),
                        if ((creatorName ?? '').isNotEmpty)
                          _buildTagChip(
                            theme,
                            icon: Icons.person,
                            label: creatorName!,
                          ),
                        if (task.files.isNotEmpty)
                          _buildTagChip(
                            theme,
                            icon: Icons.attach_file,
                            label: '${task.files.length}',
                          ),
                        if (task.parentTaskId != null)
                          _buildTagChip(
                            theme,
                            icon: Icons.account_tree_outlined,
                            label: '#${task.parentTaskId}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(color: surfaceText.withOpacity(0.2)),
          const SizedBox(height: 12),
          _overviewRow(
            theme,
            icon: Icons.folder_open,
            label: loc.translate('projects.title'),
            value: projectName,
            textColor: surfaceText,
          ),
          if ((task.creator?.phone ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            _overviewRow(
              theme,
              icon: Icons.call,
              label: loc.translate('profile.phone'),
              value: task.creator!.phone!,
              textColor: surfaceText,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagChip(
    ThemeData theme, {
    required IconData icon,
    required String label,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onPrimaryContainer;
    final background = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.white.withOpacity(0.2);
    return Chip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      backgroundColor: background,
      avatar: Icon(icon, size: 16, color: textColor),
      label: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _overviewRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required Color textColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: textColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor.withOpacity(0.75),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
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
    final items = <_MetaInfo>[
      _MetaInfo(
        icon: Icons.calendar_month,
        label: loc.translate('tasks.dueDate'),
        value: task.deadline != null ? _formatDate(task.deadline!) : '—',
      ),
      _MetaInfo(
        icon: Icons.flag_outlined,
        label: loc.translate('tasks.status'),
        value: task.status?.label ?? '—',
      ),
      _MetaInfo(
        icon: Icons.tune,
        label: loc.translate('tasks.priority'),
        value: task.taskType?.name ?? loc.translate('priority.medium'),
      ),
    ];

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
            LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                final tileWidth = maxWidth >= 520
                    ? (maxWidth - 12) / 2
                    : maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: items.map((item) {
                    return SizedBox(
                      width: tileWidth,
                      child: _metaTile(theme, item),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaTile(ThemeData theme, _MetaInfo item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: theme.colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            item.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _workersSection(
    ThemeData theme,
    AppLocalizations loc,
    TaskDetailProvider provider,
    ApiTask task,
  ) {
    // Use provider.workers which contains the workers fetched from API with task worker ID
    final workerUsers = provider.workers;

    return TaskAssigneesCard(
      workers: workerUsers,
      isLoading: provider.isWorkersLoading,
      error: provider.workersError,
      onRefresh: provider.reloadWorkers,
      onWorkerTap: (worker) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TaskWorkerDetailScreen(
              taskId: task.id,
              // Use taskWorkerId if available, otherwise use user id
              workerId: worker.taskWorkerId ?? worker.id,
            ),
          ),
        );
      },
      title: loc.translate('tasks.workers'),
      showHeader: true,
      getStatusColor: _getColorForStatus,
    );
  }

  bool _canEditTask(ApiTask task) {
    final auth = context.read<AuthProvider?>();
    final currentUserId = auth?.currentUser?.id;
    if (currentUserId == null) return false;
    return task.creator?.id == currentUserId;
  }

  Color _getColorForStatus(String statusColor) {
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

List<FileAttachment> _convertProjectFiles(
  List<project_models.FileAttachment> files,
) {
  if (files.isEmpty) return const <FileAttachment>[];
  return files
      .map(
        (file) => FileAttachment(name: file.name, url: file.url, id: file.id),
      )
      .toList(growable: false);
}
