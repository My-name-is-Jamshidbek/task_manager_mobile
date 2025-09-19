import 'package:http/http.dart' as http;
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

  Future<ApiResponse<Project>> createProject({
    required String name,
    String? description,
    List<String>? fileIds,
  }) async {
    // Build simple fields
    final fields = <String, String>{
      'name': name,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    };

    // Build repeated fields for file_id[] using MultipartFile.fromString
    final files = <String, http.MultipartFile>{};
    if (fileIds != null && fileIds.isNotEmpty) {
      for (var i = 0; i < fileIds.length; i++) {
        final id = fileIds[i].trim();
        if (id.isEmpty) continue;
        files['file_id_$i'] = http.MultipartFile.fromString('file_id[]', id);
      }
    }

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
}
