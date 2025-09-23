import 'package:flutter/material.dart';
import '../../data/datasources/tasks_api_remote_datasource.dart';
import '../../data/models/api_task_models.dart';

class TaskDetailProvider extends ChangeNotifier {
  final TasksApiRemoteDataSource _remote;
  ApiTask? _task;
  bool _loading = false;
  String? _error;
  int? _currentId;

  ApiTask? get task => _task;
  bool get isLoading => _loading;
  String? get error => _error;

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
}
