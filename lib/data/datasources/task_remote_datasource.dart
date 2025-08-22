import '../models/task.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/api_constants.dart';

abstract class TaskRemoteDataSource {
  Future<List<Task>> getAllTasks();
  Future<Task> getTaskById(String id);
  Future<Task> createTask(Task task);
  Future<Task> updateTask(Task task);
  Future<void> deleteTask(String id);
  Future<List<Task>> getTasksByCategory(String categoryId);
  Future<List<Task>> getTasksByStatus(TaskStatus status);
  Future<List<Task>> searchTasks(String query);
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final ApiClient _apiClient;

  TaskRemoteDataSourceImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  @override
  Future<List<Task>> getAllTasks() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.tasks,
    );

    if (response.isSuccess && response.data != null) {
      final List<dynamic> tasksJson = response.data!['data'] ?? [];
      return tasksJson.map((json) => Task.fromJson(json)).toList();
    } else {
      throw Exception(response.error ?? 'Failed to fetch tasks');
    }
  }

  @override
  Future<Task> getTaskById(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${ApiConstants.taskById}/$id',
    );

    if (response.isSuccess && response.data != null) {
      return Task.fromJson(response.data!['data']);
    } else {
      throw Exception(response.error ?? 'Failed to fetch task');
    }
  }

  @override
  Future<Task> createTask(Task task) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.createTask,
      body: task.toJson(),
    );

    if (response.isSuccess && response.data != null) {
      return Task.fromJson(response.data!['data']);
    } else {
      throw Exception(response.error ?? 'Failed to create task');
    }
  }

  @override
  Future<Task> updateTask(Task task) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '${ApiConstants.updateTask}/${task.id}',
      body: task.toJson(),
    );

    if (response.isSuccess && response.data != null) {
      return Task.fromJson(response.data!['data']);
    } else {
      throw Exception(response.error ?? 'Failed to update task');
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    final response = await _apiClient.delete<Map<String, dynamic>>(
      '${ApiConstants.deleteTask}/$id',
    );

    if (!response.isSuccess) {
      throw Exception(response.error ?? 'Failed to delete task');
    }
  }

  @override
  Future<List<Task>> getTasksByCategory(String categoryId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.tasks,
      queryParams: {'categoryId': categoryId},
    );

    if (response.isSuccess && response.data != null) {
      final List<dynamic> tasksJson = response.data!['data'] ?? [];
      return tasksJson.map((json) => Task.fromJson(json)).toList();
    } else {
      throw Exception(response.error ?? 'Failed to fetch tasks by category');
    }
  }

  @override
  Future<List<Task>> getTasksByStatus(TaskStatus status) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.tasks,
      queryParams: {'status': status.name},
    );

    if (response.isSuccess && response.data != null) {
      final List<dynamic> tasksJson = response.data!['data'] ?? [];
      return tasksJson.map((json) => Task.fromJson(json)).toList();
    } else {
      throw Exception(response.error ?? 'Failed to fetch tasks by status');
    }
  }

  @override
  Future<List<Task>> searchTasks(String query) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiConstants.tasks,
      queryParams: {'search': query},
    );

    if (response.isSuccess && response.data != null) {
      final List<dynamic> tasksJson = response.data!['data'] ?? [];
      return tasksJson.map((json) => Task.fromJson(json)).toList();
    } else {
      throw Exception(response.error ?? 'Failed to search tasks');
    }
  }
}
