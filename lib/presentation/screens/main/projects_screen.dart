import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        children: [
          _buildProjectStats(context, loc, theme),
          Expanded(
            child: _buildProjectsList(context, theme, loc),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectStats(BuildContext context, AppLocalizations loc, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              title: loc.translate('projects.active'),
              count: '5',
              color: theme.colorScheme.primary,
              theme: theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              title: loc.translate('projects.completed'),
              count: '12',
              color: Colors.green,
              theme: theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              title: loc.translate('projects.onHold'),
              count: '2',
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

  Widget _buildProjectsList(BuildContext context, ThemeData theme, AppLocalizations loc) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 8, // Mock data
      itemBuilder: (context, index) {
        return _buildProjectCard(context, index, theme, loc);
      },
    );
  }

  Widget _buildProjectCard(BuildContext context, int index, ThemeData theme, AppLocalizations loc) {
    final projects = [
      {
        'name': loc.translate('projects.sampleProjects.taskManager.name'),
        'description': loc.translate('projects.sampleProjects.taskManager.description'),
        'progress': 0.75,
        'tasks': 24,
        'completed': 18,
        'color': Colors.blue,
      },
      {
        'name': loc.translate('projects.sampleProjects.ecommerce.name'),
        'description': loc.translate('projects.sampleProjects.ecommerce.description'),
        'progress': 0.45,
        'tasks': 32,
        'completed': 14,
        'color': Colors.green,
      },
      {
        'name': loc.translate('projects.sampleProjects.dashboard.name'),
        'description': loc.translate('projects.sampleProjects.dashboard.description'),
        'progress': 0.90,
        'tasks': 16,
        'completed': 14,
        'color': Colors.purple,
      },
    ];

    final project = projects[index % projects.length];
    
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
                      color: project['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      project['name'] as String,
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
                project['description'] as String,
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
                          value: project['progress'] as double,
                          backgroundColor: theme.colorScheme.surfaceVariant,
                          color: project['color'] as Color,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${((project['progress'] as double) * 100).toInt()}%',
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
                        '${project['completed']}/${project['tasks']}',
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
