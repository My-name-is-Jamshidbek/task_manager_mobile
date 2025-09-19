import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../providers/project_detail_provider.dart';
import '../../../data/models/project_models.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/project_widgets.dart';

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<ProjectDetailProvider>().load(widget.projectId),
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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(context, project, theme, loc),
                const SizedBox(height: 16),
                _description(project, theme),
                const SizedBox(height: 24),
                _taskStats(project, theme, loc),
                const SizedBox(height: 24),
                _filesSection(project, theme, loc),
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
    ThemeData theme,
    AppLocalizations loc,
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
                  if (project.files.isNotEmpty)
                    InfoPill(
                      icon: Icons.attach_file,
                      label: '${project.files.length}',
                    ),
                  InfoPill(
                    icon: Icons.checklist,
                    label: '${project.taskStats?.total ?? 0}',
                  ),
                  if (project.status != null)
                    ProjectStatusChip(project: project),
                ],
              ),
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

  Widget _filesSection(Project project, ThemeData theme, AppLocalizations loc) {
    if (project.files.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.translate('common.more'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: project.files.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final f = project.files[index];
            return ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                f.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _openUrl(f.url),
            );
          },
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

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
