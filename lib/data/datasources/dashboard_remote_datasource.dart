import '../../core/api/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/dashboard_models.dart';

class DashboardRemoteDataSource {
  final ApiClient _api;
  DashboardRemoteDataSource({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  Future<UserStats> getUserStats() async {
    final res = await _api.get<Map<String, dynamic>>(ApiConstants.userStats);

    if (res.isSuccess && res.data != null) {
      // API returns plain object with counts
      final Map<String, dynamic> map = res.data!;
      return UserStats.fromJson(map);
    }
    throw Exception(res.error ?? 'Failed to fetch user stats');
  }

  Future<List<ProjectStatusStat>> getProjectStatsByStatus() async {
    final res = await _api.get<Map<String, dynamic>>(
      ApiConstants.projectStatsByStatus,
    );

    if (res.isSuccess && res.data != null) {
      // API returns { data: [ {status_id, status_key, label, count}, ... ] }
      final data = res.data!['data'];
      if (data is List) {
        return data
            .map((e) => ProjectStatusStat.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      // If backend returns raw list fallback
      if (res.data is List) {
        final list = (res.data as List)
            .map((e) => ProjectStatusStat.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
      return const <ProjectStatusStat>[];
    }
    throw Exception(res.error ?? 'Failed to fetch project stats');
  }

  Future<List<TaskStatusStat>> getTaskStatsByStatus() async {
    final res = await _api.get<List<TaskStatusStat>>(
      ApiConstants.taskStatsByStatus,
      fromJsonList: (json) => json
          .map((e) => TaskStatusStat.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

    if (res.isSuccess && res.data != null) {
      return res.data!;
    }
    throw Exception(res.error ?? 'Failed to fetch task stats');
  }
}
