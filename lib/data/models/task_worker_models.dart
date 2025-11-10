import 'file_models.dart';
import 'worker_models.dart';

/// Model for file/submission in task worker confirmations, reworks, or rejects
class TaskWorkerSubmission {
  final int id;
  final String? description;
  final int? fileGroupId;
  final List<FileAttachment> files;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TaskWorkerSubmission({
    required this.id,
    this.description,
    this.fileGroupId,
    this.files = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory TaskWorkerSubmission.fromJson(Map<String, dynamic> json) =>
      TaskWorkerSubmission(
        id: json['id'] as int? ?? 0,
        description: json['description'] as String?,
        fileGroupId: json['file_group_id'] as int?,
        files: (json['files'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(FileAttachment.fromJson)
            .toList(),
        createdAt: json['created_at'] is String
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] is String
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
      );
}

/// Complete task worker detail with all submissions
class TaskWorkerDetail {
  final int taskId;
  final int taskWorkerId;
  final int? departmentUserId;
  final WorkerUser user;
  final int? statusCode; // 0=PENDING, 1=ACCEPTED, 2=REWORK, 3=REJECTED
  final String? statusName; // PENDING, ACCEPTED, REWORK, REJECTED
  final String? statusLabel; // Pending, Accepted, Qayta ishlash, Rejected
  final String? statusColor; // secondary, success, warning, error
  final DateTime? assignedAt;
  final DateTime? updatedAt;
  final List<TaskWorkerSubmission> confirms;
  final List<TaskWorkerSubmission> reworks;
  final List<TaskWorkerSubmission> rejects;

  const TaskWorkerDetail({
    required this.taskId,
    required this.taskWorkerId,
    this.departmentUserId,
    required this.user,
    this.statusCode,
    this.statusName,
    this.statusLabel,
    this.statusColor,
    this.assignedAt,
    this.updatedAt,
    this.confirms = const [],
    this.reworks = const [],
    this.rejects = const [],
  });

  factory TaskWorkerDetail.fromJson(Map<String, dynamic> json) =>
      TaskWorkerDetail(
        taskId: json['task_id'] as int? ?? 0,
        taskWorkerId: json['task_worker_id'] as int? ?? 0,
        departmentUserId: json['department_user_id'] as int?,
        user: json['user'] is Map<String, dynamic>
            ? WorkerUser.fromJson(json['user'] as Map<String, dynamic>)
            : WorkerUser(id: 0, name: ''),
        statusCode: json['status_code'] as int?,
        statusName: json['status_name'] as String?,
        statusLabel: json['status_label'] as String?,
        statusColor: json['status_color'] as String?,
        assignedAt: json['assigned_at'] is String
            ? DateTime.tryParse(json['assigned_at'] as String)
            : null,
        updatedAt: json['updated_at'] is String
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
        confirms: (json['confirms'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(TaskWorkerSubmission.fromJson)
            .toList(),
        reworks: (json['reworks'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(TaskWorkerSubmission.fromJson)
            .toList(),
        rejects: (json['rejects'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(TaskWorkerSubmission.fromJson)
            .toList(),
      );
}
