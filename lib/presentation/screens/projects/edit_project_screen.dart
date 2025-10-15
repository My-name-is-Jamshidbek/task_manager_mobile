import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../data/models/file_models.dart' as file_models;
import '../../../data/models/project_models.dart';
import '../../providers/project_detail_provider.dart';
import '../../widgets/file_group_attachments_card.dart';

class EditProjectScreen extends StatefulWidget {
  final Project project;
  final List<file_models.FileAttachment> initialFiles;

  const EditProjectScreen({
    super.key,
    required this.project,
    this.initialFiles = const <file_models.FileAttachment>[],
  });

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  int? _fileGroupId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.project.name);
    _descCtrl = TextEditingController(text: widget.project.description ?? '');
    _fileGroupId = widget.project.fileGroupId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final provider = context.watch<ProjectDetailProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('projects.editTitle'))),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (provider.isLoading && !_submitting)
                const LinearProgressIndicator(minHeight: 2),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: loc.translate('projects.name'),
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
                  labelText: loc.translate('projects.description'),
                  border: const OutlineInputBorder(),
                ),
                minLines: 3,
                maxLines: 6,
              ),
              const SizedBox(height: 12),
              FileGroupAttachmentsCard(
                fileGroupId: _fileGroupId,
                title: loc.translate('attachments'),
                groupName: 'Project Files',
                allowEditing: true,
                initialFiles: widget.initialFiles,
                onFileGroupCreated: (id) => setState(() => _fileGroupId = id),
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
                label: Text(loc.translate('common.save')),
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

    final loc = AppLocalizations.of(context);
    final provider = context.read<ProjectDetailProvider>();
    final response = await provider.updateProject(
      projectId: widget.project.id,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      fileGroupId: _fileGroupId,
    );

    if (!mounted) return;

    if (response.isSuccess) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _submitting = false);
    final message = response.error ?? loc.translate('errors.unknown');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
