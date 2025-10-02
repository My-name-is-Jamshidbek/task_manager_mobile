class UserStats {
  final int completedTasksCount;
  final int pendingTasksCount;
  final int totalProjectsCount;

  const UserStats({
    required this.completedTasksCount,
    required this.pendingTasksCount,
    required this.totalProjectsCount,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      completedTasksCount: (json['completed_tasks_count'] ?? 0) as int,
      pendingTasksCount: (json['pending_tasks_count'] ?? 0) as int,
      totalProjectsCount: (json['total_projects_count'] ?? 0) as int,
    );
  }
}

class ProjectStatusStat {
  final int statusId;
  final String statusKey;
  final String label;
  final int count;

  const ProjectStatusStat({
    required this.statusId,
    required this.statusKey,
    required this.label,
    required this.count,
  });

  factory ProjectStatusStat.fromJson(Map<String, dynamic> json) {
    return ProjectStatusStat(
      statusId: (json['status_id'] ?? 0) as int,
      statusKey: (json['status_key'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      count: (json['count'] ?? 0) as int,
    );
  }
}

class TaskStatusStat {
  final int statusId;
  final String statusKey;
  final String label;
  final int count;

  const TaskStatusStat({
    required this.statusId,
    required this.statusKey,
    required this.label,
    required this.count,
  });

  factory TaskStatusStat.fromJson(Map<String, dynamic> json) {
    return TaskStatusStat(
      statusId: (json['status_id'] ?? 0) as int,
      statusKey: (json['status_key'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      count: (json['count'] ?? 0) as int,
    );
  }
}
