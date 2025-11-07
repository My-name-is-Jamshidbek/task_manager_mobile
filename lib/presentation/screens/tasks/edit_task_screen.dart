import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../data/datasources/tasks_api_remote_datasource.dart';
import '../../../data/models/api_task_models.dart';
import '../../../data/models/worker_models.dart';
import '../../providers/task_workers_provider.dart';
import '../../widgets/file_group_attachments_card.dart';
import '../../widgets/task_assignees_card.dart';
import 'select_task_workers_screen.dart';

class EditTaskScreen extends StatefulWidget {
  final ApiTask task;
  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _deadlineCtrl;
  late ApiTask _taskSnapshot;
  int _taskType = 1;
  DateTime? _deadline;
  int? _parentTaskId;
  int? _fileGroupId;
  bool _submitting = false;
  bool _reloading = false;
  List<WorkerUser> _assignedWorkers = [];
  bool _loadingWorkers = false;
  String? _workerError;

  @override
  void initState() {
    super.initState();
    _taskSnapshot = widget.task;
    _nameCtrl = TextEditingController(text: widget.task.name);
    _descCtrl = TextEditingController(text: widget.task.description ?? '');
    _deadline = widget.task.deadline?.toLocal();
    _deadlineCtrl = TextEditingController(
      text: _deadline != null ? _formatLocalDateTime(_deadline!) : '',
    );
    _taskType = widget.task.taskType?.id ?? 1;
    _parentTaskId = widget.task.parentTaskId;
    _fileGroupId = widget.task.fileGroupId;
    _loadAssignedWorkers();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _deadlineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final projectName = _taskSnapshot.project?.name ?? '—';

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('tasks.editTask'))),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_reloading) const LinearProgressIndicator(minHeight: 2),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.folder_open),
                  title: Text(projectName),
                  subtitle: Text(loc.translate('tasks.details')),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: loc.translate('tasks.taskTitle'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return loc.translate('validation.required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: InputDecoration(
                  labelText: loc.translate('tasks.taskDescription'),
                  border: const OutlineInputBorder(),
                ),
                minLines: 3,
                maxLines: 6,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _taskType,
                decoration: InputDecoration(
                  labelText: loc.translate('tasks.priority'),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 1,
                    child: Text(loc.translate('priority.low')),
                  ),
                  DropdownMenuItem(
                    value: 2,
                    child: Text(loc.translate('priority.medium')),
                  ),
                  DropdownMenuItem(
                    value: 3,
                    child: Text(loc.translate('priority.high')),
                  ),
                ],
                onChanged: (value) => setState(() => _taskType = value ?? 1),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deadlineCtrl,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: loc.translate('tasks.dueDate'),
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.event),
                ),
                onTap: _pickDeadline,
              ),
              if (_parentTaskId != null) ...[
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  tileColor: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: const Icon(Icons.account_tree_outlined),
                  title: Text(
                    loc.translate('tasks.parentTask'),
                    style: theme.textTheme.bodySmall,
                  ),
                  subtitle: Text('#${_parentTaskId!}'),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                loc.translate('attachments'),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              FileGroupAttachmentsCard(
                fileGroupId: _fileGroupId,
                title: loc.translate('attachments'),
                groupName: 'Task Files',
                allowEditing: true,
                onFileGroupCreated: (id) {
                  setState(() => _fileGroupId = id);
                },
              ),
              const SizedBox(height: 24),
              _buildWorkersSection(theme, loc),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _submitting ? null : _onSubmit,
                icon: _submitting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(loc.translate('tasks.save')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkersSection(ThemeData theme, AppLocalizations loc) {
    // Create a wrapper to handle the type mismatch and add edit button
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TaskAssigneesCard(
          workers: _assignedWorkers,
          isLoading: _loadingWorkers,
          error: _workerError,
          onRefresh: _loadAssignedWorkers,
          title: loc.translate('tasks.workers'),
          showHeader: true,
          maxWidth: 150,
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _openWorkerManager,
          icon: const Icon(Icons.group_outlined),
          label: Text(loc.translate('common.edit')),
        ),
      ],
    );
  }

  Future<void> _loadAssignedWorkers() async {
    setState(() {
      _loadingWorkers = true;
      _workerError = null;
    });

    final ds = TasksApiRemoteDataSource();
    final res = await ds.getTaskWorkers(_taskSnapshot.id);
    if (!mounted) return;
    final loc = AppLocalizations.of(context);

    setState(() {
      _loadingWorkers = false;
      if (res.isSuccess && res.data != null) {
        _assignedWorkers = res.data!;
        _workerError = null;
      } else {
        _workerError = res.error ?? loc.translate('errors.unknown');
      }
    });
  }

  Future<void> _openWorkerManager() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => TaskWorkersProvider(taskId: _taskSnapshot.id),
          child: SelectTaskWorkersScreen(taskId: _taskSnapshot.id),
        ),
      ),
    );
    if (!mounted) return;
    if (result == true) {
      await _reloadTaskSnapshot(showMessageOnSuccess: true);
    }
  }

  Future<void> _reloadTaskSnapshot({bool showMessageOnSuccess = false}) async {
    setState(() => _reloading = true);
    final ds = TasksApiRemoteDataSource();
    final response = await ds.getTaskById(_taskSnapshot.id);
    if (!mounted) return;
    if (response.isSuccess && response.data != null) {
      setState(() {
        _taskSnapshot = response.data!;
        _fileGroupId = _taskSnapshot.fileGroupId ?? _fileGroupId;
        _nameCtrl.text = _taskSnapshot.name;
        _descCtrl.text = _taskSnapshot.description ?? '';
        _taskType = _taskSnapshot.taskType?.id ?? _taskType;
        _parentTaskId = _taskSnapshot.parentTaskId;
        _deadline = _taskSnapshot.deadline?.toLocal();
        _deadlineCtrl.text = _deadline != null
            ? _formatLocalDateTime(_deadline!)
            : '';
      });
      if (showMessageOnSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('messages.taskUpdated'),
            ),
          ),
        );
      }
      await _loadAssignedWorkers();
    } else if (response.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.error!)));
    }
    if (mounted) {
      setState(() => _reloading = false);
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final loc = AppLocalizations.of(context);
    final ds = TasksApiRemoteDataSource();
    final response = await ds.updateTask(
      taskId: _taskSnapshot.id,
      projectId: _taskSnapshot.project?.id,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      taskTypeId: _taskType,
      deadlineIso: _deadline?.toUtc().toIso8601String(),
      parentTaskId: _parentTaskId,
      fileGroupId: _fileGroupId,
    );

    if (!mounted) return;

    if (response.isSuccess && response.data != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.translate('messages.taskUpdated'))),
      );
      Navigator.of(context).pop(true);
    } else {
      final message = response.error ?? loc.translate('errors.unknown');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }

    if (mounted) {
      setState(() => _submitting = false);
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final initialDate = _deadline != null && _deadline!.isAfter(now)
        ? _deadline!
        : now.add(const Duration(minutes: 5));
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null || !mounted) return;

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      _deadline = selected;
      _deadlineCtrl.text = _formatLocalDateTime(selected);
    });
  }

  String _formatLocalDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }
}
