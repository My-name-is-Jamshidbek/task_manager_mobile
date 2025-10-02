import 'package:flutter/material.dart';
import '../../core/utils/logger.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/models/dashboard_models.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardRemoteDataSource _remote;
  bool _loading = false;
  String? _error;
  UserStats? _stats;
  bool _projStatsLoading = false;
  String? _projStatsError;
  List<ProjectStatusStat> _projectStats = const [];
  bool _taskStatsLoading = false;
  String? _taskStatsError;
  List<TaskStatusStat> _taskStats = const [];

  DashboardProvider({DashboardRemoteDataSource? remote})
    : _remote = remote ?? DashboardRemoteDataSource();

  bool get isLoading => _loading;
  String? get error => _error;
  UserStats? get stats => _stats;
  bool get isProjectStatsLoading => _projStatsLoading;
  String? get projectStatsError => _projStatsError;
  List<ProjectStatusStat> get projectStats => _projectStats;
  bool get isTaskStatsLoading => _taskStatsLoading;
  String? get taskStatsError => _taskStatsError;
  List<TaskStatusStat> get taskStats => _taskStats;

  Future<void> fetchUserStats() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final s = await _remote.getUserStats();
      _stats = s;
      Logger.info(
        '📊 DashboardProvider: Stats loaded '
        '(completed=${s.completedTasksCount}, pending=${s.pendingTasksCount}, projects=${s.totalProjectsCount})',
      );
    } catch (e) {
      _error = e.toString();
      Logger.warning('⚠️ DashboardProvider: Failed to load stats: $_error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await fetchUserStats();
  }

  Future<void> fetchProjectStatsByStatus() async {
    if (_projStatsLoading) return;
    _projStatsLoading = true;
    _projStatsError = null;
    notifyListeners();

    try {
      final list = await _remote.getProjectStatsByStatus();
      _projectStats = list;
      Logger.info(
        '📊 DashboardProvider: Project stats loaded: '
        '${list.map((e) => '${e.statusKey}:${e.count}').join(', ')}',
      );
    } catch (e) {
      _projStatsError = e.toString();
      Logger.warning(
        '⚠️ DashboardProvider: Failed to load project stats: $_projStatsError',
      );
    } finally {
      _projStatsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProjectStats() async {
    await fetchProjectStatsByStatus();
  }

  Future<void> fetchTaskStatsByStatus() async {
    if (_taskStatsLoading) return;
    _taskStatsLoading = true;
    _taskStatsError = null;
    notifyListeners();

    try {
      final list = await _remote.getTaskStatsByStatus();
      _taskStats = list;
      Logger.info(
        '📊 DashboardProvider: Task stats loaded: '
        '${list.map((e) => '${e.statusKey}:${e.count}').join(', ')}',
      );
    } catch (e) {
      _taskStatsError = e.toString();
      Logger.warning(
        '⚠️ DashboardProvider: Failed to load task stats: $_taskStatsError',
      );
    } finally {
      _taskStatsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshTaskStats() async {
    await fetchTaskStatsByStatus();
  }
}
