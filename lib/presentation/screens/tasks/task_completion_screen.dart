import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../data/models/api_task_models.dart';
import '../../../data/models/task_action.dart';
import '../../providers/task_detail_provider.dart';
import '../../widgets/file_group_attachments_card.dart';

class TaskCompletionScreen extends StatefulWidget {
  final ApiTask task;
  final TaskDetailProvider taskProvider;

  const TaskCompletionScreen({
    super.key,
    required this.task,
    required this.taskProvider,
  });

  @override
  State<TaskCompletionScreen> createState() => _TaskCompletionScreenState();
}

class _TaskCompletionScreenState extends State<TaskCompletionScreen> {
  late final TextEditingController _descriptionController;
  String? _descriptionError;
  int? _selectedFileGroupId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleDescriptionChanged(String value) {
    // Clear error when user starts typing
    if (_descriptionError != null) {
      setState(() => _descriptionError = null);
    }
  }

  Future<void> _handleSubmit() async {
    final loc = AppLocalizations.of(context);
    final description = _descriptionController.text.trim();

    // Validate description is required
    if (description.isEmpty) {
      setState(() {
        _descriptionError = loc.translate(
          'tasks.completion.descriptionRequired',
        );
      });
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Perform the completion action
      final success = await widget.taskProvider.performAction(
        TaskActionKind.complete,
        reason: description,
        fileGroupId: _selectedFileGroupId,
      );

      if (!mounted) return;

      if (success) {
        // Show success message
        final successMessage = loc.translateWithParams(
          'tasks.actions.successMessage',
          {'action': loc.translate('tasks.actions.complete')},
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
        title: Text(loc.translate('tasks.actions.complete')),
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

                  // Description section
                  Text(
                    loc.translate('tasks.completion.descriptionLabel'),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.translate('tasks.completion.descriptionHelper'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description field
                  TextField(
                    controller: _descriptionController,
                    enabled: !_isSubmitting,
                    maxLines: 5,
                    minLines: 3,
                    decoration: InputDecoration(
                      labelText: loc.translate(
                        'tasks.completion.descriptionLabel',
                      ),
                      hintText: loc.translate(
                        'tasks.completion.descriptionHint',
                      ),
                      errorText: _descriptionError,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: _handleDescriptionChanged,
                  ),
                  const SizedBox(height: 24),

                  // File group attachments card (existing widget)
                  FileGroupAttachmentsCard(
                    fileGroupId: _selectedFileGroupId,
                    title: loc.translate('tasks.completion.filesLabel'),
                    groupName: 'Task Completion',
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
                      child: _isSubmitting
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : Text(loc.translate('tasks.actions.proceed')),
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Task Completion', style: theme.textTheme.labelSmall),
            const SizedBox(height: 8),
            Text(
              widget.task.name,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.task.description != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.task.description!,
                style: theme.textTheme.bodySmall,
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
