import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../core/api/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/file_models.dart';

// File API endpoints
class FileApiConstants {
  static const fileGroups = '/file-groups';
  static const files = '/files';
}

class FileGroupRemoteDataSource {
  final ApiClient _apiClient;

  FileGroupRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Create a new empty file group
  Future<ApiResponse<FileGroup>> createFileGroup({required String name}) async {
    return _apiClient.post<FileGroup>(
      FileApiConstants.fileGroups,
      body: {'name': name},
      fromJson: (obj) {
        final map = (obj['data'] is Map<String, dynamic>)
            ? obj['data'] as Map<String, dynamic>
            : obj;
        return FileGroup.fromJson(map);
      },
    );
  }

  /// Get a file group with all its files by ID
  Future<ApiResponse<FileGroup>> getFileGroup(int fileGroupId) async {
    return _apiClient.get<FileGroup>(
      '${FileApiConstants.fileGroups}/$fileGroupId',
      fromJson: (obj) {
        final map = (obj['data'] is Map<String, dynamic>)
            ? obj['data'] as Map<String, dynamic>
            : obj;
        return FileGroup.fromJson(map);
      },
    );
  }

  /// Delete a file group with all its files
  Future<ApiResponse<void>> deleteFileGroup(int fileGroupId) async {
    return _apiClient.delete<void>(
      '${FileApiConstants.fileGroups}/$fileGroupId',
      fromJson: (_) {},
    );
  }

  /// Add a new file to an existing file group
  Future<ApiResponse<FileAttachment>> addFileToGroup({
    required int fileGroupId,
    required String fileName,
    required Uint8List fileBytes,
    String contentType = 'application/octet-stream',
  }) async {
    final multipartFile = http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
    );

    return _apiClient.uploadMultipart<FileAttachment>(
      '${FileApiConstants.fileGroups}/$fileGroupId/files',
      fields: {}, // Empty map for required parameter
      files: {'file': multipartFile},
      fromJson: (obj) {
        final map = (obj['data'] is Map<String, dynamic>)
            ? obj['data'] as Map<String, dynamic>
            : obj;
        return FileAttachment.fromJson(map);
      },
    );
  }

  /// Delete a single file
  Future<ApiResponse<void>> deleteFile(int fileId) async {
    return _apiClient.delete<void>(
      '${FileApiConstants.files}/$fileId',
      fromJson: (_) {},
    );
  }

  /// Get download URL for a file
  String getFileDownloadUrl(int fileId) {
    return '${ApiConstants.baseUrl}${FileApiConstants.files}/$fileId/download';
  }
}