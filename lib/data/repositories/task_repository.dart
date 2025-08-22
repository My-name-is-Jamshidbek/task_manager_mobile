import '../models/task.dart';
import '../datasources/task_remote_datasource.dart';

abstract class TaskRepository {
  Future<List<Task>> getAllTasks();
  Future<Task> getTaskById(String id);
  Future<Task> createTask(Task task);
  Future<Task> updateTask(Task task);
  Future<void> deleteTask(String id);
  Future<List<Task>> getTasksByCategory(String categoryId);
  Future<List<Task>> getTasksByStatus(TaskStatus status);
  Future<List<Task>> searchTasks(String query);
}

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource _remoteDataSource;

  TaskRepositoryImpl({required TaskRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  @override
  Future<List<Task>> getAllTasks() async {
    try {
      return await _remoteDataSource.getAllTasks();
    } catch (e) {
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  @override
  Future<Task> getTaskById(String id) async {
    try {
      return await _remoteDataSource.getTaskById(id);
    } catch (e) {
      throw Exception('Failed to fetch task: $e');
    }
  }

  @override
  Future<Task> createTask(Task task) async {
    try {
      return await _remoteDataSource.createTask(task);
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  @override
  Future<Task> updateTask(Task task) async {
    try {
      return await _remoteDataSource.updateTask(task);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    try {
      await _remoteDataSource.deleteTask(id);
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  @override
  Future<List<Task>> getTasksByCategory(String categoryId) async {
    try {
      return await _remoteDataSource.getTasksByCategory(categoryId);
    } catch (e) {
      throw Exception('Failed to fetch tasks by category: $e');
    }
  }

  @override
  Future<List<Task>> getTasksByStatus(TaskStatus status) async {
    try {
      return await _remoteDataSource.getTasksByStatus(status);
    } catch (e) {
      throw Exception('Failed to fetch tasks by status: $e');
    }
  }

  @override
  Future<List<Task>> searchTasks(String query) async {
    try {
      return await _remoteDataSource.searchTasks(query);
    } catch (e) {
      throw Exception('Failed to search tasks: $e');
    }
  }
}
