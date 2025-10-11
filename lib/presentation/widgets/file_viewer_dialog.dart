import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import '../../core/api/api_client.dart';
import '../../core/localization/app_localizations.dart';

class FileViewerDialog extends StatefulWidget {
  final int fileId;
  final String fileName;
  final String? fileUrl;

  const FileViewerDialog({
    super.key,
    required this.fileId,
    required this.fileName,
    this.fileUrl,
  });

  @override
  State<FileViewerDialog> createState() => _FileViewerDialogState();
}

class _FileViewerDialogState extends State<FileViewerDialog> {
  bool _isLoading = true;
  String? _error;
  Uint8List? _fileBytes;
  String? _contentType;
  String? _localFilePath;
  PdfControllerPinch? _pdfController;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  Future<void> _loadFile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiClient().downloadBinary(
        '/files/${widget.fileId}/download',
      );

      if (!mounted) return;

      if (!response.isSuccess || response.data == null) {
        setState(() {
          _error = response.error;
          _isLoading = false;
        });
        return;
      }

      final bytes = response.data!.bytes;
      final tempDir = await getTemporaryDirectory();
      final safeFileName = _sanitizeFileName(
        _resolveFileName(response.data!.fileName),
      );
      final filePath = p.join(tempDir.path, safeFileName);
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      PdfControllerPinch? pdfController;
      final extension = _getFileExtension(widget.fileName);
      if (_isPdfFile(extension)) {
        pdfController = PdfControllerPinch(
          document: PdfDocument.openData(bytes),
        );
      }

      if (!mounted) return;

      setState(() {
        _fileBytes = bytes;
        _contentType = response.data!.contentType;
        _localFilePath = file.path;
        _pdfController?.dispose();
        _pdfController = pdfController;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _resolveFileName(String? serverFileName) {
    if (serverFileName != null && serverFileName.trim().isNotEmpty) {
      return serverFileName.trim();
    }
    if (widget.fileName.trim().isNotEmpty) {
      return widget.fileName.trim();
    }
    return 'file_${widget.fileId}';
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  String _getFileExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.isNotEmpty ? parts.last.toLowerCase() : '';
  }

  bool _isImageFile(String extension) {
    return [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
    ].contains(extension.toLowerCase());
  }

  bool _isPdfFile(String extension) {
    return extension.toLowerCase() == 'pdf';
  }

  bool _isDocumentFile(String extension) {
    return ['doc', 'docx', 'txt', 'rtf'].contains(extension.toLowerCase());
  }

  bool _isExcelFile(String extension) {
    return ['xls', 'xlsx', 'csv'].contains(extension.toLowerCase());
  }

  bool _isTextFile(String extension) {
    return [
      'txt',
      'csv',
      'json',
      'md',
      'log',
    ].contains(extension.toLowerCase());
  }

  IconData _getFileIcon(String extension) {
    extension = extension.toLowerCase();
    if (_isImageFile(extension)) return Icons.image;
    if (_isPdfFile(extension)) return Icons.picture_as_pdf;
    if (_isDocumentFile(extension)) return Icons.description;
    if (_isExcelFile(extension)) return Icons.table_chart;
    if (['zip', 'rar', '7z'].contains(extension)) return Icons.archive;
    if (['mp4', 'avi', 'mov', 'mkv'].contains(extension))
      return Icons.video_file;
    if (['mp3', 'wav', 'aac', 'flac'].contains(extension))
      return Icons.audio_file;
    return Icons.insert_drive_file;
  }

  Color _getFileColor(String extension) {
    extension = extension.toLowerCase();
    if (_isImageFile(extension)) return Colors.blue;
    if (_isPdfFile(extension)) return Colors.red;
    if (_isDocumentFile(extension)) return Colors.indigo;
    if (_isExcelFile(extension)) return Colors.green;
    return Colors.grey;
  }

  String _formatFileSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    final formatted = size >= 10 || unitIndex == 0
        ? size.toStringAsFixed(0)
        : size.toStringAsFixed(1);
    return '$formatted ${units[unitIndex]}';
  }

  Widget _buildFilePreview() {
    final extension = _getFileExtension(widget.fileName);

    if (_fileBytes == null) {
      if (_error != null) {
        return _buildErrorPlaceholder();
      }
      return _buildUnsupportedPreview();
    }

    if (_isImageFile(extension)) {
      return _buildImagePreview();
    }

    if (_isPdfFile(extension) && _pdfController != null) {
      return _buildPdfPreview();
    }

    if (_isTextFile(extension)) {
      return _buildTextPreview();
    }

    return _buildUnsupportedPreview();
  }

  Widget _buildImagePreview() {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InteractiveViewer(
          child: Image.memory(_fileBytes!, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildPdfPreview() {
    return Container(
      height: 420,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: PdfViewPinch(controller: _pdfController!),
      ),
    );
  }

  Widget _buildTextPreview() {
    final text = utf8.decode(_fileBytes!, allowMalformed: true);
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(text),
          ),
        ),
      ),
    );
  }

  Widget _buildUnsupportedPreview() {
    final extension = _getFileExtension(widget.fileName);
    final icon = _getFileIcon(extension);
    final color = _getFileColor(extension);
    final loc = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: color),
          const SizedBox(height: 12),
          Text(
            loc.translate('files.previewNotAvailable'),
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    final loc = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.red.withValues(alpha: 0.08),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 72, color: Colors.red.shade600),
          const SizedBox(height: 12),
          Text(
            loc.translate('files.loadFailed'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.red.shade600,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade600, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetadata(AppLocalizations loc) {
    if (_fileBytes == null && _localFilePath == null && _contentType == null) {
      return const SizedBox.shrink();
    }

    final items = <Widget>[];

    if (_fileBytes != null) {
      items.add(
        _buildMetadataRow(
          icon: Icons.storage,
          label: loc.translate('files.fileSize'),
          value: _formatFileSize(_fileBytes!.lengthInBytes),
        ),
      );
    }

    if (_contentType != null && _contentType!.isNotEmpty) {
      items.add(
        _buildMetadataRow(
          icon: Icons.label,
          label: loc.translate('files.contentType'),
          value: _contentType!,
        ),
      );
    }

    if (_localFilePath != null) {
      items.add(
        _buildMetadataRow(
          icon: Icons.folder,
          label: loc.translate('files.savedTo'),
          valueWidget: SelectableText(
            _localFilePath!,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [const SizedBox(height: 16), ...items],
    );
  }

  Widget _buildMetadataRow({
    required IconData icon,
    required String label,
    String? value,
    Widget? valueWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                if (valueWidget != null)
                  valueWidget
                else if (value != null)
                  Text(value, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getFileIcon(_getFileExtension(widget.fileName)),
                    color: _getFileColor(_getFileExtension(widget.fileName)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.fileName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'ID: ${widget.fileId}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(loc.translate('files.loading')),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFilePreview(),
                            _buildMetadata(loc),
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            loc.translate('files.loadFailed'),
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _error!,
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: TextButton.icon(
                                              onPressed: _loadFile,
                                              icon: const Icon(Icons.refresh),
                                              label: Text(
                                                loc.translate('common.retry'),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showFileViewer(
  BuildContext context, {
  required int fileId,
  required String fileName,
  String? fileUrl,
}) async {
  return showDialog<void>(
    context: context,
    builder: (context) =>
        FileViewerDialog(fileId: fileId, fileName: fileName, fileUrl: fileUrl),
  );
}
