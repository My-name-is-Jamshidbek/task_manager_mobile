import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../data/datasources/project_remote_datasource.dart';
import '../../data/datasources/file_group_remote_datasource.dart';
import '../../data/models/project_models.dart';
import '../../data/models/api_task_models.dart';
import '../../data/models/project_task_api_models.dart';
import '../../data/models/file_models.dart' as file_models;

class ProjectDetailProvider extends ChangeNotifier {
  static const int _defaultTasksPerPage = 10;
  final ProjectRemoteDataSource _remote;
  final FileGroupRemoteDataSource _fileGroupRemote;
  Project? _project;
  file_models.FileGroup? _fileGroup;
  bool _loading = false;
  String? _error;
  int? _currentId;

  // Project task API state
  bool _taskDashboardLoading = false;
  String? _taskDashboardError;
  Map<String, int> _taskCounts = const {};
  Map<String, List<ApiTask>> _taskListsByGroup = const {};

  bool _tasksLoading = false;
  bool _tasksLoadingMore = false;
  String? _tasksError;
  List<ApiTask> _taskItems = [];
  bool _tasksHasMore = true;
  int _tasksPage = 1;

  String? _selectedTaskGroup;
  String? _taskSearch;
  int? _taskStatus;
  int? _taskTypeId;
  int? _taskTimeProgress;
  String? _taskDeadline;

  Project? get project => _project;
  file_models.FileGroup? get fileGroup => _fileGroup;
  bool get isLoading => _loading;
  String? get error => _error;

  List<ApiTask> get tasks {
    if (_taskItems.isNotEmpty) return _taskItems;
    if (_selectedTaskGroup != null) {
      final fallback = _taskListsByGroup[_selectedTaskGroup!];
      if (fallback != null && fallback.isNotEmpty) return fallback;
    }
    final p = _project;
    if (p is ProjectWithTasks) return p.tasks;
    return const [];
  }

  Map<String, int> get taskCounts => _taskCounts;
  Map<String, List<ApiTask>> get groupedTaskLists => _taskListsByGroup;
  String? get tasksError => _tasksError;
  bool get isTaskDashboardLoading => _taskDashboardLoading;
  String? get taskDashboardError => _taskDashboardError;
  bool get isTaskListLoading => _tasksLoading && _tasksPage <= 1;
  bool get isTaskListLoadingMore => _tasksLoadingMore;
  bool get hasMoreTasks => _tasksHasMore;
  String? get selectedTaskGroup => _selectedTaskGroup;
  String? get taskSearch => _taskSearch;
  int? get taskStatus => _taskStatus;
  int? get taskTypeId => _taskTypeId;
  int? get taskTimeProgress => _taskTimeProgress;
  String? get taskDeadline => _taskDeadline;

  List<file_models.FileAttachment> get files {
    // Prioritize file group files over project.files
    if (_fileGroup?.files.isNotEmpty == true) {
      return _fileGroup!.files;
    }
    // Convert project FileAttachments to file_models.FileAttachment
    return _project?.files
            .map(
              (f) => file_models.FileAttachment(
                name: f.name,
                url: f.url,
                id: null,
              ),
            )
            .toList() ??
        [];
  }

  ProjectDetailProvider({
    ProjectRemoteDataSource? remote,
    FileGroupRemoteDataSource? fileGroupRemote,
  }) : _remote = remote ?? ProjectRemoteDataSource(),
       _fileGroupRemote = fileGroupRemote ?? FileGroupRemoteDataSource();

  void _resetTaskState() {
    _taskDashboardLoading = false;
    _taskDashboardError = null;
    _taskCounts = const {};
    _taskListsByGroup = const {};
    _tasksLoading = false;
    _tasksLoadingMore = false;
    _tasksError = null;
    _taskItems = [];
    _tasksHasMore = true;
    _tasksPage = 1;
    _selectedTaskGroup = null;
    _taskSearch = null;
    _taskStatus = null;
    _taskTypeId = null;
    _taskTimeProgress = null;
    _taskDeadline = null;
  }

  static const List<String> _taskGroupOrder = <String>[
    'accept',
    'in_progress',
    'completed',
    'checked_finished',
    'rejected',
    'rejected_confirmed',
  ];

