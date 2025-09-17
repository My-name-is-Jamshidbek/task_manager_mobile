import 'package:flutter/foundation.dart';

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
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      creator: Creator.fromJson(json['creator'] as Map<String, dynamic>),
      taskStats: json['task_stats'] != null
          ? TaskStats.fromJson(json['task_stats'] as Map<String, dynamic>)
          : null,
      files: (json['files'] as List<dynamic>? ?? [])
          .map((e) => FileAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: _parseDateTime(json['created_at']),
      status: (json['status'] as num?)?.toInt(),
      statusLabel: json['status_label'] as String?,
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
    status: json['status'] as String,
    label: json['label'] as String?,
    count: (json['count'] as num).toInt(),
  );
}

@immutable
class FileAttachment {
  final String name;
  final String url;

  const FileAttachment({required this.name, required this.url});

  factory FileAttachment.fromJson(Map<String, dynamic> json) =>
      FileAttachment(name: json['name'] as String, url: json['url'] as String);
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
