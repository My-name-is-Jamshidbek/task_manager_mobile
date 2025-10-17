import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tasks_api_provider.dart';
import '../../../data/models/api_task_models.dart';
import '../../../data/models/task_action.dart';
import '../../widgets/task_list_item.dart';
import '../../providers/dashboard_provider.dart';
import '../../utils/task_action_helper.dart';
import '../../widgets/task_action_sheet.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 10;
  // Filters
  String? _filter; // created_by_me | assigned_to_me
  int? _statusId; // backend ids 0..5 as per API
  // Collapsible UI
  bool _filtersExpanded = false;
  bool _statsExpanded = false;

  @override
  void initState() {
    super.initState();
    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<TasksApiProvider>();
      p.perPage = _pageSize;
      if (p.tasks.isEmpty) {
        p.refresh();
      }
      // Prefetch task stats
      context.read<DashboardProvider>().fetchTaskStatsByStatus();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final provider = context.read<TasksApiProvider>();
      provider.name = value.trim().isEmpty ? null : value.trim();
      provider.refresh();
    });
  }

  void _onScroll() {
    final provider = context.read<TasksApiProvider>();
    final offset = _scrollController.position.pixels;
    if (!provider.isLoading && provider.hasMore) {
      if (offset >= _scrollController.position.maxScrollExtent - 200) {
        provider.loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final currentUserId = context.watch<AuthProvider?>()?.currentUser?.id;

    return SafeArea(
      child: Consumer<TasksApiProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.tasks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.tasks.isEmpty) {
            return _buildErrorState(context, loc, theme, provider.error!);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                context.read<TasksApiProvider>().refresh(),
                context.read<DashboardProvider>().refreshTaskStats(),
              ]);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  pinned: false,
                  automaticallyImplyLeading: false,
                  toolbarHeight: 0,
                  backgroundColor: theme.colorScheme.surface,
                  surfaceTintColor: theme.colorScheme.surface,
                  elevation: 1,
                  scrolledUnderElevation: 2,
                ),
                SliverToBoxAdapter(
                  child: _buildCollapsibleSection(
                    context,
                    icon: Icons.tune,
                    title: 'Filters',
                    expanded: _filtersExpanded,
                    onToggle: () =>
                        setState(() => _filtersExpanded = !_filtersExpanded),
                    child: _buildControls(context, theme, loc, provider),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildCollapsibleSection(
                    context,
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    expanded: _statsExpanded,
                    onToggle: () =>
                        setState(() => _statsExpanded = !_statsExpanded),
                    child: _buildTaskStats(context, loc, theme),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: _buildTasksSliverList(
                    context,
                    theme,
                    loc,
                    provider,
                    currentUserId,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    ThemeData theme,
    AppLocalizations loc,
    TasksApiProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: constraints.maxWidth >= 720 ? 420 : 320,
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: loc.translate('tasks.searchHint'),
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              // Refresh
              IconButton(
                tooltip: loc.translate('common.refresh'),
                icon: provider.isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : const Icon(Icons.refresh),
                onPressed: provider.isLoading
                    ? null
                    : () {
                        context.read<TasksApiProvider>().fetchTasks(
                          perPage: _pageSize,
                          filter: _filter,
                          status: _statusId,
                          name: _searchController.text.trim().isEmpty
                              ? null
                              : _searchController.text.trim(),
                        );
                      },
              ),
              // Filter dropdowns: created/assigned and status
              SizedBox(
                width: 220,
                child: InputDecorator(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _filter,
                      isDense: true,
                      borderRadius: BorderRadius.circular(12),
                      onChanged: (value) {
                        setState(() => _filter = value);
                        final p = context.read<TasksApiProvider>();
                        p.filter = value;
                        p.refresh();
                      },
                      items:
                          <({String? val, String label})>[
                                (
                                  val: null,
                                  label: loc.translate('projects.filters.all'),
                                ),
                                (
                                  val: 'created_by_me',
                                  label: loc.translate(
                                    'projects.filters.createdByMe',
                                  ),
                                ),
                                (
                                  val: 'assigned_to_me',
                                  label: loc.translate(
                                    'projects.filters.assignedToMe',
                                  ),
                                ),
                              ]
                              .map(
                                (e) => DropdownMenuItem<String?>(
                                  value: e.val,
                                  child: Text(e.label),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: InputDecorator(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _statusId,
                      isDense: true,
                      borderRadius: BorderRadius.circular(12),
                      onChanged: (value) {
                        setState(() => _statusId = value);
                        final p = context.read<TasksApiProvider>();
                        p.status = value;
                        p.refresh();
                      },
                      items:
                          <({int? val, String label})>[
                                (
                                  val: null,
                                  label: loc.translate('projects.filters.all'),
                                ),
                                (val: 0, label: 'Accept'),
                                (val: 1, label: 'In progress'),
                                (val: 2, label: 'Completed'),
                                (val: 3, label: 'Checked finished'),
                                (val: 4, label: 'Rejected'),
                                (val: 5, label: 'Rejected confirmed'),
                              ]
                              .map(
                                (e) => DropdownMenuItem<int?>(
                                  value: e.val,
                                  child: Text(e.label),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCollapsibleSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool expanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: expanded ? 'Hide' : 'Show',
                onPressed: onToggle,
                icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              ),
            ],
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Card(
              elevation: 1,
              margin: const EdgeInsets.only(top: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(padding: const EdgeInsets.all(8.0), child: child),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskStats(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    return Consumer<DashboardProvider>(
      builder: (context, dash, _) {
        if (dash.isTaskStatsLoading && dash.taskStats.isEmpty) {
          return _buildTaskStatsLoading(theme);
        }
        if (dash.taskStatsError != null && dash.taskStats.isEmpty) {
          return _buildTaskStatsError(
            context,
            theme,
            dash.taskStatsError!,
            () => dash.fetchTaskStatsByStatus(),
          );
        }

        // Map counts by status id 0..5
        int accept = 0,
            inProgress = 0,
            completed = 0,
            checkedFinished = 0,
            rejected = 0,
            rejectedConfirmed = 0;

        for (final s in dash.taskStats) {
          switch (s.statusId) {
            case 0:
              accept = s.count;
              break;
            case 1:
              inProgress = s.count;
              break;
            case 2:
              completed = s.count;
              break;
            case 3:
              checkedFinished = s.count;
              break;
            case 4:
              rejected = s.count;
              break;
            case 5:
              rejectedConfirmed = s.count;
              break;
            default:
              break;
          }
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.1,
            children: [
              _buildStatCard(
                context,
                title: 'Accept',
                count: '$accept',
                color: theme.colorScheme.primary,
                theme: theme,
              ),
              _buildStatCard(
                context,
                title: 'In progress',
                count: '$inProgress',
                color: Colors.blue,
                theme: theme,
              ),
              _buildStatCard(
                context,
                title: 'Completed',
                count: '$completed',
                color: Colors.green,
                theme: theme,
              ),
              _buildStatCard(
                context,
                title: 'Checked finished',
                count: '$checkedFinished',
                color: Colors.purple,
                theme: theme,
              ),
              _buildStatCard(
                context,
                title: 'Rejected',
                count: '$rejected',
                color: Colors.red,
                theme: theme,
              ),
              _buildStatCard(
                context,
                title: 'Rejected confirmed',
                count: '$rejectedConfirmed',
                color: Colors.orange,
                theme: theme,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskStatsLoading(ThemeData theme) {
    Widget skeletonCard() => Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 36,
              width: 60,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 14,
              width: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.1,
        children: [
          skeletonCard(),
          skeletonCard(),
          skeletonCard(),
          skeletonCard(),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String count,
    required Color color,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                count,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
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

  Widget _buildTaskStatsError(
    BuildContext context,
    ThemeData theme,
    String message,
    VoidCallback onRetry,
  ) {
    final loc = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('common.error'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(loc.translate('common.retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverList _buildTasksSliverList(
    BuildContext context,
    ThemeData theme,
    AppLocalizations loc,
    TasksApiProvider provider,
    int? currentUserId,
  ) {
    if (provider.tasks.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.only(top: 48.0),
            child: Center(
              child: Text(
                loc.translate('tasks.noTasks'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ]),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index >= provider.tasks.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildTaskCard(
          context,
          provider.tasks[index],
          theme,
          loc,
          provider,
          currentUserId,
        );
      }, childCount: provider.tasks.length + (provider.hasMore ? 1 : 0)),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    String message,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              loc.translate('common.error'),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => context.read<TasksApiProvider>().fetchTasks(),
              icon: const Icon(Icons.refresh),
              label: Text(loc.translate('common.retry')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    ApiTask task,
    ThemeData theme,
    AppLocalizations loc,
    TasksApiProvider provider,
    int? currentUserId,
  ) {
    final isCompleted = task.status?.id == 2;
    final projectName = task.project?.name ?? '';
    final statusLabel = task.status?.label ?? '';
    final actions = TaskActionHelper.deriveActions(task, currentUserId);
    final trailing = _buildTaskTrailing(
      context,
      theme,
      loc,
      task,
      provider,
      currentUserId,
      statusLabel,
      actions,
    );

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: TaskListItem(
        task: task,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        leading: const Icon(Icons.checklist),
        trailing: trailing,
        showStatus: false,
        showProjectName: true,
        projectNameOverride: projectName,
        isCompleted: isCompleted,
        deadlineLabel: loc.translate('tasks.due'),
      ),
    );
  }

  Widget? _buildTaskTrailing(
    BuildContext context,
    ThemeData theme,
    AppLocalizations loc,
    ApiTask task,
    TasksApiProvider provider,
    int? currentUserId,
    String statusLabel,
    List<TaskActionKind> actions,
  ) {
    final statusChip = statusLabel.isNotEmpty
        ? _buildStatusChip(statusLabel, theme)
        : null;
    if (actions.isEmpty) {
      return statusChip;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (statusChip != null) statusChip,
        if (statusChip != null) const SizedBox(width: 4),
        IconButton(
          tooltip: loc.translate('tasks.actions.title'),
          icon: const Icon(Icons.more_horiz),
          onPressed: () => _openTaskActions(
            context,
            loc,
            task,
            actions,
            provider,
            currentUserId,
          ),
        ),
      ],
    );
  }

  Future<void> _openTaskActions(
    BuildContext context,
    AppLocalizations loc,
    ApiTask task,
    List<TaskActionKind> actions,
    TasksApiProvider provider,
    int? currentUserId,
  ) async {
    final result = await TaskActionSheet.show(
      context,
      task: task,
      currentUserId: currentUserId,
      presetActions: actions,
    );
    if (!mounted || result == null) return;

    if (result.updatedTask != null) {
      provider.replaceTask(result.updatedTask!);
    }

    await provider.refresh();

    if (!mounted) return;

    context.read<DashboardProvider>().refreshTaskStats();

    final message = TaskActionHelper.buildSuccessMessage(loc, result.action);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildStatusChip(String label, ThemeData theme) {
    final color = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
