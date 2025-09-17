import '../../core/api/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/api_task_models.dart';

class TasksApiRemoteDataSource {
  final ApiClient _apiClient;
  TasksApiRemoteDataSource({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<ApiResponse<List<ApiTask>>> getTasks({
    int? perPage,
    String? filter, // created_by_me | assigned_to_me
    String? name, // search by name
    int? status, // status id
  }) async {
    final query = <String, String>{};
    if (perPage != null) query['per_page'] = perPage.toString();
    if (filter != null && filter.isNotEmpty) query['filter'] = filter;
    if (name != null && name.isNotEmpty) query['name'] = name;
    if (status != null) query['status'] = status.toString();

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
}
