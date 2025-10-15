import 'package:http/http.dart' as http;
import '../../core/api/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/project_models.dart';
import '../models/project_task_api_models.dart';

class ProjectRemoteDataSource {
  final ApiClient _apiClient;

  ProjectRemoteDataSource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<ApiResponse<List<Project>>> getProjects({
    String? search,
    int? perPage,
    int? page,
    String? filter, // 'created_by_me' (default) | 'assigned_to_me'
    int? status, // 1=active,2=completed,3=expired,4=rejected
  }) async {
    final query = <String, String>{};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (perPage != null) query['per_page'] = perPage.toString();
    if (page != null) query['page'] = page.toString();
    if (filter != null && filter.isNotEmpty) query['filter'] = filter;
    if (status != null) query['status'] = status.toString();

    // Parse envelope: { data: [...], meta: {...}, links: {...} }
    return _apiClient.get<List<Project>>(
      ApiConstants.projects,
      queryParams: query.isEmpty ? null : query,
      fromJson: (obj) {
        final list = (obj['data'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map((e) => Project.fromJson(e))
            .toList();
        return list;
      },
    );
  }

  Future<ApiResponse<Project>> getProject(int id) async {
    return _apiClient.get<Project>(
      '${ApiConstants.projects}/$id',
      fromJson: (obj) {
        // obj is Map<String,dynamic> per ApiClient contract
        if (obj['data'] is Map<String, dynamic>) {
          return Project.fromJson(obj['data'] as Map<String, dynamic>);
        }
        if (obj['id'] != null) {
          return Project.fromJson(obj);
        }
        throw Exception('Invalid project response structure');
      },
    );
  }

  /// Fetch project detail expecting embedded tasks array under 'tasks'.
  Future<ApiResponse<ProjectWithTasks>> getProjectWithTasks(int id) async {
    return _apiClient.get<ProjectWithTasks>(
      '${ApiConstants.projects}/$id',
      fromJson: (obj) {
        final map = obj['data'] is Map<String, dynamic>
            ? obj['data'] as Map<String, dynamic>
            : obj;
        return ProjectWithTasks.fromJson(map);
      },
    );
  }

  Future<ApiResponse<Project>> createProject({
    required String name,
    String? description,
    int? fileGroupId,
  }) async {
    // Build simple fields
    final fields = <String, String>{
      'name': name,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (fileGroupId != null) 'file_group_id': fileGroupId.toString(),
    };

    // No individual file IDs for project creation; only reference group id.
    final files = <String, http.MultipartFile>{};

    return _apiClient.uploadMultipart<Project>(
      ApiConstants.projects,
      fields: fields,
      files: files,
      fromJson: (obj) {
        // API may return { data: {...} } or flat object
        if (obj['data'] is Map<String, dynamic>) {
          return Project.fromJson(obj['data'] as Map<String, dynamic>);
        }
        return Project.fromJson(obj);
      },
    );
  }

  Future<ApiResponse<Project>> updateProject({
    required int projectId,
    String? name,
    String? description,
    int? fileGroupId,
    int? status,
    List<String>? fileIds,
  }) async {
    final endpoint = '${ApiConstants.projects}/$projectId';
    final fields = <String, String>{
      '_method': 'PUT',
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (fileGroupId != null) 'file_group_id': fileGroupId.toString(),
      if (status != null) 'status': status.toString(),
    };

    final files = <String, http.MultipartFile>{};
    if (fileIds != null && fileIds.isNotEmpty) {
      for (var i = 0; i < fileIds.length; i++) {
        final id = fileIds[i].trim();
        if (id.isEmpty) continue;
        files['files_$i'] = http.MultipartFile.fromString('files[]', id);
      }
    }

    return _apiClient.uploadMultipart<Project>(
      endpoint,
      fields: fields,
      files: files,
      fromJson: (obj) {
        final map = obj['data'] is Map<String, dynamic>
            ? obj['data'] as Map<String, dynamic>
            : obj;
        return Project.fromJson(map);
      },
    );
  }

  Future<ApiResponse<Project>> completeProject(int projectId) async {
    final endpoint = '${ApiConstants.projects}/$projectId/complete';
    return _apiClient.post<Project>(
      endpoint,
      body: const <String, dynamic>{},
      fromJson: (obj) {
        final map = obj['data'] is Map<String, dynamic>
            ? obj['data'] as Map<String, dynamic>
            : obj;
        return Project.fromJson(map);
      },
    );
  }

  Future<ApiResponse<Project>> rejectProject(int projectId) async {
    final endpoint = '${ApiConstants.projects}/$projectId/reject';
    return _apiClient.post<Project>(
      endpoint,
      body: const <String, dynamic>{},
      fromJson: (obj) {
        final map = obj['data'] is Map<String, dynamic>
            ? obj['data'] as Map<String, dynamic>
            : obj;
        return Project.fromJson(map);
      },
    );
  }

  Future<ApiResponse<ProjectTasksResult>> getProjectTasks({
    required int projectId,
    String? group,
    int? page,
    int? perPage,
    String? search,
    int? status,
    int? taskTypeId,
    int? timeProgress,
    String? deadline,
  }) async {
    final endpoint = '${ApiConstants.projects}/$projectId/tasks';
    final query = <String, String>{};
    if (group != null && group.isNotEmpty) query['group'] = group;
    if (page != null) query['page'] = page.toString();
    if (perPage != null) query['per_page'] = perPage.toString();
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (status != null) query['status'] = status.toString();
    if (taskTypeId != null) query['task_type_id'] = taskTypeId.toString();
    if (timeProgress != null) query['time_progress'] = timeProgress.toString();
    if (deadline != null && deadline.isNotEmpty) query['deadline'] = deadline;

    return _apiClient.get<ProjectTasksResult>(
      endpoint,
      queryParams: query.isEmpty ? null : query,
      fromJson: (obj) => ProjectTasksResult.fromResponse(obj),
    );
  }
}
