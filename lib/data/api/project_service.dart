import 'package:http/http.dart' as http;
import '../../core/api/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/project_models.dart';

class ProjectService {
  final ApiClient _apiClient;

  ProjectService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<ApiResponse<Project>> createProject({
    required String name,
    String? description,
    int? fileGroupId,
  }) async {
    final fields = <String, String>{
      'name': name,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (fileGroupId != null) 'file_group_id': fileGroupId.toString(),
    };
    // No file parts; backend expects file_group_id reference only for project creation.
    final files = <String, http.MultipartFile>{};

    return _apiClient.uploadMultipart<Project>(
      ApiConstants.projects,
      fields: fields,
      files: files,
      fromJson: (obj) {
        if (obj['data'] is Map<String, dynamic>) {
          return Project.fromJson(obj['data'] as Map<String, dynamic>);
        }
        return Project.fromJson(obj);
      },
    );
  }
}
