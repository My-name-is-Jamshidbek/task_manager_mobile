import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/logger.dart';
import '../../../data/datasources/tasks_api_remote_datasource.dart';
import '../../providers/tasks_api_provider.dart';
import '../../providers/file_group_provider.dart';
import '../../widgets/file_group_manager.dart';

class CreateTaskScreen extends StatefulWidget {
  final int projectId;
  const CreateTaskScreen({super.key, required this.projectId});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _deadlineCtrl = TextEditingController();
  final _toWhomCtrl = TextEditingController();
  // File group integration
  int? _fileGroupId;
  int _taskType = 1; // 1-low, 2-medium, 3-high
  DateTime? _deadline;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _deadlineCtrl.dispose();
    _toWhomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('tasks.addTask'))),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Name
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: loc.translate('tasks.taskTitle'),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? loc.translate('validation.required')
                    : null,
              ),
              const SizedBox(height: 12),

              // Description
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

              // Task Type (priority)
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
                onChanged: (v) => setState(() => _taskType = v ?? 1),
              ),
              const SizedBox(height: 12),

              // Deadline ISO8601
              TextFormField(
                controller: _deadlineCtrl,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: loc.translate('tasks.dueDate'),
                  hintText: _deadline == null ? 'YYYY-MM-DD HH:MM' : null,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.event),
                ),
                onTap: _pickDeadline,
                validator: (v) {
                  if (_deadline == null) {
                    return loc.translate('validation.required');
                  }
                  if (_deadline!.isBefore(DateTime.now())) {
                    return loc.translate('validation.futureDateTime');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // To Whom (IDs)
              TextFormField(
                controller: _toWhomCtrl,
                decoration: InputDecoration(
                  labelText: loc.translate('tasks.toWhom'),
                  helperText: loc.translate('tasks.toWhomHelper'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Attachments widget
              ChangeNotifierProvider(
                create: (_) => FileGroupProvider(),
                child: FileGroupManager(
                  groupName: 'Task Files',
                  onFileGroupCreated: (id) => _fileGroupId = id,
                ),
              ),
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
                label: Text(loc.translate('common.create')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final ds = TasksApiRemoteDataSource();
      final toWhom = _parseIntList(_toWhomCtrl.text);
      final res = await ds.createTask(
        projectId: widget.projectId,
        taskTypeId: _taskType,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        deadlineIso:
            _deadline?.toUtc().toIso8601String() ?? _deadlineCtrl.text.trim(),
        toWhomUserIds: toWhom.isEmpty ? null : toWhom,
        parentTaskId: null,
        // Backend expects a list of file ids; here we pass the single created group id if present
        fileIds: _fileGroupId != null ? [_fileGroupId.toString()] : null,
      );

      if (!mounted) return;
      if (res.isSuccess) {
        // Optionally push new task into provider list
        final provider = context.read<TasksApiProvider>();
        // We could refresh tasks list from server or optimistically add if relevant
        await provider.refresh();
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        final msg = res.error ?? 'Failed to create task';
        Logger.warning('CreateTask error: $msg');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  List<int> _parseIntList(String input) {
    return input
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => int.tryParse(e))
        .whereType<int>()
        .toList();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline != null && _deadline!.isAfter(now)
          ? _deadline!
          : now.add(const Duration(minutes: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    if (!mounted) return;

    final timeOfDay = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _deadline ?? now.add(const Duration(minutes: 5)),
      ),
    );
    if (timeOfDay == null) return;

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
    if (selected.isBefore(now)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).translate('validation.futureDateTime'),
          ),
        ),
      );
      return;
    }

    setState(() {
      _deadline = selected;
      // Display local formatted string; actual API uses UTC ISO.
      _deadlineCtrl.text = _formatLocalDateTime(selected);
    });
  }

  String _formatLocalDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }
}
