import 'package:flutter/material.dart';
import '../../data/datasources/tasks_api_remote_datasource.dart';
import '../../data/models/api_task_models.dart';
import '../../data/models/task_action.dart';

class TaskDetailProvider extends ChangeNotifier {
  final TasksApiRemoteDataSource _remote;
  ApiTask? _task;
  bool _loading = false;
  String? _error;
  int? _currentId;
  bool _actionInProgress = false;
  String? _actionError;
  TaskActionKind? _activeAction;

  ApiTask? get task => _task;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isActionInProgress => _actionInProgress;
  String? get actionError => _actionError;
  TaskActionKind? get activeAction => _activeAction;
  bool isActionBusy(TaskActionKind action) =>
      _actionInProgress && _activeAction == action;

  TaskDetailProvider({TasksApiRemoteDataSource? remote})
    : _remote = remote ?? TasksApiRemoteDataSource();

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
      }
    } else {
      _error = res.error ?? 'Unknown error';
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
      }
    } else {
      _actionError = response.error ?? 'Unknown error';
    }

    _actionInProgress = false;
    _activeAction = null;
    notifyListeners();
    return success;
  }
}
