import 'package:http/http.dart' as http;
import '../../core/api/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/api_task_models.dart';
import '../models/worker_models.dart';
import '../models/task_action.dart';

class TasksApiRemoteDataSource {
  final ApiClient _apiClient;
  TasksApiRemoteDataSource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<ApiResponse<List<ApiTask>>> getTasks({
    int? perPage,
    int? page,
    String? filter, // created_by_me | assigned_to_me
    String? name, // search by name
    int? status, // status id
    int? projectId, // filter by project
  }) async {
    final query = <String, String>{};
    if (perPage != null) query['per_page'] = perPage.toString();
    if (page != null) query['page'] = page.toString();
    if (filter != null && filter.isNotEmpty) query['filter'] = filter;
    if (name != null && name.isNotEmpty) query['name'] = name;
    if (status != null) query['status'] = status.toString();
    if (projectId != null) query['project_id'] = projectId.toString();

    return _apiClient.get<List<ApiTask>>(
      ApiConstants.tasks,
      queryParams: query.isEmpty ? null : query,
      // Support envelope: { data: [...] }
      fromJson: (obj) {
        final list = (obj['data'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ApiTask.fromJson)
            .toList();
        return list;
      },
      // Support raw list: [ {...}, {...} ]
      fromJsonList: (list) =>
          list.whereType<Map<String, dynamic>>().map(ApiTask.fromJson).toList(),
    );
  }

  Future<ApiResponse<ApiTask>> createTask({
    required int projectId,
    required int taskTypeId,
    required String name,
    String? description,
    required String deadlineIso,
    List<int>? toWhomUserIds,
    int? parentTaskId,
    List<String>? fileIds,
    int? fileGroupId,
  }) async {
    final fields = <String, String>{
      'project_id': projectId.toString(),
      'task_type_id': taskTypeId.toString(),
      'name': name,
      'deadline': deadlineIso, // e.g., 2025-09-19T10:57:51Z
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (parentTaskId != null) 'parent_task_id': parentTaskId.toString(),
      // Backend expects the group reference under 'file_group_id' for tasks
      if (fileGroupId != null) 'file_group_id': fileGroupId.toString(),
    };

    final files = <String, http.MultipartFile>{};
    if (toWhomUserIds != null && toWhomUserIds.isNotEmpty) {
      for (var i = 0; i < toWhomUserIds.length; i++) {
        files['to_whom_$i'] = http.MultipartFile.fromString(
          'to_whom[]',
          toWhomUserIds[i].toString(),
        );
      }
    }
    if (fileIds != null && fileIds.isNotEmpty) {
      for (var i = 0; i < fileIds.length; i++) {
        final id = fileIds[i].trim();
        if (id.isEmpty) continue;
        files['file_id_$i'] = http.MultipartFile.fromString('file_id[]', id);
      }
    }

    return _apiClient.uploadMultipart<ApiTask>(
      ApiConstants.tasks,
      fields: fields,
      files: files,
      fromJson: (obj) {
        // support both { data: {...} } and flat object
        final map = (obj['data'] is Map<String, dynamic>)
            ? obj['data'] as Map<String, dynamic>
            : obj;
        return ApiTask.fromJson(map);
      },
    );
  }

  Future<ApiResponse<ApiTask>> getTaskById(int id) async {
    final endpoint = '${ApiConstants.taskById}/$id';
    return _apiClient.get<ApiTask>(
      endpoint,
      fromJson: (obj) {
        final map = (obj['data'] is Map<String, dynamic>)
            ? obj['data'] as Map<String, dynamic>
            : obj;
        return ApiTask.fromJson(map);
      },
    );
  }

  Future<ApiResponse<ApiTask>> performTaskAction({
    required int taskId,
    required TaskActionKind action,
    String? reason,
  }) async {
    final endpoint = '${ApiConstants.tasks}/$taskId/${action.pathSegment}';
    final body = (reason != null && reason.trim().isNotEmpty)
        ? {'reason': reason.trim()}
        : null;
    return _apiClient.post<ApiTask>(
      endpoint,
      body: body,
      fromJson: (obj) {
        final map = (obj['data'] is Map<String, dynamic>)
            ? obj['data'] as Map<String, dynamic>
            : obj;
        return ApiTask.fromJson(map);
      },
    );
  }

  // ---------------- Worker assignment endpoints ----------------
  Future<ApiResponse<List<WorkerUser>>> getTaskWorkers(int taskId) async {
    final endpoint = '${ApiConstants.tasks}/$taskId/workers';
    return _apiClient.get<List<WorkerUser>>(
      endpoint,
      fromJson: (obj) {
        final list =
            (obj['data'] as List<dynamic>? ?? obj as List<dynamic>? ?? [])
                .whereType<Map<String, dynamic>>()
                .map(WorkerUser.fromJson)
                .toList();
        return list;
      },
      fromJsonList: (list) => list
          .whereType<Map<String, dynamic>>()
          .map(WorkerUser.fromJson)
          .toList(),
    );
  }

  Future<ApiResponse<List<WorkerUser>>> getTaskAvailableWorkers(
    int taskId, {
    int? page,
    int? perPage,
  }) async {
    final endpoint = '${ApiConstants.tasks}/$taskId/available-workers';
    final query = <String, String>{};
    if (page != null) query['page'] = page.toString();
    if (perPage != null) query['per_page'] = perPage.toString();
    return _apiClient.get<List<WorkerUser>>(
      endpoint,
      queryParams: query.isEmpty ? null : query,
      fromJson: (obj) {
        final list =
            (obj['data'] as List<dynamic>? ?? obj as List<dynamic>? ?? [])
                .whereType<Map<String, dynamic>>()
                .map(WorkerUser.fromJson)
                .toList();
        return list;
      },
      fromJsonList: (list) => list
          .whereType<Map<String, dynamic>>()
          .map(WorkerUser.fromJson)
          .toList(),
    );
  }

  Future<ApiResponse<void>> addTaskWorker({
    required int taskId,
    required int userId,
  }) async {
    final endpoint = '${ApiConstants.tasks}/$taskId/workers';
    return _apiClient.post<void>(
      endpoint,
      body: {'user_id': userId},
      fromJson: (_) {},
    );
  }

  Future<ApiResponse<void>> removeTaskWorker({
    required int taskId,
    required int userId,
  }) async {
    final endpoint = '${ApiConstants.tasks}/$taskId/workers/$userId';
    return _apiClient.delete<void>(endpoint, fromJson: (_) {});
  }
}
