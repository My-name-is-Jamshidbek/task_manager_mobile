import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/logger.dart';
import '../../../data/api/project_service.dart';
import '../../../data/models/project_models.dart';
import '../../providers/project_detail_provider.dart';
import 'project_detail_screen.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _fileIdsCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _fileIdsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('projects.createTitle'))),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: loc.translate('projects.name'),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
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
              TextFormField(
                controller: _fileIdsCtrl,
                decoration: InputDecoration(
                  labelText: loc.translate('projects.fileIds'),
                  helperText: loc.translate('projects.fileIdsHelper'),
                  border: const OutlineInputBorder(),
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
      final service = ProjectService();
      final fileIds = _parseFileIds(_fileIdsCtrl.text);
      final res = await service.createProject(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        fileIds: fileIds.isEmpty ? null : fileIds,
      );
      if (!mounted) return;
      if (res.isSuccess && res.data != null) {
        final Project project = res.data!;
        Logger.info('✅ Project created: ${project.id}');
        // Navigate to detail page with optimistic provider
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => ChangeNotifierProvider(
              create: (_) =>
                  ProjectDetailProvider(initial: project)..load(project.id),
              child: ProjectDetailScreen(projectId: project.id),
            ),
          ),
        );
      } else {
        final snack = SnackBar(
          content: Text(res.error ?? 'Failed to create project'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snack);
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

  List<String> _parseFileIds(String input) {
    return input
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
