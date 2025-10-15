import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/datasources/tasks_api_remote_datasource.dart';
import '../../widgets/file_group_attachments_card.dart';

class CreateTaskWithFilesScreen extends StatefulWidget {
  final int? projectId;

  const CreateTaskWithFilesScreen({super.key, this.projectId});

  @override
  State<CreateTaskWithFilesScreen> createState() =>
      _CreateTaskWithFilesScreenState();
}

class _CreateTaskWithFilesScreenState extends State<CreateTaskWithFilesScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _deadline;
  int? _fileGroupId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline(BuildContext context) async {
    final initialDate = _deadline ?? DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (selectedDate == null) return;

    if (!mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (selectedTime == null) return;

    setState(() {
      _deadline = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  void _handleFileGroupCreated(int fileGroupId) {
    setState(() {
      _fileGroupId = fileGroupId;
    });
  }

  Future<void> _createTask() async {
    if (_formKey.currentState?.validate() != true) return;
    if (widget.projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            ).translate('validation.projectRequired'),
          ),
        ),
      );
      return;
    }
    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            ).translate('validation.deadlineRequired'),
          ),
        ),
      );
      return;
    }

    final remote = TasksApiRemoteDataSource();

    final result = await remote.createTask(
      projectId: widget.projectId!,
      taskTypeId: 1, // Assuming default task type
      name: _titleController.text,
      description: _descriptionController.text,
      deadlineIso: _deadline!.toIso8601String(),
      fileGroupId: _fileGroupId,
    );

    if (result.isSuccess && mounted) {
      Navigator.of(context).pop(true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.error ??
                AppLocalizations.of(context).translate('errors.unknown'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('tasks.create'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: loc.translate('tasks.title'),
                ),
                validator: (value) => value?.isEmpty ?? true
                    ? loc.translate('validation.required')
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: loc.translate('tasks.description'),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(loc.translate('tasks.deadline')),
                subtitle: Text(
                  _deadline != null
                      ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year} ${_deadline!.hour}:${_deadline!.minute.toString().padLeft(2, '0')}'
                      : loc.translate('tasks.noDeadline'),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDeadline(context),
              ),
              const SizedBox(height: 24),

              FileGroupAttachmentsCard(
                fileGroupId: _fileGroupId,
                title: loc.translate('attachments'),
                groupName: 'Task Files',
                allowEditing: true,
                onFileGroupCreated: _handleFileGroupCreated,
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createTask,
                  child: Text(loc.translate('common.create')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