  String _pickDefaultTaskGroup(Map<String, int> counts) {
    for (final key in _taskGroupOrder) {
      if ((counts[key] ?? 0) > 0) {
        return key;
      }
    }
    if (counts.isNotEmpty) {
      return counts.entries.first.key;
    }
    return _taskGroupOrder.first;
  }

  Future<void> fetchTaskDashboard() async {
    final id = _currentId;
    if (id == null) return;
    _taskDashboardLoading = true;
    _taskDashboardError = null;
    notifyListeners();

    final response = await _remote.getProjectTasks(projectId: id);
    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      _taskCounts = Map<String, int>.from(data.counts);
      _taskListsByGroup = data.lists.map(
        (key, value) => MapEntry(key, List<ApiTask>.from(value)),
      );
      _taskDashboardError = null;
      _selectedTaskGroup ??= _pickDefaultTaskGroup(_taskCounts);
    } else {
      _taskDashboardError = response.error ?? 'Unknown error';
      _taskCounts = const {};
      _taskListsByGroup = const {};
    }

    _taskDashboardLoading = false;
    notifyListeners();
  }

  Future<bool> _fetchProjectTasksInternal({
    required int projectId,
    required int page,
  }) async {
    final group = _selectedTaskGroup;
    if (group == null || group.isEmpty) {
      _taskItems = [];
      _tasksHasMore = false;
      return true;
    }

    final result = await _remote.getProjectTasks(
      projectId: projectId,
      group: group,
      page: page,
      perPage: _defaultTasksPerPage,
      search: _taskSearch,
      status: _taskStatus,
      taskTypeId: _taskTypeId,
      timeProgress: _taskTimeProgress,
      deadline: _taskDeadline,
    );

    if (result.isSuccess && result.data != null) {
      final payload = result.data!;
      final incoming = List<ApiTask>.from(payload.items);
      if (page <= 1) {
        _taskItems = incoming;
      } else {
        _taskItems = [..._taskItems, ...incoming];
      }

      if (payload.counts.isNotEmpty) {
        _taskCounts = Map<String, int>.from(payload.counts);
      }

      if (_selectedTaskGroup != null) {
        _taskListsByGroup = {
          ..._taskListsByGroup,
          _selectedTaskGroup!: List<ApiTask>.from(_taskItems),
        };
      }

      final meta = payload.meta;
      if (meta != null) {
        _tasksHasMore = meta.hasMore;
      } else {
        _tasksHasMore = incoming.length >= _defaultTasksPerPage;
      }

      _tasksError = null;
      return true;
    } else {
      _tasksError = result.error ?? 'Unknown error';
      return false;
    }
  }

  Future<void> refreshProjectTasks() async {
    final id = _currentId;
    if (id == null) return;
    _tasksPage = 1;
    _tasksHasMore = true;
    _tasksLoading = true;
    _tasksError = null;
    notifyListeners();

    final success = await _fetchProjectTasksInternal(projectId: id, page: 1);

    _tasksLoading = false;
    if (!success && _taskItems.isEmpty) {
      _tasksHasMore = false;
    }
    notifyListeners();
  }

  Future<void> loadMoreProjectTasks() async {
    final id = _currentId;
    if (id == null) return;
    if (_tasksLoading || _tasksLoadingMore || !_tasksHasMore) return;

    final nextPage = _tasksPage + 1;
    _tasksLoadingMore = true;
    notifyListeners();

    final success = await _fetchProjectTasksInternal(
      projectId: id,
      page: nextPage,
    );

    if (success) {
      _tasksPage = nextPage;
    }

    _tasksLoadingMore = false;
    notifyListeners();
  }

  Future<void> selectTaskGroup(String group) async {
    if (_selectedTaskGroup == group) return;
    _selectedTaskGroup = group;
    _tasksPage = 1;
    _tasksHasMore = true;
    _taskItems = [];
    _tasksError = null;
    notifyListeners();
    await refreshProjectTasks();
  }

  Future<void> updateTaskSearch(String? value) async {
    final normalized = (value ?? '').trim();
    final newValue = normalized.isEmpty ? null : normalized;
    if (_taskSearch == newValue) return;
    _taskSearch = newValue;
    await refreshProjectTasks();
  }

  Future<void> updateTaskStatus(int? status) async {
    if (_taskStatus == status) return;
    _taskStatus = status;
    await refreshProjectTasks();
  }

  Future<void> _initializeTaskData() async {
    await fetchTaskDashboard();
    if (_selectedTaskGroup != null) {
      await refreshProjectTasks();
    }
  }

  Future<void> _refreshFileGroup(int? groupId) async {
    if (groupId == null) {
      _fileGroup = null;
      return;
    }
    try {
      final fileGroupResult = await _fileGroupRemote.getFileGroup(groupId);
      if (fileGroupResult.isSuccess) {
        _fileGroup = fileGroupResult.data;
      } else {
        _fileGroup = null;
      }
    } catch (_) {
      _fileGroup = null;
    }
  }

  Project _mergeProjectWithTasks(Project updated, List<ApiTask> existingTasks) {
    if (updated is ProjectWithTasks) return updated;
    if (existingTasks.isEmpty) return updated;
    return ProjectWithTasks(
      id: updated.id,
      name: updated.name,
      description: updated.description,
      creator: updated.creator,
      taskStats: updated.taskStats,
      files: updated.files,
      createdAt: updated.createdAt,
      status: updated.status,
      statusLabel: updated.statusLabel,
      fileGroupId: updated.fileGroupId,
      tasks: existingTasks,
    );
  }

  Future<ApiResponse<Project>> _applyProjectMutation(
    Future<ApiResponse<Project>> Function() mutation,
  ) async {
    if (_loading) {
      return ApiResponse.error('Another operation is in progress');
    }
    _loading = true;
    _error = null;
    notifyListeners();

    final existingTasks = tasks;
    late ApiResponse<Project> response;

    try {
      response = await mutation();
      if (response.isSuccess && response.data != null) {
        final merged = _mergeProjectWithTasks(response.data!, existingTasks);
        _project = merged;
        _currentId = merged.id;
        await _refreshFileGroup(merged.fileGroupId);
      } else {
        _error = response.error;
      }
    } catch (e) {
      final message = e.toString();
      _error = message;
      response = ApiResponse.error(message);
    } finally {
      _loading = false;
      notifyListeners();
    }

    return response;
  }

  Future<void> load(int id) async {
    if (_loading) return;
    _currentId = id;
    _loading = true;
    _error = null;
    _project = null; // Clear previous project data
    _fileGroup = null; // Clear previous file group data
    _resetTaskState();
    notifyListeners();
    try {
      // Load project (with tasks if available)
      final withTasks = await _remote.getProjectWithTasks(id);
      if (withTasks.isSuccess && _currentId == id) {
        _project = withTasks.data;

        // If project has file_group_id, load the file group
        if (_project?.fileGroupId != null) {
          try {
            final fileGroupResult = await _fileGroupRemote.getFileGroup(
              _project!.fileGroupId!,
            );
            if (fileGroupResult.isSuccess) {
              _fileGroup = fileGroupResult.data;
            }
          } catch (e) {
            // File group loading failed, but don't fail the whole operation
            // Just log or ignore, use project.files as fallback
          }
        }
        await _initializeTaskData();
      } else if (!withTasks.isSuccess) {
        // Fallback to basic project fetch
        final basic = await _remote.getProject(id);
        if (basic.isSuccess && _currentId == id) {
          _project = basic.data;

          // Try to load file group for basic project too
          if (_project?.fileGroupId != null) {
            try {
              final fileGroupResult = await _fileGroupRemote.getFileGroup(
                _project!.fileGroupId!,
              );
              if (fileGroupResult.isSuccess) {
                _fileGroup = fileGroupResult.data;
              }
            } catch (e) {
              // Ignore file group errors
            }
          }
          await _initializeTaskData();
        } else {
          _error = withTasks.error ?? basic.error ?? 'Unknown error';
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<ApiResponse<Project>> updateProject({
    required int projectId,
    String? name,
    String? description,
    int? fileGroupId,
    int? status,
    List<String>? fileIds,
  }) {
    return _applyProjectMutation(
      () => _remote.updateProject(
        projectId: projectId,
        name: name,
        description: description,
        fileGroupId: fileGroupId,
        status: status,
        fileIds: fileIds,
      ),
    );
  }

  Future<ApiResponse<Project>> completeProject(int projectId) {
    return _applyProjectMutation(() => _remote.completeProject(projectId));
  }

  Future<ApiResponse<Project>> rejectProject(int projectId) {
    return _applyProjectMutation(() => _remote.rejectProject(projectId));
  }
}
