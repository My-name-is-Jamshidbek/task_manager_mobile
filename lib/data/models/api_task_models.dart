import 'project_models.dart';

class ApiTaskStatusRef {
  final int id;
  final String? label;
  const ApiTaskStatusRef({required this.id, this.label});
  factory ApiTaskStatusRef.fromJson(Map<String, dynamic> json) =>
      ApiTaskStatusRef(
        id: json['id'] as int? ?? 0,
        label: json['label'] as String?,
      );
}

class ApiTaskTypeRef {
  final int id;
  final String? name;
  const ApiTaskTypeRef({required this.id, this.name});
  factory ApiTaskTypeRef.fromJson(Map<String, dynamic> json) => ApiTaskTypeRef(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String?,
  );
}

class ApiUserRef {
  final int id;
  final String? name;
  final String? phone;
  final String? avatarUrl;
  const ApiUserRef({required this.id, this.name, this.phone, this.avatarUrl});
  factory ApiUserRef.fromJson(Map<String, dynamic> json) => ApiUserRef(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String?,
    phone: json['phone'] as String?,
    avatarUrl: json['avatar_url'] as String?,
  );
}

class ApiTimeProgress {
  final String id;
  final String? label;
  const ApiTimeProgress({required this.id, this.label});
  factory ApiTimeProgress.fromJson(Map<String, dynamic> json) =>
      ApiTimeProgress(
        id: json['id']?.toString() ?? '',
        label: json['label'] as String?,
      );
}

class ApiProjectRef {
  final int id;
  final String name;
  final String? description;
  final int? status; // 1=active, etc.
  final String? statusLabel;
  const ApiProjectRef({
    required this.id,
    required this.name,
    this.description,
    this.status,
    this.statusLabel,
  });
  factory ApiProjectRef.fromJson(Map<String, dynamic> json) => ApiProjectRef(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    description: json['description'] as String?,
    status: (json['status'] as num?)?.toInt(),
    statusLabel: json['status_label'] as String?,
  );
}

class ApiTask {
  final int id;
  final String name;
  final String? description;
  final DateTime? deadline;
  final ApiTaskStatusRef? status;
  final ApiTaskTypeRef? taskType;
  final ApiProjectRef? project;
  final ApiUserRef? creator;
  final ApiTimeProgress? timeProgress;
  final List<ApiUserRef> workers;
  final List<FileAttachment> files;
  const ApiTask({
    required this.id,
    required this.name,
    this.description,
    this.deadline,
    this.status,
    this.taskType,
    this.project,
    this.creator,
    this.timeProgress,
    this.workers = const [],
    this.files = const [],
  });

  factory ApiTask.fromJson(Map<String, dynamic> json) => ApiTask(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    description: json['description'] as String?,
    deadline: json['deadline'] != null
        ? DateTime.tryParse(json['deadline'] as String)
        : null,
    status: json['status'] is Map<String, dynamic>
        ? ApiTaskStatusRef.fromJson(json['status'] as Map<String, dynamic>)
        : null,
    taskType: json['task_type'] is Map<String, dynamic>
        ? ApiTaskTypeRef.fromJson(json['task_type'] as Map<String, dynamic>)
        : null,
    project: json['project'] is Map<String, dynamic>
        ? ApiProjectRef.fromJson(json['project'] as Map<String, dynamic>)
        : null,
    creator: json['creator'] is Map<String, dynamic>
        ? ApiUserRef.fromJson(json['creator'] as Map<String, dynamic>)
        : null,
    timeProgress: json['time_progress'] is Map<String, dynamic>
        ? ApiTimeProgress.fromJson(
            json['time_progress'] as Map<String, dynamic>,
          )
        : null,
    workers: (json['workers'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ApiUserRef.fromJson)
        .toList(),
    files: (json['files'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(FileAttachment.fromJson)
        .toList(),
  );
}
