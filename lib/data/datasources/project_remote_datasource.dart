import '../../core/api/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/project_models.dart';

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
}
