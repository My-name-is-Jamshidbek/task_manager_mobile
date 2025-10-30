import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../data/models/api_task_models.dart';
import '../../../data/models/task_action.dart';
import '../../providers/task_detail_provider.dart';
import '../../widgets/file_group_attachments_card.dart';

class TaskRejectionScreen extends StatefulWidget {
  final ApiTask task;
  final TaskDetailProvider taskProvider;

  const TaskRejectionScreen({
    super.key,
    required this.task,
    required this.taskProvider,
  });

  @override
  State<TaskRejectionScreen> createState() => _TaskRejectionScreenState();
}

class _TaskRejectionScreenState extends State<TaskRejectionScreen> {
  late final TextEditingController _reasonController;
  String? _reasonError;
  int? _selectedFileGroupId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _handleReasonChanged(String value) {
    // Clear error when user starts typing
    if (_reasonError != null) {
      setState(() => _reasonError = null);
    }
  }

  Future<void> _handleSubmit() async {
    final loc = AppLocalizations.of(context);
    final reason = _reasonController.text.trim();

    // Validate reason is required
    if (reason.isEmpty) {
      setState(() {
        _reasonError = loc.translate('tasks.rejection.reasonRequired');
      });
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Perform the rejection action
      final success = await widget.taskProvider.performAction(
        TaskActionKind.reject,
        reason: reason,
        fileGroupId: _selectedFileGroupId,
      );

      if (!mounted) return;

      if (success) {
        // Show success message
        final successMessage = loc.translateWithParams(
          'tasks.actions.successMessage',
          {'action': loc.translate('tasks.actions.reject')},
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));

        // Pop back to task detail
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        });
      } else {
        // Show error message
        final error =
            widget.taskProvider.actionError ??
            loc.translate('tasks.actions.genericError');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('tasks.actions.reject')),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Task summary
                  _buildTaskSummary(theme, loc),
                  const SizedBox(height: 24),

                  // Reason section
                  Text(
                    loc.translate('tasks.rejection.reasonLabel'),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.translate('tasks.rejection.reasonHelper'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Reason field
                  TextField(
                    controller: _reasonController,
                    enabled: !_isSubmitting,
                    maxLines: 5,
                    minLines: 3,
                    decoration: InputDecoration(
                      labelText: loc.translate('tasks.rejection.reasonLabel'),
                      hintText: loc.translate('tasks.rejection.reasonHint'),
                      errorText: _reasonError,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: _handleReasonChanged,
                  ),
                  const SizedBox(height: 24),

                  // File group attachments card (existing widget)
                  FileGroupAttachmentsCard(
                    fileGroupId: _selectedFileGroupId,
                    title: loc.translate('tasks.rejection.filesLabel'),
                    groupName: 'Task Rejection',
                    allowEditing: true,
                    autoCreateWhenMissing: false,
                    onFileGroupCreated: (fileGroupId) {
                      setState(() => _selectedFileGroupId = fileGroupId);
                    },
                  ),
                ],
              ),
            ),
          ),
          // Action buttons at bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(loc.translate('common.cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onError,
                              ),
                            )
                          : Text(loc.translate('tasks.actions.reject')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskSummary(ThemeData theme, AppLocalizations loc) {
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Rejection',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.task.name,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            if (widget.task.description != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.task.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
