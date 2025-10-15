import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../data/datasources/project_remote_datasource.dart';
import '../../data/datasources/file_group_remote_datasource.dart';
import '../../data/models/project_models.dart';
import '../../data/models/api_task_models.dart';
import '../../data/models/file_models.dart' as file_models;

class ProjectDetailProvider extends ChangeNotifier {
  final ProjectRemoteDataSource _remote;
  final FileGroupRemoteDataSource _fileGroupRemote;
  Project? _project;
  file_models.FileGroup? _fileGroup;
  bool _loading = false;
  String? _error;
  int? _currentId;

  Project? get project => _project;
  file_models.FileGroup? get fileGroup => _fileGroup;
  bool get isLoading => _loading;
  String? get error => _error;

  List<ApiTask> get tasks {
    final p = _project;
    if (p is ProjectWithTasks) return p.tasks;
    return const [];
  }

  List<file_models.FileAttachment> get files {
    // Prioritize file group files over project.files
    if (_fileGroup?.files.isNotEmpty == true) {
      return _fileGroup!.files;
    }
    // Convert project FileAttachments to file_models.FileAttachment
    return _project?.files
            .map(
              (f) => file_models.FileAttachment(
                name: f.name,
                url: f.url,
                id: null,
              ),
            )
            .toList() ??
        [];
  }

  ProjectDetailProvider({
    ProjectRemoteDataSource? remote,
    FileGroupRemoteDataSource? fileGroupRemote,
  }) : _remote = remote ?? ProjectRemoteDataSource(),
       _fileGroupRemote = fileGroupRemote ?? FileGroupRemoteDataSource();

  Future<void> load(int id) async {
    if (_loading) return;
    _currentId = id;
    _loading = true;
    _error = null;
    _project = null; // Clear previous project data
    _fileGroup = null; // Clear previous file group data
    notifyListeners();
    try {
      // Load project (with tasks if available)
      final withTasks = await _remote.getProjectWithTasks(id);
      if (withTasks.isSuccess && _currentId == id) {
        _project = withTasks.data;

        // If project has file_group_id, load the file group
        if (_project?.fileGroupId != null) {
          try {
            final fileGroupResult = await _fileGroupRemote.getFileGroup(
              _project!.fileGroupId!,
            );
            if (fileGroupResult.isSuccess) {
              _fileGroup = fileGroupResult.data;
            }
          } catch (e) {
            // File group loading failed, but don't fail the whole operation
            // Just log or ignore, use project.files as fallback
          }
        }
      } else if (!withTasks.isSuccess) {
        // Fallback to basic project fetch
        final basic = await _remote.getProject(id);
        if (basic.isSuccess && _currentId == id) {
          _project = basic.data;

          // Try to load file group for basic project too
          if (_project?.fileGroupId != null) {
            try {
              final fileGroupResult = await _fileGroupRemote.getFileGroup(
                _project!.fileGroupId!,
              );
              if (fileGroupResult.isSuccess) {
                _fileGroup = fileGroupResult.data;
              }
            } catch (e) {
              // Ignore file group errors
            }
          }
        } else {
          _error = withTasks.error ?? basic.error ?? 'Unknown error';
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<ApiResponse<Project>> updateProject({
    required int projectId,
    String? name,
    String? description,
    int? fileGroupId,
    int? status,
    List<String>? fileIds,
  }) async {
    if (_loading) {
      return ApiResponse.error('Another operation is in progress');
    }
    _loading = true;
    _error = null;
    notifyListeners();

    final existingTasks = tasks;
    ApiResponse<Project>? response;
    try {
      response = await _remote.updateProject(
        projectId: projectId,
        name: name,
        description: description,
        fileGroupId: fileGroupId,
        status: status,
        fileIds: fileIds,
      );

      if (response.isSuccess && response.data != null) {
        final updated = response.data!;
        _currentId = projectId;
        if (updated is ProjectWithTasks) {
          _project = updated;
        } else if (existingTasks.isNotEmpty) {
          _project = ProjectWithTasks(
            id: updated.id,
            name: updated.name,
            description: updated.description,
            creator: updated.creator,
            taskStats: updated.taskStats,
            files: updated.files,
            createdAt: updated.createdAt,
            status: updated.status,
            statusLabel: updated.statusLabel,
            fileGroupId: updated.fileGroupId,
            tasks: existingTasks,
          );
        } else {
          _project = updated;
        }

        final groupId = _project?.fileGroupId;
        if (groupId != null) {
          try {
            final fileGroupResult = await _fileGroupRemote.getFileGroup(
              groupId,
            );
            if (fileGroupResult.isSuccess) {
              _fileGroup = fileGroupResult.data;
            } else {
              _fileGroup = null;
            }
          } catch (_) {
            _fileGroup = null;
          }
        } else {
          _fileGroup = null;
        }
      } else {
        _error = response.error;
      }
    } catch (e) {
      final message = e.toString();
      _error = message;
      response = ApiResponse.error(message);
    } finally {
      _loading = false;
      notifyListeners();
    }

    return response;
  }
}
