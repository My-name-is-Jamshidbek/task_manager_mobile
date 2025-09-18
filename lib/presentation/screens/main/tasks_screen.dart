import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../providers/tasks_api_provider.dart';
import '../../../data/models/api_task_models.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();
  bool _headersVisible = true;
  double _lastOffset = 0.0;

  // Filters
  String? _filter; // created_by_me | assigned_to_me
  int?
  _statusId; // 1=pending, 2=in progress, 3=completed, 4=cancelled (assumption)

  // Assumed mapping for backend status ids
  static const Map<String, int> _statusIdMap = {
    'pending': 1,
    'inProgress': 2,
    'completed': 3,
    'cancelled': 4,
  };

  @override
  void initState() {
    super.initState();
    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TasksApiProvider>();
      provider.perPage = 10;
      if (provider.tasks.isEmpty) {
        provider.refresh();
      }
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
    final delta = offset - _lastOffset;

    // Hide headers when scrolling down, show when scrolling up or near top
    if (delta > 8 && offset > 80 && _headersVisible) {
      setState(() => _headersVisible = false);
    } else if ((delta < -8 && !_headersVisible) ||
        (offset < 40 && !_headersVisible)) {
      setState(() => _headersVisible = true);
    }

    if (!provider.isLoading && provider.hasMore) {
      if (offset >= _scrollController.position.maxScrollExtent - 200) {
        provider.loadMore();
      }
    }
    _lastOffset = offset;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        children: [
          AnimatedCrossFade(
            firstChild: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: loc.translate('tasks.searchHint'),
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                _buildFilterRow(context, loc, theme),
              ],
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _headersVisible
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
          Expanded(
            child: Consumer<TasksApiProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.tasks.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.error != null && provider.tasks.isEmpty) {
                  return _buildErrorState(context, loc, theme, provider.error!);
                }
                if (provider.tasks.isEmpty) {
                  return _buildEmptyState(context, loc, theme);
                }
                return RefreshIndicator(
                  onRefresh: () async => provider.refresh(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount:
                        provider.tasks.length + (provider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= provider.tasks.length) {
                        // Bottom loader for next page
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
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Created/Assigned filter
            _buildChoiceChip(
              context,
              label: loc.translate('projects.filters.all'),
              selected: _filter == null,
              onSelected: (_) {
                setState(() => _filter = null);
                final p = context.read<TasksApiProvider>();
                p.filter = null;
                p.refresh();
              },
            ),
            const SizedBox(width: 8),
            _buildChoiceChip(
              context,
              label: loc.translate('projects.filters.createdByMe'),
              selected: _filter == 'created_by_me',
              onSelected: (_) {
                setState(() => _filter = 'created_by_me');
                final p = context.read<TasksApiProvider>();
                p.filter = 'created_by_me';
                p.refresh();
              },
            ),
            const SizedBox(width: 8),
            _buildChoiceChip(
              context,
              label: loc.translate('projects.filters.assignedToMe'),
              selected: _filter == 'assigned_to_me',
              onSelected: (_) {
                setState(() => _filter = 'assigned_to_me');
                final p = context.read<TasksApiProvider>();
                p.filter = 'assigned_to_me';
                p.refresh();
              },
            ),
            const SizedBox(width: 16),
            // Status filter chips
            _buildChoiceChip(
              context,
              label: loc.translate('projects.status.all'),
              selected: _statusId == null,
              onSelected: (_) {
                setState(() => _statusId = null);
                final p = context.read<TasksApiProvider>();
                p.status = null;
                p.refresh();
              },
            ),
            const SizedBox(width: 8),
            _buildChoiceChip(
              context,
              label: loc.translate('status.pending'),
              selected: _statusId == _statusIdMap['pending'],
              onSelected: (_) {
                setState(() => _statusId = _statusIdMap['pending']);
                final p = context.read<TasksApiProvider>();
                p.status = _statusId;
                p.refresh();
              },
            ),
            const SizedBox(width: 8),
            _buildChoiceChip(
              context,
              label: loc.translate('status.inProgress'),
              selected: _statusId == _statusIdMap['inProgress'],
              onSelected: (_) {
                setState(() => _statusId = _statusIdMap['inProgress']);
                final p = context.read<TasksApiProvider>();
                p.status = _statusId;
                p.refresh();
              },
            ),
            const SizedBox(width: 8),
            _buildChoiceChip(
              context,
              label: loc.translate('status.completed'),
              selected: _statusId == _statusIdMap['completed'],
              onSelected: (_) {
                setState(() => _statusId = _statusIdMap['completed']);
                final p = context.read<TasksApiProvider>();
                p.status = _statusId;
                p.refresh();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) => onSelected(v),
      selectedColor: theme.colorScheme.primary.withOpacity(0.2),
      checkmarkColor: theme.colorScheme.primary,
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              loc.translate('tasks.noTasks'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              loc.translate('tasks.createFirstTask'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
  ) {
    final isCompleted = task.status?.id == _statusIdMap['completed'];
    final deadline = task.deadline;
    final projectName = task.project?.name ?? '';
    final statusLabel = task.status?.label ?? '';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to task detail
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: isCompleted,
                    onChanged: (value) {
                      // TODO: Toggle task completion via API
                    },
                  ),
                  Expanded(
                    child: Text(
                      task.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: isCompleted
                            ? theme.colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                  ),
                  if (statusLabel.isNotEmpty)
                    _buildStatusChip(statusLabel, theme),
                ],
              ),
              if (task.description != null &&
                  task.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    deadline != null
                        ? '${loc.translate('tasks.due')}: ${_formatDate(deadline)}'
                        : loc.translate('tasks.due'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.folder_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    projectName.isEmpty ? '-' : projectName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    // Simple date formatting; can be replaced with intl if available
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
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
