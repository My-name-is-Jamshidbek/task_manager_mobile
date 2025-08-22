import 'package:flutter/foundation.dart';
import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';

class TaskProvider extends ChangeNotifier {
  final TaskRepository _taskRepository;

  TaskProvider({required TaskRepository taskRepository})
    : _taskRepository = taskRepository;

  // Task lists
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];

  // Loading states
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isUpdating = false;
  bool _isDeleting = false;

  // Error handling
  String? _errorMessage;

  // Filters and sorting
  TaskStatus? _statusFilter;
  TaskPriority? _priorityFilter;
  String? _categoryFilter;
  String _searchQuery = '';
  TaskSortBy _sortBy = TaskSortBy.dueDate;
  bool _sortAscending = true;

  // Getters
  List<Task> get tasks => _filteredTasks;
  List<Task> get allTasks => _tasks;
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;
  TaskStatus? get statusFilter => _statusFilter;
  TaskPriority? get priorityFilter => _priorityFilter;
  String? get categoryFilter => _categoryFilter;
  String get searchQuery => _searchQuery;
  TaskSortBy get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  // Computed getters
  int get totalTasks => _tasks.length;
  int get completedTasks =>
      _tasks.where((task) => task.status == TaskStatus.completed).length;
  int get pendingTasks =>
      _tasks.where((task) => task.status == TaskStatus.pending).length;
  int get inProgressTasks =>
      _tasks.where((task) => task.status == TaskStatus.inProgress).length;
  int get overdueTasks {
    final now = DateTime.now();
    return _tasks
        .where(
          (task) =>
              task.dueDate != null &&
              task.dueDate!.isBefore(now) &&
              task.status != TaskStatus.completed,
        )
        .length;
  }

  // Load all tasks
  Future<void> loadTasks() async {
    _setLoading(true);
    _clearError();

    try {
      _tasks = await _taskRepository.getAllTasks();
      _applyFiltersAndSorting();
    } catch (e) {
      _setError('Failed to load tasks: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create a new task
  Future<bool> createTask(Task task) async {
    _setCreating(true);
    _clearError();

    try {
      final createdTask = await _taskRepository.createTask(task);
      _tasks.add(createdTask);
      _applyFiltersAndSorting();
      return true;
    } catch (e) {
      _setError('Failed to create task: $e');
      return false;
    } finally {
      _setCreating(false);
    }
  }

  // Update an existing task
  Future<bool> updateTask(Task task) async {
    _setUpdating(true);
    _clearError();

    try {
      final updatedTask = await _taskRepository.updateTask(task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        _applyFiltersAndSorting();
      }
      return true;
    } catch (e) {
      _setError('Failed to update task: $e');
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  // Delete a task
  Future<bool> deleteTask(String taskId) async {
    _setDeleting(true);
    _clearError();

    try {
      await _taskRepository.deleteTask(taskId);
      _tasks.removeWhere((task) => task.id == taskId);
      _applyFiltersAndSorting();
      return true;
    } catch (e) {
      _setError('Failed to delete task: $e');
      return false;
    } finally {
      _setDeleting(false);
    }
  }

  // Toggle task completion status
  Future<bool> toggleTaskStatus(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final newStatus = task.status == TaskStatus.completed
        ? TaskStatus.pending
        : TaskStatus.completed;

    final updatedTask = task.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );

    return await updateTask(updatedTask);
  }

  // Filter methods
  void setStatusFilter(TaskStatus? status) {
    _statusFilter = status;
    _applyFiltersAndSorting();
  }

  void setPriorityFilter(TaskPriority? priority) {
    _priorityFilter = priority;
    _applyFiltersAndSorting();
  }

  void setCategoryFilter(String? categoryId) {
    _categoryFilter = categoryId;
    _applyFiltersAndSorting();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersAndSorting();
  }

  void clearFilters() {
    _statusFilter = null;
    _priorityFilter = null;
    _categoryFilter = null;
    _searchQuery = '';
    _applyFiltersAndSorting();
  }

  // Sorting methods
  void setSortBy(TaskSortBy sortBy, {bool? ascending}) {
    _sortBy = sortBy;
    if (ascending != null) {
      _sortAscending = ascending;
    }
    _applyFiltersAndSorting();
  }

  void toggleSortOrder() {
    _sortAscending = !_sortAscending;
    _applyFiltersAndSorting();
  }

  // Apply filters and sorting
  void _applyFiltersAndSorting() {
    List<Task> filtered = List.from(_tasks);

    // Apply filters
    if (_statusFilter != null) {
      filtered = filtered
          .where((task) => task.status == _statusFilter)
          .toList();
    }

    if (_priorityFilter != null) {
      filtered = filtered
          .where((task) => task.priority == _priorityFilter)
          .toList();
    }

    if (_categoryFilter != null) {
      filtered = filtered
          .where((task) => task.categoryId == _categoryFilter)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (task) =>
                task.title.toLowerCase().contains(query) ||
                task.description.toLowerCase().contains(query),
          )
          .toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      int comparison = 0;

      switch (_sortBy) {
        case TaskSortBy.title:
          comparison = a.title.compareTo(b.title);
          break;
        case TaskSortBy.dueDate:
          if (a.dueDate == null && b.dueDate == null) {
            comparison = 0;
          } else if (a.dueDate == null) {
            comparison = 1;
          } else if (b.dueDate == null) {
            comparison = -1;
          } else {
            comparison = a.dueDate!.compareTo(b.dueDate!);
          }
          break;
        case TaskSortBy.priority:
          comparison = a.priority.value.compareTo(b.priority.value);
          break;
        case TaskSortBy.status:
          comparison = a.status.index.compareTo(b.status.index);
          break;
        case TaskSortBy.createdAt:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
      }

      return _sortAscending ? comparison : -comparison;
    });

    _filteredTasks = filtered;
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setCreating(bool creating) {
    _isCreating = creating;
    notifyListeners();
  }

  void _setUpdating(bool updating) {
    _isUpdating = updating;
    notifyListeners();
  }

  void _setDeleting(bool deleting) {
    _isDeleting = deleting;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Clear error message
  void clearError() {
    _clearError();
    notifyListeners();
  }
}

// Enum for sorting options
enum TaskSortBy { title, dueDate, priority, status, createdAt }
