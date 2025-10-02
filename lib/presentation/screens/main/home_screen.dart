import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../projects/create_project_screen.dart';
import '../tasks/create_task_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/projects_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(context, loc, theme),
            const SizedBox(height: 20),
            _buildQuickActions(context, loc, theme),
            const SizedBox(height: 20),
            _buildRecentItems(context, loc, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.waving_hand,
              size: 32,
              color: theme.colorScheme.onPrimary,
            ),
            const SizedBox(height: 8),
            Text(
              loc.translate('home.welcomeBack'),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              loc.translate('home.todayMotivation'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.translate('home.quickActions'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.add_task,
                title: loc.translate('tasks.addTask'),
                color: theme.colorScheme.primary,
                onTap: () => _pickProjectAndCreateTask(context, loc),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.create_new_folder,
                title: loc.translate('home.newProject'),
                color: theme.colorScheme.secondary,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateProjectScreen(),
                    ),
                  );
                  if (!context.mounted) return;
                  await context.read<ProjectsProvider>().refresh();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentItems(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.translate('home.recentActivity'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildRecentItem(
          context,
          icon: Icons.task_alt,
          title: loc.translate('home.sampleActivities.completePresentation'),
          subtitle: '2 ${loc.translate('home.hoursAgo')}',
          color: Colors.green,
          theme: theme,
        ),
        _buildRecentItem(
          context,
          icon: Icons.folder,
          title: loc.translate('home.sampleActivities.mobileAppDev'),
          subtitle: loc.translate('home.projectUpdated'),
          color: Colors.blue,
          theme: theme,
        ),
        _buildRecentItem(
          context,
          icon: Icons.rate_review,
          title: loc.translate('home.sampleActivities.reviewFeedback'),
          subtitle: loc.translate('home.yesterday'),
          color: Colors.orange,
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildRecentItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: () {
          // TODO: Navigate to item detail
        },
      ),
    );
  }

  Future<void> _pickProjectAndCreateTask(
    BuildContext context,
    AppLocalizations loc,
  ) async {
    final projectsProvider = context.read<ProjectsProvider>();
    if (projectsProvider.projects.isEmpty && !projectsProvider.isLoading) {
      await projectsProvider.refresh();
    }
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final projects = context.watch<ProjectsProvider>().projects;
        final loading = context.watch<ProjectsProvider>().isLoading;
        if (loading && projects.isEmpty) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (projects.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(loc.translate('projects.empty')),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CreateProjectScreen(),
                      ),
                    );
                    if (!context.mounted) return;
                    await context.read<ProjectsProvider>().refresh();
                  },
                  icon: const Icon(Icons.create_new_folder),
                  label: Text(loc.translate('projects.createShort')),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        }
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: projects.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = projects[i];
              return ListTile(
                leading: const Icon(Icons.folder),
                title: Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CreateTaskScreen(projectId: p.id),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
