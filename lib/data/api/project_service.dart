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
    List<String>? fileIds,
  }) async {
    final fields = <String, String>{
      'name': name,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    };

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
        if (obj['data'] is Map<String, dynamic>) {
          return Project.fromJson(obj['data'] as Map<String, dynamic>);
        }
        return Project.fromJson(obj);
      },
    );
  }
}
