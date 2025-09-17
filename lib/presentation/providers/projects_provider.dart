import 'package:flutter/material.dart';
import '../../core/utils/logger.dart';
import '../../data/datasources/project_remote_datasource.dart';
import '../../data/models/project_models.dart';

class ProjectsProvider extends ChangeNotifier {
  final ProjectRemoteDataSource _remote;
  bool _loading = false;
  String? _error;
  List<Project> _projects = [];
  int _page = 1;
  bool _hasMore = true;

  // Filters/state (persist last used)
  String? search;
  int? perPage = 10;
  String? filter; // 'created_by_me' | 'assigned_to_me' | null
  int? status; // 1..4 | null

  ProjectsProvider({ProjectRemoteDataSource? remote})
    : _remote = remote ?? ProjectRemoteDataSource();

  bool get isLoading => _loading;
  String? get error => _error;
  List<Project> get projects => _projects;
  bool get hasMore => _hasMore;
  int get page => _page;

  Future<void> fetchProjects({
    String? search,
    int? perPage,
    String? filter,
    int? status,
  }) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    // Use effective criteria: provided or persisted
    final effectiveSearch = search ?? this.search;
    final effectivePerPage = perPage ?? this.perPage;
    final effectiveFilter = filter ?? this.filter;
    final effectiveStatus = status ?? this.status;

    // Persist criteria for subsequent paging
    this.search = effectiveSearch;
    this.perPage = effectivePerPage;
    this.filter = effectiveFilter;
    this.status = effectiveStatus;

    final res = await _remote.getProjects(
      search: effectiveSearch,
      perPage: effectivePerPage,
      page: _page,
      filter: effectiveFilter,
      status: effectiveStatus,
    );

    if (res.isSuccess) {
      final items = res.data ?? [];
      if (_page == 1) {
        _projects = items;
      } else {
        _projects = [..._projects, ...items];
      }
      _hasMore = items.length == (effectivePerPage ?? 10);
      Logger.info(
        '📁 ProjectsProvider: Page $_page, +${items.length}, total ${_projects.length}, hasMore=$_hasMore',
      );
    } else {
      _error = res.error ?? 'Unknown error';
      Logger.warning('⚠️ ProjectsProvider: Error - $_error');
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _page = 1;
    _hasMore = true;
    await fetchProjects();
  }

  Future<void> loadMore() async {
    if (_loading || !_hasMore) return;
    _page += 1;
    await fetchProjects();
  }
}
