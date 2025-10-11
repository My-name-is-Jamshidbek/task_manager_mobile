import 'package:flutter/material.dart';
import '../../core/utils/logger.dart';
import '../../data/datasources/tasks_api_remote_datasource.dart';
import '../../data/models/worker_models.dart';

class TaskWorkersProvider extends ChangeNotifier {
  final TasksApiRemoteDataSource _remote;
  final int taskId;

  TaskWorkersProvider({required this.taskId, TasksApiRemoteDataSource? remote})
    : _remote = remote ?? TasksApiRemoteDataSource();

  bool _loadingAssigned = false;
  bool _loadingAvailable = false;
  bool _loadingMore = false;
  bool _mutating = false;
  String? _error;

  List<WorkerUser> _assigned = [];
  List<WorkerUser> _available = [];
  int _availablePage = 1;
  final int _perPage = 20;
  bool _hasMoreAvailable = true;

  bool get loadingAssigned => _loadingAssigned;
  bool get loadingAvailable => _loadingAvailable;
  bool get loadingMore => _loadingMore;
  bool get mutating => _mutating;
  String? get error => _error;
  List<WorkerUser> get assigned => _assigned;
  List<WorkerUser> get available => _available;
  bool get hasMoreAvailable => _hasMoreAvailable;

  Future<void> load() async {
    await Future.wait([fetchAssignedWorkers(), fetchAvailableWorkers()]);
  }

  Future<void> fetchAssignedWorkers() async {
    _loadingAssigned = true;
    _error = null;
    notifyListeners();
    final res = await _remote.getTaskWorkers(taskId);
    if (res.isSuccess) {
      _assigned = res.data ?? [];
    } else {
      _error = res.error;
      Logger.warning('TaskWorkersProvider assigned error: $_error');
    }
    _loadingAssigned = false;
    notifyListeners();
  }

  Future<void> fetchAvailableWorkers() async {
    _availablePage = 1;
    _hasMoreAvailable = true;
    _loadingAvailable = true;
    _error = null;
    notifyListeners();
    final res = await _remote.getTaskAvailableWorkers(
      taskId,
      page: _availablePage,
      perPage: _perPage,
    );
    if (res.isSuccess) {
      final data = res.data ?? [];
      _available = data;
      _hasMoreAvailable = data.length == _perPage;
    } else {
      _error = res.error;
      Logger.warning('TaskWorkersProvider available error: $_error');
    }
    _loadingAvailable = false;
    notifyListeners();
  }

  Future<void> loadMoreAvailable() async {
    if (_loadingMore || !_hasMoreAvailable || _loadingAvailable) return;
    _loadingMore = true;
    notifyListeners();
    final nextPage = _availablePage + 1;
    final res = await _remote.getTaskAvailableWorkers(
      taskId,
      page: nextPage,
      perPage: _perPage,
    );
    if (res.isSuccess) {
      final data = res.data ?? [];
      _available = [..._available, ...data];
      _availablePage = nextPage;
      _hasMoreAvailable = data.length == _perPage;
    } else {
      _error = res.error;
      Logger.warning('TaskWorkersProvider loadMore available error: $_error');
    }
    _loadingMore = false;
    notifyListeners();
  }

  Future<bool> addWorker(int userId) async {
    if (_mutating) return false;
    _mutating = true;
    notifyListeners();
    // Optimistic: move user from available -> assigned immediately
    final idx = _available.indexWhere((w) => w.id == userId);
    WorkerUser? selected;
    if (idx != -1) {
      selected = _available[idx];
      _available.removeAt(idx);
      _assigned = [..._assigned, selected];
      notifyListeners();
    }
    final res = await _remote.addTaskWorker(taskId: taskId, userId: userId);
    _mutating = false;
    if (!res.isSuccess) {
      // Rollback
      if (selected != null) {
        _assigned = _assigned.where((w) => w.id != userId).toList();
        _available = [..._available, selected];
      }
      _error = res.error;
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  Future<bool> removeWorker(int userId) async {
    if (_mutating) return false;
    _mutating = true;
    notifyListeners();
    // Optimistic: move user from assigned -> available
    final idx = _assigned.indexWhere((w) => w.id == userId);
    WorkerUser? removed;
    if (idx != -1) {
      removed = _assigned[idx];
      _assigned.removeAt(idx);
      _available = [..._available, removed];
      notifyListeners();
    }
    final res = await _remote.removeTaskWorker(taskId: taskId, userId: userId);
    _mutating = false;
    if (!res.isSuccess) {
      // Rollback
      if (removed != null) {
        _available = _available.where((w) => w.id != userId).toList();
        _assigned = [..._assigned, removed];
      }
      _error = res.error;
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }
}
