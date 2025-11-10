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
  String? _filter;
  int? _statusId;
  bool _filtersExpanded = true; // Keep filters expanded by default
  bool _statsExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<TasksApiProvider>();
      p.perPage = _pageSize;
      if (p.tasks.isEmpty) {
        p.refresh();
      }
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
            child: Column(
              children: [
                _buildControls(context, theme, loc, provider),
                _buildTaskStats(context, loc, theme),
                Expanded(
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    controller: _scrollController,
                    slivers: [
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
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
              const SizedBox(width: 8),
              IconButton(
                tooltip: loc.translate('common.refresh'),
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed: provider.isLoading ? null : () => provider.refresh(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  context,
                  value: _filter,
                  onChanged: (value) {
                    setState(() => _filter = value);
                    final p = context.read<TasksApiProvider>();
                    p.filter = value;
                    p.refresh();
                  },
                  items: [
                    (val: null, label: loc.translate('projects.filters.all')),
                    (val: 'created_by_me', label: loc.translate('projects.filters.createdByMe')),
                    (val: 'assigned_to_me', label: loc.translate('projects.filters.assignedToMe')),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Consumer<DashboardProvider>(
                builder: (context, dashProvider, _) {
                   return Expanded(
                     child: _buildFilterDropdown<int?>(
                       context,
                       value: _statusId,
                       onChanged: (value) {
                         setState(() => _statusId = value);
                         final p = context.read<TasksApiProvider>();
                         p.status = value;
                         p.refresh();
                       },
                       items: [
                         (val: null, label: loc.translate('tasks.filters.statusAll')),
                         ...dashProvider.taskStats.map((s) => (val: s.statusId, label: s.label)),
                       ],
                     ),
                   );
                },
              ),
            ],
          )
        ],
      ),
    );
  }
  
  Widget _buildFilterDropdown<T>(
    BuildContext context,
    {
      required T value,
      required ValueChanged<T?> onChanged,
      required List<({T val, String label})> items,
    }
  ) {
    return InputDecorator(
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          onChanged: onChanged,
          items: items.map((e) => DropdownMenuItem<T>(
            value: e.val,
            child: Text(e.label, overflow: TextOverflow.ellipsis),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildTaskStats(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
  ) {
     // This can be simplified or removed if not needed
     return const SizedBox.shrink(); 
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
