import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/datasources/file_group_remote_datasource.dart';
import '../../data/datasources/tasks_api_remote_datasource.dart';
import '../../data/models/api_task_models.dart';
import '../../data/models/file_models.dart';
import '../../data/models/project_models.dart'
    as project_models
    show FileAttachment;
import '../../data/models/task_action.dart';
import '../../data/models/worker_models.dart';

class TaskDetailProvider extends ChangeNotifier {
  final TasksApiRemoteDataSource _remote;
  final FileGroupRemoteDataSource _fileRemote;
  ApiTask? _task;
  bool _loading = false;
  String? _error;
  int? _currentId;
  bool _actionInProgress = false;
  String? _actionError;
  TaskActionKind? _activeAction;
  List<WorkerUser> _workers = const <WorkerUser>[];
  bool _workersLoading = false;
  String? _workersError;
  List<FileAttachment> _attachments = const <FileAttachment>[];
  bool _filesLoading = false;
  String? _filesError;
  int? _currentFileGroupId;

  ApiTask? get task => _task;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isActionInProgress => _actionInProgress;
  String? get actionError => _actionError;
  TaskActionKind? get activeAction => _activeAction;
  bool isActionBusy(TaskActionKind action) =>
      _actionInProgress && _activeAction == action;
  List<WorkerUser> get workers => _workers;
  bool get isWorkersLoading => _workersLoading;
  String? get workersError => _workersError;
  List<FileAttachment> get attachments => _attachments;
  bool get isFilesLoading => _filesLoading;
  String? get filesError => _filesError;

  TaskDetailProvider({
    TasksApiRemoteDataSource? remote,
    FileGroupRemoteDataSource? fileRemote,
  }) : _remote = remote ?? TasksApiRemoteDataSource(),
       _fileRemote = fileRemote ?? FileGroupRemoteDataSource();

  Future<void> load(int id) async {
    if (_loading) return;
    _currentId = id;
    _loading = true;
    _error = null;
    notifyListeners();

    final res = await _remote.getTaskById(id);
    if (res.isSuccess) {
      if (_currentId == id) {
        _task = res.data;
        _attachments = _convertTaskFiles(_task?.files);
        _filesError = null;
        _filesLoading = false;
        _currentFileGroupId = _task?.fileGroupId;
        await _fetchWorkers(id);
        await _fetchAttachments(_currentFileGroupId);
      }
    } else {
      _error = res.error ?? 'Unknown error';
      _workers = const <WorkerUser>[];
      _workersError = res.error;
      _attachments = const <FileAttachment>[];
      _filesError = res.error;
      _filesLoading = false;
      _currentFileGroupId = null;
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> performAction(TaskActionKind action, {String? reason}) async {
    final currentTask = _task;
    if (currentTask == null || _actionInProgress) return false;

    _actionInProgress = true;
    _actionError = null;
    _activeAction = action;
    notifyListeners();

    final response = await _remote.performTaskAction(
      taskId: currentTask.id,
      action: action,
      reason: reason,
    );

    var success = false;
    ApiTask? refreshedTask = response.data;

    if (response.isSuccess) {
      success = true;
      if (refreshedTask == null) {
        final reload = await _remote.getTaskById(currentTask.id);
        if (reload.isSuccess) {
          refreshedTask = reload.data;
        }
      }
      if (refreshedTask != null) {
        _task = refreshedTask;
        _currentId = refreshedTask.id;
        unawaited(_fetchWorkers(refreshedTask.id));
        unawaited(_fetchAttachments(refreshedTask.fileGroupId, force: true));
      }
    } else {
      _actionError = response.error ?? 'Unknown error';
    }

    _actionInProgress = false;
    _activeAction = null;
    notifyListeners();
    return success;
  }

  Future<void> reloadWorkers() async {
    final id = _currentId;
    if (id == null) return;
    await _fetchWorkers(id, force: true);
  }

  Future<void> reloadFiles() async {
    final task = _task;
    if (task == null) return;
    await _fetchAttachments(task.fileGroupId, force: true);
  }

  Future<void> _fetchWorkers(int taskId, {bool force = false}) async {
    if (_workersLoading) {
      if (!force) return;
    }

    _workersLoading = true;
    _workersError = null;
    notifyListeners();

    final res = await _remote.getTaskWorkers(taskId);
    if (_currentId == taskId) {
      if (res.isSuccess) {
        _workers = res.data ?? const <WorkerUser>[];
        _workersError = null;
      } else {
        _workers = const <WorkerUser>[];
        _workersError = res.error ?? 'Unknown error';
      }
    }

    _workersLoading = false;
    notifyListeners();
  }

  Future<void> _fetchAttachments(int? fileGroupId, {bool force = false}) async {
    final previousId = _currentFileGroupId;
    final requested = fileGroupId;

    if (_filesLoading && !force && requested == previousId) {
      return;
    }

    _currentFileGroupId = requested;

    if (requested == null) {
      _attachments = _convertTaskFiles(_task?.files);
      _filesError = null;
      _filesLoading = false;
      notifyListeners();
      return;
    }

    _filesLoading = true;
    _filesError = null;
    notifyListeners();

    final res = await _fileRemote.getFileGroup(requested);

    if (_currentFileGroupId != requested) {
      _filesLoading = false;
      notifyListeners();
      return;
    }

    if (res.isSuccess && res.data != null) {
      _attachments = res.data!.files;
      _filesError = null;
    } else {
      _attachments = const <FileAttachment>[];
      _filesError = res.error ?? 'Unknown error';
    }

    _filesLoading = false;
    notifyListeners();
  }
}

List<FileAttachment> _convertTaskFiles(
  List<project_models.FileAttachment>? files,
) {
  if (files == null || files.isEmpty) {
    return const <FileAttachment>[];
  }
  return files
      .map(
        (file) => FileAttachment(name: file.name, url: file.url, id: file.id),
      )
      .toList(growable: false);
}
