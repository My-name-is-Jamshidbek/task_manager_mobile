import 'package:flutter/foundation.dart';
import 'api_task_models.dart';

@immutable
class Project {
  final int id;
  final String name;
  final String? description;
  final Creator creator;
  final TaskStats? taskStats;
  final List<FileAttachment> files;
  final DateTime createdAt;
  final int? status; // 1=active,2=completed,3=expired,4=rejected
  final String? statusLabel; // optional label from API
  final int? fileGroupId; // ID of the file group

  const Project({
    required this.id,
    required this.name,
    required this.description,
    required this.creator,
    required this.taskStats,
    required this.files,
    required this.createdAt,
    required this.status,
    required this.statusLabel,
    this.fileGroupId,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    // Some endpoints (e.g., create project) return a slim payload
    // without nested 'creator' or 'files'. Provide robust fallbacks.
    final dynamic creatorRaw = json['creator'];
    Creator fallbackCreator = const Creator(
      id: 0,
      name: 'Unknown',
      phone: null,
      avatarUrl: null,
    );
    Creator parsedCreator;
    if (creatorRaw is Map<String, dynamic>) {
      try {
        parsedCreator = Creator.fromJson(creatorRaw);
      } catch (_) {
        parsedCreator = fallbackCreator;
      }
    } else {
      parsedCreator = fallbackCreator;
    }

    final filesRaw = json['files'];
    List<FileAttachment> parsedFiles = [];
    if (filesRaw is List) {
      parsedFiles = filesRaw.whereType<Map<String, dynamic>>().map((e) {
        try {
          return FileAttachment.fromJson(e);
        } catch (_) {
          return const FileAttachment(name: 'file', url: '');
        }
      }).toList();
    }

    return Project(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      description: json['description'] as String?,
      creator: parsedCreator,
      taskStats: json['task_stats'] != null
          ? TaskStats.fromJson(json['task_stats'] as Map<String, dynamic>)
          : null,
      files: parsedFiles,
      createdAt: _parseDateTime(json['created_at']),
      status: (json['status'] as num?)?.toInt(),
      statusLabel: json['status_label'] as String?,
      fileGroupId: _parseFileGroupId(json['file_group_id']),
    );
  }
}

/// Extended view model when backend embeds tasks inside project detail response.
@immutable
class ProjectWithTasks extends Project {
  final List<ApiTask> tasks;
  const ProjectWithTasks({
    required super.id,
    required super.name,
    required super.description,
    required super.creator,
    required super.taskStats,
    required super.files,
    required super.createdAt,
    required super.status,
    required super.statusLabel,
    super.fileGroupId,
    this.tasks = const [],
  }) : super();

  factory ProjectWithTasks.fromJson(Map<String, dynamic> json) {
    final base = Project.fromJson(json);
    final tasksRaw = json['tasks'];
    List<ApiTask> parsedTasks = [];
    if (tasksRaw is List) {
      parsedTasks = tasksRaw
          .whereType<Map<String, dynamic>>()
          .map((e) {
            try {
              return ApiTask.fromJson(e);
            } catch (_) {
              return const ApiTask(id: 0, name: '');
            }
          })
          .where((t) => t.id != 0)
          .toList();
    }
    return ProjectWithTasks(
      id: base.id,
      name: base.name,
      description: base.description,
      creator: base.creator,
      taskStats: base.taskStats,
      files: base.files,
      createdAt: base.createdAt,
      status: base.status,
      statusLabel: base.statusLabel,
      fileGroupId: base.fileGroupId,
      tasks: parsedTasks,
    );
  }
}

@immutable
class Creator {
  final int id;
  final String name;
  final String? phone;
  final String? avatarUrl;

  const Creator({
    required this.id,
    required this.name,
    required this.phone,
    required this.avatarUrl,
  });

  factory Creator.fromJson(Map<String, dynamic> json) => Creator(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    phone: json['phone'] as String?,
    avatarUrl: json['avatar_url'] as String?,
  );
}

@immutable
class TaskStats {
  final int total;
  final List<ByStatus> byStatus;

  const TaskStats({required this.total, required this.byStatus});

  factory TaskStats.fromJson(Map<String, dynamic> json) => TaskStats(
    total: (json['total'] as num).toInt(),
    byStatus: (json['by_status'] as List<dynamic>? ?? [])
        .map((e) => ByStatus.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

@immutable
class ByStatus {
  final String status;
  final String? label;
  final int count;

  const ByStatus({
    required this.status,
    required this.label,
    required this.count,
  });

  factory ByStatus.fromJson(Map<String, dynamic> json) => ByStatus(
    status: (json['status'])?.toString() ?? '',
    label: json['label'] as String?,
    count: (json['count'] as num).toInt(),
  );
}

@immutable
class FileAttachment {
  final String name;
  final String url;
  final int? id;

  const FileAttachment({required this.name, required this.url, this.id});

  factory FileAttachment.fromJson(Map<String, dynamic> json) => FileAttachment(
    name: json['name'] as String? ?? '',
    url: json['url'] as String? ?? '',
    id: json['id'] as int?,
  );
}

DateTime _parseDateTime(dynamic v) {
  if (v is String) {
    // API sample uses 'YYYY-MM-DD HH:mm:ss'
    // Attempt to parse ISO first; if fails, replace space with 'T'
    try {
      return DateTime.parse(v);
    } catch (_) {
      try {
        return DateTime.parse(v.replaceFirst(' ', 'T'));
      } catch (_) {
        // Fallback to now when parsing fails
        return DateTime.now();
      }
    }
  }
  return DateTime.now();
}

int? _parseFileGroupId(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  if (v is String) {
    final parsed = int.tryParse(v);
    return parsed;
  }
  return null;
}
