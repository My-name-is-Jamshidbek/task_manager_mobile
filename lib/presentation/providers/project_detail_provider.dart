import 'package:flutter/material.dart';
import '../../data/datasources/project_remote_datasource.dart';
import '../../data/models/project_models.dart';

class ProjectDetailProvider extends ChangeNotifier {
  final ProjectRemoteDataSource _remote;
  Project? _project;
  bool _loading = false;
  String? _error;
  int? _currentId;

  Project? get project => _project;
  bool get isLoading => _loading;
  String? get error => _error;

  ProjectDetailProvider({ProjectRemoteDataSource? remote, Project? initial})
    : _remote = remote ?? ProjectRemoteDataSource() {
    if (initial != null) {
      // Seed optimistic cache
      _project = initial;
      _currentId = initial.id;
    }
  }

  /// Load (or reload) a project by id. If an optimistic project with same id
  /// is already present, UI will show it instantly while fresh data is fetched.
  Future<void> load(int id) async {
    if (_loading) return;
    _currentId = id;
    _loading = true;
    _error = null;
    notifyListeners();

    final res = await _remote.getProject(id);
    if (res.isSuccess) {
      // Update only if this response matches most recent requested id (avoid race)
      if (_currentId == id) {
        _project = res.data;
      }
    } else {
      _error = res.error ?? 'Unknown error';
    }
    _loading = false;
    notifyListeners();
  }
}
