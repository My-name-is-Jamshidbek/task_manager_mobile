import 'package:flutter/material.dart';
import '../../core/utils/logger.dart';
import '../../data/datasources/tasks_api_remote_datasource.dart';
import '../../data/models/api_task_models.dart';

class TasksApiProvider extends ChangeNotifier {
  final TasksApiRemoteDataSource _remote;
  bool _loading = false;
  String? _error;
  List<ApiTask> _tasks = [];

  // Filters
  int? perPage;
  String? filter; // created_by_me | assigned_to_me
  String? name; // search text
  int? status; // status id

  TasksApiProvider({TasksApiRemoteDataSource? remote})
      : _remote = remote ?? TasksApiRemoteDataSource();

  bool get isLoading => _loading;
  String? get error => _error;
  List<ApiTask> get tasks => _tasks;

  Future<void> fetchTasks({
    int? perPage,
    String? filter,
    String? name,
    int? status,
  }) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    final res = await _remote.getTasks(
      perPage: perPage ?? this.perPage,
      filter: filter ?? this.filter,
      name: name ?? this.name,
      status: status ?? this.status,
    );

    if (res.isSuccess) {
      _tasks = res.data ?? [];
      Logger.info('🧾 TasksApiProvider: Loaded ${_tasks.length} tasks');
    } else {
      _error = res.error ?? 'Unknown error';
      Logger.warning('⚠️ TasksApiProvider: Error - $_error');
    }

    _loading = false;
    notifyListeners();
  }
}
