import 'package:flutter/foundation.dart';
import '../../data/datasources/file_group_remote_datasource.dart';
import '../../data/models/file_models.dart';

class FileGroupProvider extends ChangeNotifier {
  final FileGroupRemoteDataSource _remote;

  FileGroup? _fileGroup;
  bool _isLoading = false;
  String? _error;

  FileGroup? get fileGroup => _fileGroup;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<FileAttachment> get files => _fileGroup?.files ?? [];
  bool get hasFiles => files.isNotEmpty;

  FileGroupProvider({FileGroupRemoteDataSource? remote})
    : _remote = remote ?? FileGroupRemoteDataSource();

  /// Initialize with a file group ID
  Future<void> loadFileGroup(int fileGroupId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _remote.getFileGroup(fileGroupId);

    if (result.isSuccess && result.data != null) {
      _fileGroup = result.data;
    } else {
      _error = result.error;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Create a new file group
  Future<bool> createFileGroup(String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _remote.createFileGroup(name: name);

    if (result.isSuccess && result.data != null) {
      _fileGroup = result.data;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _error = result.error;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Add a file to the current file group
  Future<bool> addFile(String fileName, Uint8List fileBytes) async {
    if (_fileGroup == null) {
      _error = "No active file group";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    final result = await _remote.addFileToGroup(
      fileGroupId: _fileGroup!.id,
      fileName: fileName,
      fileBytes: fileBytes,
    );

    if (result.isSuccess && result.data != null) {
      // Update the file list
      final updatedFiles = List<FileAttachment>.from(_fileGroup!.files);
      updatedFiles.add(result.data!);

      _fileGroup = FileGroup(
        id: _fileGroup!.id,
        name: _fileGroup!.name,
        files: updatedFiles,
        createdAt: _fileGroup!.createdAt,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _error = result.error;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete a file from the current file group
  Future<bool> deleteFile(FileAttachment file) async {
    if (_fileGroup == null || file.id == null) {
      _error = "No active file group or invalid file";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    final result = await _remote.deleteFile(file.id!);

    if (result.isSuccess) {
      // Remove the file from the list
      final updatedFiles = List<FileAttachment>.from(
        _fileGroup!.files,
      ).where((f) => f.id != file.id).toList();

      _fileGroup = FileGroup(
        id: _fileGroup!.id,
        name: _fileGroup!.name,
        files: updatedFiles,
        createdAt: _fileGroup!.createdAt,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _error = result.error;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete the entire file group
  Future<bool> deleteFileGroup() async {
    if (_fileGroup == null) {
      _error = "No active file group";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    final result = await _remote.deleteFileGroup(_fileGroup!.id);

    if (result.isSuccess) {
      _fileGroup = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _error = result.error;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get download URL for a file
  String getDownloadUrl(FileAttachment file) {
    if (file.id == null) {
      return file.url; // Use the URL provided if no ID
    }
    return _remote.getFileDownloadUrl(file.id!);
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
