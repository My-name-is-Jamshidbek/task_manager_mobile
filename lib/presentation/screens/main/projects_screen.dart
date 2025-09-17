import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../providers/projects_provider.dart';
import '../../../data/models/project_models.dart';
import 'dart:async';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  // Filters: null => all, 'created_by_me', 'assigned_to_me'
  String? _currentFilter; // default to all
  static const int _pageSizeAll = 1000; // large page size to approximate "all"
  // Global error modal is handled by ApiClient.

  @override
  void initState() {
    super.initState();
    // Initial load: all projects
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectsProvider>().fetchProjects(
        perPage: _pageSizeAll,
        filter: _currentFilter,
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
      );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      context.read<ProjectsProvider>().fetchProjects(
        perPage: _pageSizeAll,
        filter: _currentFilter,
        search: value.trim().isEmpty ? null : value.trim(),
      );
    });
  }

  void _onFilterChanged(String? filter) {
    setState(() => _currentFilter = filter);
    context.read<ProjectsProvider>().fetchProjects(
      perPage: _pageSizeAll,
      filter: _currentFilter,
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Consumer<ProjectsProvider>(
        builder: (context, provider, _) {
          // Show error dialog once per error occurrence when list is empty
          // Global error modal is handled by ApiClient; just render content here.

          if (provider.isLoading && provider.projects.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.projects.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 36,
                    ),
                    const SizedBox(height: 12),
                    Text(provider.error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        context.read<ProjectsProvider>().fetchProjects(
                          perPage: _pageSizeAll,
                          filter: _currentFilter,
                          search: _searchController.text.trim().isEmpty
                              ? null
                              : _searchController.text.trim(),
                        );
                      },
                      child: Text(loc.translate('common.retry')),
                    ),
                  ],
                ),
              ),
            );
          }

          final projects = provider.projects;
          // No local error dialog state; rendering continues below.
          return Column(
            children: [
              _buildControls(context, theme, loc, provider),
              _buildProjectStats(context, loc, theme, projects),
              Expanded(
                child: _buildProjectsList(context, theme, loc, projects),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    ThemeData theme,
    AppLocalizations loc,
    ProjectsProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: loc.translate('projects.searchHint'),
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
          const SizedBox(width: 12),
          // Filter dropdown: All / Created / Assigned
          DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _currentFilter,
              isDense: true,
              borderRadius: BorderRadius.circular(12),
              onChanged: (value) => _onFilterChanged(value),
              items:
                  <({String? val, String label})>[
                        (
                          val: null,
                          label: loc.translate('projects.filters.all'),
                        ),
                        (
                          val: 'created_by_me',
                          label: loc.translate('projects.filters.createdByMe'),
                        ),
                        (
                          val: 'assigned_to_me',
                          label: loc.translate('projects.filters.assignedToMe'),
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
          const SizedBox(width: 8),
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
                    context.read<ProjectsProvider>().fetchProjects(
                      perPage: _pageSizeAll,
                      filter: _currentFilter,
                      search: _searchController.text.trim().isEmpty
                          ? null
                          : _searchController.text.trim(),
                    );
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildProjectStats(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    List<Project> projects,
  ) {
    // Simple derived stats
    final total = projects.length;
    final completed = projects
        .where(
          (p) =>
              (p.taskStats?.byStatus.any((s) => s.status == 'completed') ??
              false),
        )
        .length;
    final onHold = projects
        .where(
          (p) =>
              (p.taskStats?.byStatus.any((s) => s.status == 'on_hold') ??
              false),
        )
        .length;
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              title: loc.translate('projects.active'),
              count: '$total',
              color: theme.colorScheme.primary,
              theme: theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              title: loc.translate('projects.completed'),
              count: '$completed',
              color: Colors.green,
              theme: theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              title: loc.translate('projects.onHold'),
              count: '$onHold',
              color: Colors.orange,
              theme: theme,
            ),
          ),
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
        child: Column(
          children: [
            Text(
              count,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsList(
    BuildContext context,
    ThemeData theme,
    AppLocalizations loc,
    List<Project> projects,
  ) {
    if (projects.isEmpty) {
      return Center(
        child: Text(
          loc.translate('projects.empty'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return _buildProjectCard(context, project, theme, loc);
      },
    );
  }

  Widget _buildProjectCard(
    BuildContext context,
    Project project,
    ThemeData theme,
    AppLocalizations loc,
  ) {
    // Derive progress from taskStats if available
    final total = project.taskStats?.total ?? 0;
    final completedCount =
        project.taskStats?.byStatus
            .firstWhere(
              (s) => s.status == 'completed',
              orElse: () =>
                  const ByStatus(status: 'none', label: null, count: 0),
            )
            .count ??
        0;
    final progress = total > 0 ? (completedCount / total).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to project detail
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      project.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.more_vert,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                project.description ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.translate('projects.progress'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$completedCount/$total',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        loc.translate('projects.tasks'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
