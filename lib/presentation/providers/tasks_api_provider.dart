import 'package:flutter/material.dart';
import '../../core/utils/logger.dart';
import '../../data/datasources/tasks_api_remote_datasource.dart';
import '../../data/models/api_task_models.dart';

class TasksApiProvider extends ChangeNotifier {
  final TasksApiRemoteDataSource _remote;
  bool _loading = false;
  String? _error;
  List<ApiTask> _tasks = [];
  int _page = 1;
  bool _hasMore = true;

  // Filters
  int? perPage = 10;
  String? filter; // created_by_me | assigned_to_me
  String? name; // search text
  int? status; // status id

  TasksApiProvider({TasksApiRemoteDataSource? remote})
    : _remote = remote ?? TasksApiRemoteDataSource();

  bool get isLoading => _loading;
  String? get error => _error;
  List<ApiTask> get tasks => _tasks;
  bool get hasMore => _hasMore;
  int get page => _page;

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

    // Reset paging when core filters change via parameters
    final effectivePerPage = perPage ?? this.perPage;
    final effectiveFilter = filter ?? this.filter;
    final effectiveName = name ?? this.name;
    final effectiveStatus = status ?? this.status;

    final res = await _remote.getTasks(
      perPage: effectivePerPage,
      page: _page,
      filter: effectiveFilter,
      name: effectiveName,
      status: effectiveStatus,
    );

    if (res.isSuccess) {
      final items = res.data ?? [];
      if (_page == 1) {
        _tasks = items;
      } else {
        _tasks = [..._tasks, ...items];
      }
      _hasMore = items.length == (effectivePerPage ?? 10);
      Logger.info(
        '🧾 TasksApiProvider: Page $_page, +${items.length}, total ${_tasks.length}, hasMore=$_hasMore',
      );
    } else {
      _error = res.error ?? 'Unknown error';
      Logger.warning('⚠️ TasksApiProvider: Error - $_error');
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _page = 1;
    _hasMore = true;
    await fetchTasks();
  }

  Future<void> loadMore() async {
    if (_loading || !_hasMore) return;
    _page += 1;
    await fetchTasks();
  }
}
