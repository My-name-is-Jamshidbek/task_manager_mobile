import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_localizations.dart';
import '../../providers/projects_provider.dart';
import '../../../data/models/project_models.dart';
import 'dart:async';
import '../projects/project_detail_screen.dart';
import '../projects/create_project_screen.dart';
import '../../providers/project_detail_provider.dart';
import '../../widgets/project_widgets.dart';
import '../../providers/dashboard_provider.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();
  // Filters: null => all, 'created_by_me', 'assigned_to_me'
  String? _currentFilter; // default to all
  int? _status = 1; // default status 1 = active; null means all
  static const int _pageSize = 10;
  // Global error modal is handled by ApiClient.
  bool _filtersExpanded = false;
  bool _statsExpanded = false;

  @override
  void initState() {
    super.initState();
    // Initial load: all projects
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ProjectsProvider>();
      p.perPage = _pageSize;
      p.status = _status; // align provider with UI default (active)
      // Skip refresh if prefetch already populated list
      if (p.projects.isEmpty) {
        p.refresh();
      }
      // Fetch project status stats
      context.read<DashboardProvider>().fetchProjectStatsByStatus();
    });
    // Rebuild to show/hide clear icon in search field
    _searchController.addListener(() => setState(() {}));
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
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final p = context.read<ProjectsProvider>();
      p.search = value.trim().isEmpty ? null : value.trim();
      p.refresh();
    });
  }

  void _onFilterChanged(String? filter) {
    setState(() => _currentFilter = filter);
    final p = context.read<ProjectsProvider>();
    p.filter = _currentFilter;
    p.refresh();
  }

  void _onScroll() {
    final p = context.read<ProjectsProvider>();
    // Infinite scroll load more
    if (!p.isLoading && p.hasMore) {
      final offset = _scrollController.position.pixels;
      if (offset >= _scrollController.position.maxScrollExtent - 200) {
        p.loadMore();
      }
    }
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
                          perPage: _pageSize,
                          filter: _currentFilter,
                          status: _status,
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
          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                context.read<ProjectsProvider>().refresh(),
                context.read<DashboardProvider>().refreshProjectStats(),
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
                // Collapsible Filters section
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
                // Collapsible Dashboard stats section
                SliverToBoxAdapter(
                  child: _buildCollapsibleSection(
                    context,
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    expanded: _statsExpanded,
                    onToggle: () =>
                        setState(() => _statsExpanded = !_statsExpanded),
                    child: _buildProjectStats(context, loc, theme),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: _buildProjectsSliverList(
                    context,
                    theme,
                    loc,
                    projects,
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
    ProjectsProvider provider,
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
              // 2) Refresh button
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
                          perPage: _pageSize,
                          filter: _currentFilter,
                          status: _status,
                          search: _searchController.text.trim().isEmpty
                              ? null
                              : _searchController.text.trim(),
                        );
                      },
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
                      value: _status,
                      isDense: true,
                      borderRadius: BorderRadius.circular(12),
                      onChanged: (value) => _onStatusChanged(value),
                      items:
                          <({int? val, String label})>[
                                (
                                  val: null,
                                  label: loc.translate('projects.filters.all'),
                                ),
                                (
                                  val: 1,
                                  label: loc.translate('projects.active'),
                                ),
                                (
                                  val: 2,
                                  label: loc.translate('projects.completed'),
                                ),
                                (
                                  val: 3,
                                  label: loc.translate(
                                    'projects.status.expired',
                                  ),
                                ),
                                (
                                  val: 4,
                                  label: loc.translate(
                                    'projects.status.rejected',
                                  ),
                                ),
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
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: Text(loc.translate('projects.createShort')),
                onPressed: () async {
                  final ctx = context;
                  await Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateProjectScreen(),
                    ),
                  );
                  if (!ctx.mounted) return;
                  // On return, refresh projects list to include the new one
                  ctx.read<ProjectsProvider>().refresh();
                },
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

  void _onStatusChanged(int? status) {
    setState(() => _status = status);
    final p = context.read<ProjectsProvider>();
    p.status = _status;
    p.refresh();
  }

  Widget _buildProjectStats(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    return Consumer<DashboardProvider>(
      builder: (context, dash, _) {
        if (dash.isProjectStatsLoading && dash.projectStats.isEmpty) {
          return _buildProjectStatsLoading(theme);
        }
        if (dash.projectStatsError != null && dash.projectStats.isEmpty) {
          return _buildProjectStatsError(
            context,
            theme,
            dash.projectStatsError!,
            () => dash.fetchProjectStatsByStatus(),
          );
        }

        // Map counts by status id/key (backend provides ids 1..4)
        int active = 0, completed = 0, expired = 0, rejected = 0;
        for (final s in dash.projectStats) {
          switch (s.statusId) {
            case 1:
              active = s.count;
              break;
            case 2:
              completed = s.count;
              break;
            case 3:
              expired = s.count;
              break;
            case 4:
              rejected = s.count;
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
                title: loc.translate('projects.active'),
                count: '$active',
                color: theme.colorScheme.primary,
                theme: theme,
              ),
              _buildStatCard(
                context,
                title: loc.translate('projects.completed'),
                count: '$completed',
                color: Colors.green,
                theme: theme,
              ),
              _buildStatCard(
                context,
                title: loc.translate('projects.status.expired'),
                count: '$expired',
                color: Colors.purple,
                theme: theme,
              ),
              _buildStatCard(
                context,
                title: loc.translate('projects.status.rejected'),
                count: '$rejected',
                color: Colors.red,
                theme: theme,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProjectStatsLoading(ThemeData theme) {
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

  Widget _buildProjectStatsError(
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

  SliverList _buildProjectsSliverList(
    BuildContext context,
    ThemeData theme,
    AppLocalizations loc,
    List<Project> projects,
  ) {
    if (projects.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.only(top: 48.0),
            child: Center(
              child: Text(
                loc.translate('projects.empty'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ]),
      );
    }

    final provider = context.watch<ProjectsProvider>();
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index >= projects.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final project = projects[index];
        return _buildProjectCard(context, project, theme, loc);
      }, childCount: projects.length + (provider.hasMore ? 1 : 0)),
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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => ChangeNotifierProvider(
                create: (_) => ProjectDetailProvider()..load(project.id),
                child: ProjectDetailScreen(projectId: project.id),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildAvatar(project.creator.avatarUrl, project.creator.name),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      project.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (project.status != null) const SizedBox(width: 4),
                  if (project.status != null)
                    ProjectStatusChip(project: project),
                  IconButton(
                    tooltip: loc.translate('common.more'),
                    icon: Icon(
                      Icons.more_vert,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      _showProjectActionsSheet(context, project, loc);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Friendly compact info pills
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  InfoPill(icon: Icons.person, label: project.creator.name),
                  InfoPill(
                    icon: Icons.calendar_today,
                    label: _formatDate(project.createdAt),
                  ),
                  if (project.files.isNotEmpty)
                    InfoPill(
                      icon: Icons.attach_file,
                      label: '${project.files.length}',
                      onTap: () => _showFilesSheet(context, project),
                    ),
                  InfoPill(
                    icon: Icons.checklist,
                    label: '${project.taskStats?.total ?? 0}',
                  ),
                ],
              ),
              if ((project.description ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  thickness: 0.75,
                  color: theme.colorScheme.outlineVariant,
                ),
                const SizedBox(height: 10),
                Text(
                  project.description ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
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

  Widget _buildAvatar(String? avatarUrl, String name) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 12,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: Colors.transparent,
      );
    }
    final initials = _initials(name);
    return CircleAvatar(
      radius: 12,
      child: Text(
        initials,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    final first = parts.first.substring(0, 1).toUpperCase();
    final last = parts.last.substring(0, 1).toUpperCase();
    return '$first$last';
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  // _buildInfoPill and _buildStatusChip removed in favor of shared widgets (InfoPill, ProjectStatusChip)

  void _showProjectActionsSheet(
    BuildContext context,
    Project project,
    AppLocalizations loc,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(loc.translate('common.edit')),
                onTap: () {
                  Navigator.of(ctx).pop();
                  // TODO: Navigate to edit screen
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: Text(loc.translate('common.share')),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _shareProject(project);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: Text(loc.translate('common.delete')),
                textColor: Theme.of(context).colorScheme.error,
                iconColor: Theme.of(context).colorScheme.error,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmDelete(context, project, loc);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showFilesSheet(BuildContext context, Project project) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        if (project.files.isEmpty) {
          return const SizedBox.shrink();
        }
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final f = project.files[index];
              return ListTile(
                leading: const Icon(Icons.insert_drive_file),
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
                onTap: () {
                  _openUrl(f.url);
                },
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: project.files.length,
          ),
        );
      },
    );
  }

  void _shareProject(Project project) {
    final text = '📁 ${project.name}\n${project.description ?? ''}'.trim();
    Share.share(text);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Project project,
    AppLocalizations loc,
  ) async {
    final theme = Theme.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.translate('common.delete')),
        content: Text(loc.translate('common.confirmDelete')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.translate('common.cancel')),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: theme.colorScheme.onErrorContainer,
              backgroundColor: theme.colorScheme.errorContainer,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.translate('common.delete')),
          ),
        ],
      ),
    );
    if (result == true) {
      // TODO: Call provider/remote to delete, then refresh list
      // context.read<ProjectsProvider>().deleteProject(project.id);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Could not launch, optionally show a snackbar
      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.translate('errors.cannotOpenLink'))),
        );
      }
    }
  }
}
