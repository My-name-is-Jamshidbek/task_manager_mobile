import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/theme_service.dart';
import '../../../core/constants/theme_constants.dart';
import '../../../data/models/task_worker_models.dart';
import '../../providers/tasks_api_provider.dart';
import '../../widgets/file_viewer_dialog.dart';

class TaskWorkerDetailScreen extends StatefulWidget {
  final int taskId;
  final int workerId;

  const TaskWorkerDetailScreen({
    super.key,
    required this.taskId,
    required this.workerId,
  });

  @override
  State<TaskWorkerDetailScreen> createState() => _TaskWorkerDetailScreenState();
}

class _TaskWorkerDetailScreenState extends State<TaskWorkerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<TaskWorkerDetail?> _detailFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDetail();
  }

  void _loadDetail() {
    _detailFuture = _fetchTaskWorkerDetail();
  }

  Future<TaskWorkerDetail?> _fetchTaskWorkerDetail() async {
    final provider = context.read<TasksApiProvider>();
    final response = await provider.getTaskWorkerDetail(
      taskId: widget.taskId,
      workerId: widget.workerId,
    );
    return response.data;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('tasks.workers')),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Material(
            color: Theme.of(context).appBarTheme.backgroundColor,
            child: TabBar(
              controller: _tabController,
              indicatorColor: themeService.primaryColor,
              labelColor: themeService.primaryColor,
              unselectedLabelColor: Theme.of(
                context,
              ).textTheme.bodySmall?.color,
              isScrollable: true,
              tabs: [
                _buildTab(
                  icon: Icons.check_circle_outline,
                  label: loc.translate('tasks.actions.approve'),
                ),
                _buildTab(
                  icon: Icons.loop_rounded,
                  label: loc.translate('tasks.actions.rework'),
                ),
                _buildTab(
                  icon: Icons.cancel_outlined,
                  label: loc.translate('tasks.actions.reject'),
                ),
              ],
            ),
          ),
        ),
      ),
      body: FutureBuilder<TaskWorkerDetail?>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(context);
          }

          if (snapshot.hasError) {
            return _buildErrorState(context, snapshot.error);
          }

          final detail = snapshot.data;
          if (detail == null) {
            return _buildEmptyState(context, loc);
          }

          return Column(
            children: [
              // Worker profile header (non-scrollable)
              _buildWorkerProfile(detail, context),
              // Tab content (scrollable)
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSubmissionList(detail.confirms, 'confirms', context),
                    _buildSubmissionList(detail.reworks, 'reworks', context),
                    _buildSubmissionList(detail.rejects, 'rejects', context),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTab({required IconData icon, required String label}) {
    return Tab(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppThemeConstants.spaceMD,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(label, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Provider.of<ThemeService>(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).translate('common.loading'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, dynamic error) {
    final loc = AppLocalizations.of(context);
    final themeService = Provider.of<ThemeService>(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppThemeConstants.spaceLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppThemeConstants.spaceLG),
              decoration: BoxDecoration(
                color: AppThemeConstants.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppThemeConstants.radiusLG),
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: AppThemeConstants.danger,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              loc.translate('common.error'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeService.primaryColor,
              ),
              onPressed: () => setState(_loadDetail),
              child: Text(loc.translate('common.retry')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations loc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppThemeConstants.spaceLG),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              loc.translate('workers.noneAssigned'),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerProfile(TaskWorkerDetail detail, BuildContext context) {
    final user = detail.user;
    final loc = AppLocalizations.of(context);
    final themeService = Provider.of<ThemeService>(context);
    final statusColor = _getStatusColor(detail.statusColor);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(AppThemeConstants.spaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar + Worker Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with enhanced styling
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: themeService.primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                  color: themeService.primaryColor.withOpacity(0.1),
                  image: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(user.avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                    ? Center(
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: themeService.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppThemeConstants.spaceLG),
              // Worker info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppThemeConstants.spaceMD),
                    // Status badge with improved styling
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppThemeConstants.spaceMD,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        border: Border.all(
                          color: statusColor.withOpacity(0.5),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppThemeConstants.radiusLG,
                        ),
                      ),
                      child: Text(
                        detail.statusLabel ?? loc.translate('common.unknown'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppThemeConstants.spaceMD),
                    // Phone
                    if (user.phone != null && user.phone!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: AppThemeConstants.spaceSM,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              user.phone!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          // Department info
          if (user.departments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppThemeConstants.spaceLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.translate('tasks.meta'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.departments
                        .map(
                          (dept) => Chip(
                            label: Text(dept.name),
                            backgroundColor: themeService.primaryColor
                                .withOpacity(0.1),
                            side: BorderSide(
                              color: themeService.primaryColor.withOpacity(0.3),
                              width: 1,
                            ),
                            labelStyle: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: themeService.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          // Timestamps
          if (detail.assignedAt != null || detail.updatedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: AppThemeConstants.spaceLG),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (detail.assignedAt != null)
                    _buildTimestampInfo(
                      loc.translate('tasks.title'),
                      detail.assignedAt!,
                      context,
                    ),
                  if (detail.updatedAt != null)
                    _buildTimestampInfo(
                      loc.translate('common.update'),
                      detail.updatedAt!,
                      context,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimestampInfo(
    String label,
    DateTime dateTime,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatDateTime(dateTime),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSubmissionList(
    List<TaskWorkerSubmission> submissions,
    String type,
    BuildContext context,
  ) {
    final loc = AppLocalizations.of(context);

    if (submissions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppThemeConstants.spaceLG),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                loc.translate('workers.noneAssigned'),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppThemeConstants.spaceMD),
      itemCount: submissions.length,
      itemBuilder: (context, index) =>
          _buildSubmissionItem(submissions[index], context, index + 1),
    );
  }

  Widget _buildSubmissionItem(
    TaskWorkerSubmission submission,
    BuildContext context,
    int index,
  ) {
    final loc = AppLocalizations.of(context);
    final themeService = Provider.of<ThemeService>(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppThemeConstants.spaceMD),
      elevation: AppThemeConstants.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppThemeConstants.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with index
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: themeService.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      AppThemeConstants.radiusLG,
                    ),
                  ),
                  child: Text(
                    '#${index.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: themeService.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppThemeConstants.spaceMD),
            // Description
            if (submission.description != null &&
                submission.description!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.translate('tasks.completion.descriptionLabel'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(AppThemeConstants.spaceMD),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(
                        AppThemeConstants.radiusMD,
                      ),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      submission.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: AppThemeConstants.spaceMD),
                ],
              ),
            // Files section
            if (submission.files.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${loc.translate('files.download')} (${submission.files.length})',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...submission.files.asMap().entries.map(
                    (entry) =>
                        _buildFileItem(entry.value, context, entry.key + 1),
                  ),
                  const SizedBox(height: AppThemeConstants.spaceMD),
                ],
              ),
            // Timestamps footer
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppThemeConstants.spaceSM,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (submission.createdAt != null)
                    Text(
                      '${loc.translate('common.create')}: ${_formatDateTime(submission.createdAt!)}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  if (submission.updatedAt != null)
                    Text(
                      '${loc.translate('common.update')}: ${_formatDateTime(submission.updatedAt!)}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileItem(dynamic file, BuildContext context, int index) {
    final themeService = Provider.of<ThemeService>(context);

    // Handle both FileAttachment and generic map
    final fileName = (file is Map)
        ? file['name'] ?? 'Unknown file'
        : (file.name ?? 'Unknown file');
    final fileUrl = (file is Map) ? file['url'] : (file.url);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppThemeConstants.spaceSM),
      child: GestureDetector(
        onTap: fileUrl != null && fileUrl.isNotEmpty
            ? () => _openFile(fileUrl, fileName, context)
            : null,
        child: Container(
          padding: const EdgeInsets.all(AppThemeConstants.spaceMD),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor, width: 1),
            borderRadius: BorderRadius.circular(AppThemeConstants.radiusMD),
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeService.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    AppThemeConstants.radiusMD,
                  ),
                ),
                child: Icon(
                  _getFileIcon(fileName),
                  color: themeService.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppThemeConstants.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#${index.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              if (fileUrl != null && fileUrl.isNotEmpty)
                Icon(
                  Icons.open_in_new_rounded,
                  color: themeService.primaryColor,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFile(String url, String fileName, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          FileViewerDialog(fileId: 0, fileName: fileName, fileUrl: url),
    );
  }

  Color _getStatusColor(String? statusColor) {
    switch (statusColor?.toLowerCase()) {
      case 'success':
        return AppThemeConstants.success;
      case 'warning':
        return AppThemeConstants.warning;
      case 'error':
        return AppThemeConstants.danger;
      case 'secondary':
        return AppThemeConstants.secondary;
      default:
        return AppThemeConstants.info;
    }
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image_rounded;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file_rounded;
      case 'txt':
        return Icons.text_fields_rounded;
      default:
        return Icons.attachment_rounded;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dayString;
    if (targetDay == today) {
      dayString = 'Today';
    } else if (targetDay == yesterday) {
      dayString = 'Yesterday';
    } else {
      dayString =
          '${dateTime.day.toString().padLeft(2, '0')}/'
          '${dateTime.month.toString().padLeft(2, '0')}/'
          '${dateTime.year}';
    }

    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
    return '$dayString at $time';
  }
}
