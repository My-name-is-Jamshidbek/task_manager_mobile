import 'package:flutter/material.dart';
import '../../core/utils/logger.dart';
import '../../data/datasources/project_remote_datasource.dart';
import '../../data/models/project_models.dart';

class ProjectsProvider extends ChangeNotifier {
  final ProjectRemoteDataSource _remote;
  bool _loading = false;
  String? _error;
  List<Project> _projects = [];

  ProjectsProvider({ProjectRemoteDataSource? remote})
    : _remote = remote ?? ProjectRemoteDataSource();

  bool get isLoading => _loading;
  String? get error => _error;
  List<Project> get projects => _projects;

  Future<void> fetchProjects({
    String? search,
    int? perPage,
    String? filter,
  }) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    final res = await _remote.getProjects(
      search: search,
      perPage: perPage,
      filter: filter,
    );

    if (res.isSuccess) {
      _projects = res.data ?? [];
      Logger.info('📁 ProjectsProvider: Loaded ${_projects.length} projects');
    } else {
      _error = res.error ?? 'Unknown error';
      Logger.warning('⚠️ ProjectsProvider: Error - $_error');
    }

    _loading = false;
    notifyListeners();
  }
}
