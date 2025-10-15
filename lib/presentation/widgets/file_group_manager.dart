import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/file_models.dart';
import '../providers/file_group_provider.dart';
import '../../core/localization/app_localizations.dart';
import 'file_viewer_dialog.dart';

class FileGroupManager extends StatefulWidget {
  final int? fileGroupId;
  final String groupName;
  final bool allowEditing;
  final bool showHeader;
  final Function(int)? onFileGroupCreated;
  final Function(List<FileAttachment>)? onFilesUpdated;
  final List<FileAttachment>? initialFiles;

  const FileGroupManager({
    super.key,
    this.fileGroupId,
    required this.groupName,
    this.allowEditing = true,
    this.showHeader = true,
    this.onFileGroupCreated,
    this.onFilesUpdated,
    this.initialFiles,
  });

  @override
  State<FileGroupManager> createState() => _FileGroupManagerState();
}

class _FileGroupManagerState extends State<FileGroupManager> {
  final ImagePicker _picker = ImagePicker();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Defer initialization to after the first frame to avoid build-scope updates
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeFileGroup());
  }

  Future<void> _initializeFileGroup() async {
    if (!_isInitialized) {
      final provider = Provider.of<FileGroupProvider>(context, listen: false);

      if (widget.fileGroupId != null) {
        await provider.loadFileGroup(widget.fileGroupId!);
      } else if (widget.allowEditing) {
        // Create a new file group if none provided and editing is allowed
        final success = await provider.createFileGroup(widget.groupName);
        if (success &&
            provider.fileGroup != null &&
            widget.onFileGroupCreated != null) {
          // Notify parent after the current frame to avoid rebuild-in-build errors
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            widget.onFileGroupCreated!(provider.fileGroup!.id);
          });
        }
      }

      _isInitialized = true;

      // Notify parent about current files if needed, deferred to next frame
      if (widget.onFilesUpdated != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.onFilesUpdated!(provider.files);
        });
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile == null) return;

      final provider = Provider.of<FileGroupProvider>(context, listen: false);
      final fileName = pickedFile.name;
      final fileBytes = await pickedFile.readAsBytes();

      final success = await provider.addFile(fileName, fileBytes);

      if (success && widget.onFilesUpdated != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.onFilesUpdated!(provider.files);
        });
      }

      if (!success && mounted && provider.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(provider.error!)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _deleteFile(FileAttachment file) async {
    final provider = Provider.of<FileGroupProvider>(context, listen: false);
    final loc = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('deleteFileTitle')),
        content: Text(loc.translate('deleteFileConfirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.translate('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await provider.deleteFile(file);

      if (success && widget.onFilesUpdated != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.onFilesUpdated!(provider.files);
        });
      }

      if (!success && mounted && provider.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(provider.error!)));
      }
    }
  }

  Future<void> _viewFile(FileAttachment file) async {
    final provider = Provider.of<FileGroupProvider>(context, listen: false);
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

    final url = provider.getDownloadUrl(file);

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.translate('couldNotOpenFile'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Consumer<FileGroupProvider>(
      builder: (context, provider, _) {
        final files = _mergeFiles(provider.files);

        if (provider.isLoading && files.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showHeader) ...[
              Text(
                loc.translate('attachments'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
            ],

            // File list
            if (files.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  return _buildFileItem(
                    file,
                    canDelete: provider.files.contains(file),
                  );
                },
              )
            else
              Text(
                loc.translate('noAttachments'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),

            // Add file button
            if (widget.allowEditing) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: provider.isLoading ? null : _pickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(loc.translate('addFile')),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFileItem(FileAttachment file, {required bool canDelete}) {
    final loc = AppLocalizations.of(context);
    String fileTypeName = _getFileTypeName(file.name);
    IconData fileIcon = _getFileIcon(file.name);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(fileIcon, size: 36),
        title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(fileTypeName),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility),
              tooltip: loc.translate('viewFile'),
              onPressed: () => _viewFile(file),
            ),
            if (widget.allowEditing && canDelete)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: loc.translate('deleteFile'),
                onPressed: () => _deleteFile(file),
              ),
          ],
        ),
      ),
    );
  }

  String _getFileTypeName(String? fileName) {
    final loc = AppLocalizations.of(context);
    if (fileName == null) return loc.translate('unknownFile');

    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
        return loc.translate('image');
      case 'pdf':
        return 'PDF';
      case 'doc':
      case 'docx':
        return loc.translate('wordDocument');
      case 'xls':
      case 'xlsx':
        return loc.translate('excelDocument');
      case 'txt':
        return loc.translate('textFile');
      default:
        return loc.translate('file');
    }
  }

  IconData _getFileIcon(String? fileName) {
    if (fileName == null) return Icons.insert_drive_file;

    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
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
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  List<FileAttachment> _mergeFiles(List<FileAttachment> providerFiles) {
    final merged = <FileAttachment>[];
    final seen = <String>{};

    void addUnique(FileAttachment file) {
      final key = '${file.id ?? file.url}|${file.name}';
      if (seen.add(key)) {
        merged.add(file);
      }
    }

    for (final file in providerFiles) {
      addUnique(file);
    }

    final extras = widget.initialFiles ?? const <FileAttachment>[];
    for (final file in extras) {
      addUnique(file);
    }

    return merged;
  }
}
