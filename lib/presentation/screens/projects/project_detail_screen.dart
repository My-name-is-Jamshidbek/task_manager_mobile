import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../providers/project_detail_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/project_models.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/project_widgets.dart';
import '../../widgets/file_group_attachments_card.dart';
import '../tasks/create_task_screen.dart';
// Removed direct task detail imports; navigation is handled by TaskListItem
import '../../widgets/task_list_item.dart';
import 'edit_project_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  static const List<String> _taskGroupOrder = <String>[
    'accept',
    'in_progress',
    'completed',
    'checked_finished',
    'rejected',
    'rejected_confirmed',
  ];

  static const Map<String, String> _defaultTaskGroupLabels = <String, String>{
    'accept': 'Accept',
    'in_progress': 'In progress',
    'completed': 'Completed',
    'checked_finished': 'Checked finished',
    'rejected': 'Rejected',
    'rejected_confirmed': 'Rejected confirmed',
  };

  static const Map<String, Color> _taskGroupColors = <String, Color>{
    'accept': Colors.indigo,
    'in_progress': Colors.blue,
    'completed': Colors.green,
    'checked_finished': Colors.teal,
    'rejected': Colors.red,
    'rejected_confirmed': Colors.deepOrange,
  };

  static const Map<int?, String> _defaultTaskStatusLabels = <int?, String>{
    null: 'All statuses',
    0: 'Accept',
    1: 'In progress',
    2: 'Completed',
    3: 'Checked finished',
    4: 'Rejected',
    5: 'Rejected confirmed',
  };

  static const Map<int, String> _taskStatusCodeToGroup = <int, String>{
    0: 'accept',
    1: 'in_progress',
    2: 'completed',
    3: 'checked_finished',
    4: 'rejected',
    5: 'rejected_confirmed',
  };

  static const List<int?> _taskStatusOptions = <int?>[null, 0, 1, 2, 3, 4, 5];

  final TextEditingController _taskSearchController = TextEditingController();
  Timer? _taskSearchDebounce;
  bool _taskFiltersExpanded = false;
  bool _taskDashboardExpanded = true;
  final ScrollController _scrollController = ScrollController();
  bool _isSyncingSearchText = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<ProjectDetailProvider>().load(widget.projectId),
    );
    _taskSearchController.addListener(_handleSearchTextChanged);
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _taskSearchDebounce?.cancel();
    _taskSearchController.dispose();
    super.dispose();
  }

  void _handleSearchTextChanged() {
    if (_isSyncingSearchText) return;
    final query = _taskSearchController.text;
    _taskSearchDebounce?.cancel();
    _taskSearchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final provider = context.read<ProjectDetailProvider>();
      provider.updateTaskSearch(query);
    });
  }

  void _handleScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      final provider = context.read<ProjectDetailProvider>();
      if (provider.hasMoreTasks && !provider.isTaskListLoadingMore) {
        provider.loadMoreProjectTasks();
      }
    }
  }

  String _taskGroupLabel(AppLocalizations loc, String key) {
    final translated = loc.translate('tasks.groups.$key');
    if (translated != 'tasks.groups.$key') {
      return translated;
    }
    return _defaultTaskGroupLabels[key] ?? key;
  }

  String _taskStatusLabel(AppLocalizations loc, int? status) {
    if (status == null) {
      final translated = loc.translate('tasks.filters.statusAll');
      if (translated != 'tasks.filters.statusAll') {
        return translated;
      }
      return _defaultTaskStatusLabels[null] ?? 'All statuses';
    }

    final groupKey = _taskStatusCodeToGroup[status];
    if (groupKey != null) {
      return _taskGroupLabel(loc, groupKey);
    }

    return _defaultTaskStatusLabels[status] ?? status.toString();
  }

  Widget _buildCollapsibleSection({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required bool expanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: theme.colorScheme.primary),
            title: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: IconButton(
              onPressed: onToggle,
              icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
            ),
            onTap: onToggle,
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskFilters(
    ThemeData theme,
    AppLocalizations loc,
    ProjectDetailProvider provider,
  ) {
    final statusValue = provider.taskStatus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _taskSearchController,
          decoration: InputDecoration(
            hintText: loc.translate('tasks.searchHint'),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _taskSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _isSyncingSearchText = true;
                      _taskSearchController.clear();
                      _isSyncingSearchText = false;
                      provider.updateTaskSearch(null);
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        InputDecorator(
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            isDense: true,
            labelText: loc.translate('tasks.filters.status'),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: statusValue,
              isDense: true,
              onChanged: (value) {
                provider.updateTaskStatus(value);
              },
              items: _taskStatusOptions
                  .map(
                    (status) => DropdownMenuItem<int?>(
                      value: status,
                      child: Text(_taskStatusLabel(loc, status)),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        if (statusValue != null || provider.taskSearch != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                if (_taskSearchController.text.isNotEmpty) {
                  _isSyncingSearchText = true;
                  _taskSearchController.clear();
                  _isSyncingSearchText = false;
                }
                provider.updateTaskSearch(null);
                provider.updateTaskStatus(null);
              },
              icon: const Icon(Icons.filter_alt_off),
              label: Text(loc.translate('tasks.filters.clear')),
            ),
          ),
      ],
    );
  }

  Widget _buildTaskDashboard(
    ThemeData theme,
    ProjectDetailProvider provider,
    AppLocalizations loc,
  ) {
    final loading = provider.isTaskDashboardLoading;
    final error = provider.taskDashboardError;
    final counts = provider.taskCounts;
    final grouped = provider.groupedTaskLists;

    if (loading && counts.isEmpty && grouped.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null && counts.isEmpty && grouped.isEmpty) {
      return _buildTaskErrorState(
        theme,
        error,
        () => provider.fetchTaskDashboard(),
        loc.translate('common.retry'),
      );
    }

    final keys = <String>{...counts.keys, ...grouped.keys}.toList();
    keys.sort((a, b) {
      final indexA = _taskGroupOrder.indexOf(a);
      final indexB = _taskGroupOrder.indexOf(b);
      final safeA = indexA == -1 ? _taskGroupOrder.length : indexA;
      final safeB = indexB == -1 ? _taskGroupOrder.length : indexB;
      if (safeA != safeB) return safeA.compareTo(safeB);
      return a.compareTo(b);
    });

    final cards = keys
        .map(
          (key) => _buildTaskStatCard(
            theme,
            title: _taskGroupLabel(loc, key),
            count: counts[key] ?? 0,
            color: _taskGroupColors[key] ?? theme.colorScheme.primary,
            isLoading: loading,
          ),
        )
        .toList();

    final groupedSections = keys
        .where((key) => (grouped[key] ?? const []).isNotEmpty)
        .map((key) {
          final tasks = grouped[key]!.take(3).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _taskGroupLabel(loc, key),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...tasks.map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TaskListItem(task: task),
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        })
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cards.isNotEmpty)
          GridView.count(
            crossAxisCount: cards.length == 1 ? 1 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.4,
            children: cards,
          ),
        if (groupedSections.isNotEmpty) ...groupedSections,
        if (cards.isEmpty && groupedSections.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              loc.translate('tasks.noTasks'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTaskErrorState(
    ThemeData theme,
    String message,
    Future<void> Function() retry,
    String retryLabel,
  ) {
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: retry,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              child: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskStatCard(
    ThemeData theme, {
    required String title,
    required int count,
    required Color color,
    required bool isLoading,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.labelLarge),
            const Spacer(),
            isLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    '$count',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ],
        ),
      ),
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
              final currentUserId = context
                  .read<AuthProvider?>()
                  ?.currentUser
                  ?.id;
              if (project == null || currentUserId != project.creator.id) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: loc.translate('common.edit'),
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ChangeNotifierProvider<ProjectDetailProvider>.value(
                            value: provider,
                            child: EditProjectScreen(
                              project: project,
                              initialFiles: provider.files,
                            ),
                          ),
                    ),
                  );
                  if (result == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(loc.translate('messages.projectUpdated')),
                      ),
                    );
                    await context.read<ProjectDetailProvider>().load(
                      project.id,
                    );
                  }
                },
              );
            },
          ),
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
          final isOwner =
              context.read<AuthProvider?>()?.currentUser?.id ==
              project.creator.id;
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<ProjectDetailProvider>().load(project.id),
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                _header(context, project, provider, theme, loc, isOwner),
                const SizedBox(height: 16),
                _description(project, theme),
                const SizedBox(height: 24),
                _taskStats(project, theme, loc),
                const SizedBox(height: 24),
                FileGroupAttachmentsCard(
                  fileGroupId: project.fileGroupId,
                  title: loc.translate('attachments'),
                  groupName: 'Project Files',
                  allowEditing: isOwner,
                  initialFiles: provider.files,
                ),
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
    bool isOwner,
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
              if (isOwner) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: provider.isLoading
                          ? null
                          : () =>
                                _handleProjectComplete(project, provider, loc),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(loc.translate('projects.markComplete')),
                    ),
                    OutlinedButton.icon(
                      onPressed: provider.isLoading
                          ? null
                          : () => _handleProjectReject(project, provider, loc),
                      icon: const Icon(Icons.cancel_outlined),
                      label: Text(loc.translate('projects.markRejected')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
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

  Widget _projectTasksSection(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    ProjectDetailProvider provider,
  ) {
    final tasks = provider.tasks;
    final isInitialLoading = provider.isTaskListLoading;
    final isLoadingMore = provider.isTaskListLoadingMore;
    final hasMore = provider.hasMoreTasks;
    final taskError = provider.tasksError;
    final selectedGroup = provider.selectedTaskGroup;
    final counts = provider.taskCounts;
    final dashboardError = provider.taskDashboardError;

    final searchValue = provider.taskSearch ?? '';
    if (!_isSyncingSearchText && _taskSearchController.text != searchValue) {
      _isSyncingSearchText = true;
      _taskSearchController.value = TextEditingValue(
        text: searchValue,
        selection: TextSelection.collapsed(offset: searchValue.length),
      );
      _isSyncingSearchText = false;
    }

    final orderLookup = Map<String, int>.fromEntries(
      _taskGroupOrder.asMap().entries.map(
        (entry) => MapEntry(entry.value, entry.key),
      ),
    );

    final groupKeys =
        <String>{
          ..._taskGroupOrder,
          ...counts.keys,
          ...provider.groupedTaskLists.keys,
          if (selectedGroup != null) selectedGroup,
        }.toList()..sort((a, b) {
          final indexA = orderLookup[a] ?? _taskGroupOrder.length;
          final indexB = orderLookup[b] ?? _taskGroupOrder.length;
          if (indexA != indexB) return indexA.compareTo(indexB);
          return a.compareTo(b);
        });

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
              onPressed: provider.isTaskListLoading
                  ? null
                  : () async {
                      await provider.fetchTaskDashboard();
                      if (!mounted) return;
                      await provider.refreshProjectTasks();
                    },
              icon: provider.isTaskListLoading
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
        _buildCollapsibleSection(
          theme: theme,
          icon: Icons.dashboard_customize,
          title: loc.translate('tasks.dashboard.title'),
          expanded: _taskDashboardExpanded,
          onToggle: () {
            setState(() => _taskDashboardExpanded = !_taskDashboardExpanded);
          },
          child: _buildTaskDashboard(theme, provider, loc),
        ),
        _buildCollapsibleSection(
          theme: theme,
          icon: Icons.filter_alt,
          title: loc.translate('tasks.filters.title'),
          expanded: _taskFiltersExpanded,
          onToggle: () {
            setState(() => _taskFiltersExpanded = !_taskFiltersExpanded);
          },
          child: _buildTaskFilters(theme, loc, provider),
        ),
        if (dashboardError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              dashboardError,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        if (groupKeys.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: groupKeys.map((key) {
              final count = counts[key] ?? 0;
              final selected = key == selectedGroup;
              final label = _taskGroupLabel(loc, key);
              final chipLabel = count > 0 ? '$label ($count)' : label;
              return ChoiceChip(
                label: Text(chipLabel),
                selected: selected,
                onSelected: (value) {
                  if (!value) return;
                  provider.selectTaskGroup(key);
                },
              );
            }).toList(),
          ),
        const SizedBox(height: 12),
        if (isInitialLoading && tasks.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (taskError != null && tasks.isEmpty)
          _buildTaskErrorState(theme, taskError, () async {
            await provider.refreshProjectTasks();
          }, loc.translate('common.retry'))
        else if (tasks.isEmpty)
          Text(
            loc.translate('tasks.noTasks'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          Column(
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) =>
                    TaskListItem(task: tasks[index]),
              ),
              if (isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (taskError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    taskError,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                )
              else if (!hasMore)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    loc.translate('tasks.endOfList'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
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

  Future<bool> _confirmProjectAction({
    required String message,
    required String confirmLabel,
    required AppLocalizations loc,
    Color? confirmColor,
  }) async {
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.translate('common.warning')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(loc.translate('common.cancel')),
          ),
          FilledButton(
            style: confirmColor != null
                ? FilledButton.styleFrom(
                    backgroundColor: confirmColor,
                    foregroundColor: theme.colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleProjectComplete(
    Project project,
    ProjectDetailProvider provider,
    AppLocalizations loc,
  ) async {
    final confirm = await _confirmProjectAction(
      message: loc.translate('projects.markCompleteConfirm'),
      confirmLabel: loc.translate('projects.markComplete'),
      loc: loc,
    );
    if (!confirm || !mounted) return;

    final response = await provider.completeProject(project.id);
    if (!mounted) return;

    if (response.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('messages.projectCompleted'))),
      );
    } else {
      final message = response.error ?? loc.translate('errors.unknown');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _handleProjectReject(
    Project project,
    ProjectDetailProvider provider,
    AppLocalizations loc,
  ) async {
    final theme = Theme.of(context);
    final confirm = await _confirmProjectAction(
      message: loc.translate('projects.markRejectedConfirm'),
      confirmLabel: loc.translate('projects.markRejected'),
      loc: loc,
      confirmColor: theme.colorScheme.error,
    );
    if (!confirm || !mounted) return;

    final response = await provider.rejectProject(project.id);
    if (!mounted) return;

    if (response.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('messages.projectRejected'))),
      );
    } else {
      final message = response.error ?? loc.translate('errors.unknown');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
