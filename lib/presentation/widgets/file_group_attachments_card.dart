import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/localization/app_localizations.dart';
import '../../data/models/file_models.dart';
import '../providers/file_group_provider.dart';
import 'file_group_manager.dart';
import 'file_viewer_dialog.dart';

class FileGroupAttachmentsCard extends StatefulWidget {
  final int? fileGroupId;
  final String? title;
  final String groupName;
  final bool allowEditing;
  final bool autoCreateWhenMissing;
  final ValueChanged<int>? onFileGroupCreated;
  final ValueChanged<List<FileAttachment>>? onFilesChanged;
  final List<FileAttachment>? initialFiles;

  const FileGroupAttachmentsCard({
    super.key,
    this.fileGroupId,
    this.title,
    this.groupName = 'Files',
    this.allowEditing = true,
    this.autoCreateWhenMissing = false,
    this.onFileGroupCreated,
    this.onFilesChanged,
    this.initialFiles,
  });

  @override
  State<FileGroupAttachmentsCard> createState() =>
      _FileGroupAttachmentsCardState();
}

class _FileGroupAttachmentsCardState extends State<FileGroupAttachmentsCard> {
  late final FileGroupProvider _provider;
  int? _currentGroupId;
  bool _creatingGroup = false;
  String _lastEmittedSignature = '';

  @override
  void initState() {
    super.initState();
    _provider = FileGroupProvider();
    _currentGroupId = widget.fileGroupId;
    _provider.addListener(_handleProviderUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_bootstrap(initial: true));
    });
  }

  @override
  void didUpdateWidget(covariant FileGroupAttachmentsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fileGroupId != oldWidget.fileGroupId) {
      _currentGroupId = widget.fileGroupId;
      unawaited(_bootstrap(force: true));
    } else if (widget.initialFiles != oldWidget.initialFiles) {
      _maybeEmitFiles(widget.initialFiles ?? const <FileAttachment>[]);
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_handleProviderUpdate);
    _provider.dispose();
    super.dispose();
  }

  Future<void> _bootstrap({bool initial = false, bool force = false}) async {
    if (!mounted) return;
    final id = _currentGroupId;
    if (id != null) {
      await _provider.loadFileGroup(id);
      return;
    }
    if ((initial && widget.autoCreateWhenMissing) || force) {
      await _ensureGroupExists(userRequested: !initial);
    } else {
      if (mounted) {
        _maybeEmitFiles(widget.initialFiles ?? const <FileAttachment>[]);
      }
    }
  }

  void _handleProviderUpdate() {
    if (!mounted) return;
    final group = _provider.fileGroup;
    if (group != null && group.id != _currentGroupId) {
      _currentGroupId = group.id;
      widget.onFileGroupCreated?.call(group.id);
    }
    _maybeEmitFiles(_provider.files);
  }

  void _maybeEmitFiles(List<FileAttachment> files) {
    if (widget.onFilesChanged == null) return;
    final signature = files
        .map((f) => '${f.id ?? 'tmp'}|${f.name}|${f.url}')
        .join(';');
    if (signature == _lastEmittedSignature) return;
    _lastEmittedSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onFilesChanged!(List<FileAttachment>.from(files));
    });
  }

  Future<bool> _ensureGroupExists({bool userRequested = false}) async {
    if (_currentGroupId != null) return true;
    if (!widget.allowEditing) return false;
    if (_creatingGroup) return _currentGroupId != null;

    setState(() => _creatingGroup = true);
    final created = await _provider.createFileGroup(widget.groupName);
    if (!mounted) return false;
    setState(() => _creatingGroup = false);

    if (created && _provider.fileGroup != null) {
      _currentGroupId = _provider.fileGroup!.id;
      widget.onFileGroupCreated?.call(_currentGroupId!);
      return true;
    }

    if (userRequested) {
      final loc = AppLocalizations.of(context);
      final message = _provider.error ?? loc.translate('errors.unknown');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
    return false;
  }

  Future<void> _reload() async {
    final id = _currentGroupId;
    if (id == null) return;
    await _provider.loadFileGroup(id);
  }

  Future<void> _openEditor() async {
    if (!widget.allowEditing) return;
    final ready = await _ensureGroupExists(userRequested: true);
    if (!ready || !mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final loc = AppLocalizations.of(context);
        final theme = Theme.of(context);
        return ChangeNotifierProvider<FileGroupProvider>.value(
          value: _provider,
          child: FractionallySizedBox(
            heightFactor: 0.85,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${loc.translate('common.edit')} ${loc.translate('attachments')}',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: FileGroupManager(
                        fileGroupId: _currentGroupId,
                        groupName: widget.groupName,
                        allowEditing: widget.allowEditing,
                        showHeader: false,
                        initialFiles: widget.initialFiles,
                        onFileGroupCreated: (id) {
                          _currentGroupId = id;
                          widget.onFileGroupCreated?.call(id);
                          if (mounted) {
                            _provider.loadFileGroup(id);
                          }
                        },
                        onFilesUpdated: (files) =>
                            _maybeEmitFiles(List<FileAttachment>.from(files)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    // Check mounted status before accessing provider after modal closes
    if (mounted && _currentGroupId != null) {
      await _provider.loadFileGroup(_currentGroupId!);
    }
  }

  Future<void> _viewFile(FileAttachment file) async {
    final loc = AppLocalizations.of(context);
    if (file.id != null) {
      await showFileViewer(
        context,
        fileId: file.id!,
        fileName: file.name,
        fileUrl: file.url.isNotEmpty ? file.url : null,
      );
      return;
    }

    final url = _provider.getDownloadUrl(file);
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.translate('couldNotOpenFile'))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  IconData _fileIconForName(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'txt':
      case 'md':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ChangeNotifierProvider<FileGroupProvider>.value(
      value: _provider,
      child: Consumer<FileGroupProvider>(
        builder: (context, provider, _) {
          final isLoading = provider.isLoading || _creatingGroup;
          final error = provider.error;
          final files = provider.files;
          final displayFiles = files.isNotEmpty
              ? files
              : (widget.initialFiles ?? const <FileAttachment>[]);
          final hasFiles = displayFiles.isNotEmpty;
          final title = widget.title ?? loc.translate('attachments');
          final canRefresh = _currentGroupId != null && !isLoading;

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      if (hasFiles) ...[
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            displayFiles.length.toString(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      IconButton(
                        tooltip: loc.translate('common.refresh'),
                        icon: isLoading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary,
                                ),
                              )
                            : const Icon(Icons.refresh),
                        onPressed: canRefresh ? _reload : null,
                      ),
                      if (widget.allowEditing)
                        IconButton(
                          tooltip: loc.translate('common.edit'),
                          icon: const Icon(Icons.edit),
                          onPressed: isLoading ? null : _openEditor,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (isLoading && !hasFiles)
                    const Center(child: CircularProgressIndicator())
                  else if (error != null && !hasFiles)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          error,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: canRefresh ? _reload : null,
                          icon: const Icon(Icons.refresh),
                          label: Text(loc.translate('common.retry')),
                        ),
                      ],
                    )
                  else if (!hasFiles)
                    Row(
                      children: [
                        const Icon(Icons.attach_file),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            loc.translate('noAttachments'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayFiles.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final file = displayFiles[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(_fileIconForName(file.name)),
                          title: Text(
                            file.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            file.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            tooltip: loc.translate('viewFile'),
                            icon: const Icon(Icons.visibility),
                            onPressed: () => _viewFile(file),
                          ),
                          onTap: () => _viewFile(file),
                        );
                      },
                    ),
                  if (error != null && hasFiles)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        error,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
