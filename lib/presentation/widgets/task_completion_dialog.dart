import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import 'file_group_manager.dart';

/// Result returned from TaskCompletionDialog
class TaskCompletionResult {
  final String description;
  final int? fileGroupId;

  TaskCompletionResult({required this.description, this.fileGroupId});
}

/// Dialog for task completion with description and optional file group selection
class TaskCompletionDialog extends StatefulWidget {
  final int? initialFileGroupId;
  final String? initialDescription;

  const TaskCompletionDialog({
    super.key,
    this.initialFileGroupId,
    this.initialDescription,
  });

  @override
  State<TaskCompletionDialog> createState() => _TaskCompletionDialogState();

  /// Show the completion dialog and return the result
  static Future<TaskCompletionResult?> show(
    BuildContext context, {
    int? initialFileGroupId,
    String? initialDescription,
  }) {
    return showDialog<TaskCompletionResult>(
      context: context,
      builder: (context) => TaskCompletionDialog(
        initialFileGroupId: initialFileGroupId,
        initialDescription: initialDescription,
      ),
    );
  }
}

class _TaskCompletionDialogState extends State<TaskCompletionDialog> {
  late final TextEditingController _descriptionController;
  String? _descriptionError;
  int? _selectedFileGroupId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.initialDescription ?? '',
    );
    _selectedFileGroupId = widget.initialFileGroupId;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final description = _descriptionController.text.trim();
    final loc = AppLocalizations.of(context);

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

    // Create the result and close dialog
    if (mounted) {
      Navigator.of(context).pop(
        TaskCompletionResult(
          description: description,
          fileGroupId: _selectedFileGroupId,
        ),
      );
    }
  }

  void _handleDescriptionChanged(String value) {
    // Clear error when user starts typing
    if (_descriptionError != null) {
      setState(() => _descriptionError = null);
    }
  }

  void _handleFileGroupSelected(int fileGroupId) {
    setState(() => _selectedFileGroupId = fileGroupId);
  }

  void _handleFileGroupCleared() {
    setState(() => _selectedFileGroupId = null);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(loc.translate('tasks.actions.complete')),
      scrollable: true,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description field (required)
            TextField(
              controller: _descriptionController,
              enabled: !_isSubmitting,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: loc.translate('tasks.completion.descriptionLabel'),
                hintText: loc.translate('tasks.completion.descriptionHint'),
                helperText: loc.translate('tasks.completion.descriptionHelper'),
                errorText: _descriptionError,
                border: const OutlineInputBorder(),
              ),
              onChanged: _handleDescriptionChanged,
            ),
            const SizedBox(height: 20),

            // File group section (optional)
            Text(
              loc.translate('tasks.completion.filesLabel'),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              loc.translate('tasks.completion.filesHint'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            // File group selection widget
            _buildFileGroupSelector(loc, theme),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(loc.translate('common.cancel')),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : Text(loc.translate('tasks.actions.proceed')),
        ),
      ],
    );
  }

  /// Build file group selector widget
  Widget _buildFileGroupSelector(AppLocalizations loc, ThemeData theme) {
    if (_selectedFileGroupId == null) {
      return OutlinedButton.icon(
        onPressed: _isSubmitting ? null : _showFileGroupManager,
        icon: const Icon(Icons.attach_file),
        label: Text(loc.translate('tasks.completion.addFiles')),
      );
    }

    return _buildSelectedFileGroupCard(loc, theme);
  }

  /// Build card showing selected file group
  Widget _buildSelectedFileGroupCard(AppLocalizations loc, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    loc.translate('tasks.completion.filesSelected'),
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'File Group #$_selectedFileGroupId',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _isSubmitting
                  ? null
                  : () {
                      _handleFileGroupCleared();
                    },
              icon: const Icon(Icons.clear),
              tooltip: loc.translate('common.remove'),
            ),
            IconButton(
              onPressed: _isSubmitting ? null : _showFileGroupManager,
              icon: const Icon(Icons.edit),
              tooltip: loc.translate('common.edit'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show file group manager to select or create file group
  Future<void> _showFileGroupManager() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) =>
          FileGroupManagerDialog(initialFileGroupId: _selectedFileGroupId),
    );

    if (result != null && mounted) {
      _handleFileGroupSelected(result);
    }
  }
}

/// Standalone file group manager dialog for selection
class FileGroupManagerDialog extends StatefulWidget {
  final int? initialFileGroupId;

  const FileGroupManagerDialog({super.key, this.initialFileGroupId});

  @override
  State<FileGroupManagerDialog> createState() => _FileGroupManagerDialogState();
}

class _FileGroupManagerDialogState extends State<FileGroupManagerDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: FileGroupManager(
        fileGroupId: widget.initialFileGroupId,
        groupName: 'Task Completion',
        allowEditing: true,
        showHeader: true,
        onFileGroupCreated: (fileGroupId) {
          Navigator.of(context).pop(fileGroupId);
        },
      ),
    );
  }
}
