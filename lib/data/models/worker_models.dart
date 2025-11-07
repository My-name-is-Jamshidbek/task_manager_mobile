class WorkerBoss {
  final int id;
  final String name;
  final String? avatarUrl;
  const WorkerBoss({required this.id, required this.name, this.avatarUrl});
  factory WorkerBoss.fromJson(Map<String, dynamic> json) => WorkerBoss(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: (json['name'] as String?) ?? '',
    avatarUrl: json['avatar_url'] as String?,
  );
}

class WorkerDepartment {
  final int id;
  final String name;
  final String? description;
  final WorkerBoss? boss; // API returns an object {id,name,avatar_url}
  final DateTime? createdAt;
  const WorkerDepartment({
    required this.id,
    required this.name,
    this.description,
    this.boss,
    this.createdAt,
  });
  factory WorkerDepartment.fromJson(Map<String, dynamic> json) {
    WorkerBoss? parsedBoss;
    final rawBoss = json['boss'];
    if (rawBoss is Map<String, dynamic>) {
      try {
        parsedBoss = WorkerBoss.fromJson(rawBoss);
      } catch (_) {
        parsedBoss = null;
      }
    }
    return WorkerDepartment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      boss: parsedBoss,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

class WorkerUser {
  final int id;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final List<WorkerDepartment> departments;
  final int? departmentUserId; // New: from department_user_id
  final int? statusCode; // New: 0=PENDING, 1=ACCEPTED, etc.
  final String? statusName; // New: PENDING, ACCEPTED, REJECTED
  final String? statusLabel; // New: Pending, Accepted, etc.
  final String? statusColor; // New: secondary, success, error, etc.
  final DateTime? assignedAt; // New: when assigned
  final DateTime? updatedAt; // New: last update

  const WorkerUser({
    required this.id,
    required this.name,
    this.phone,
    this.avatarUrl,
    this.departments = const [],
    this.departmentUserId,
    this.statusCode,
    this.statusName,
    this.statusLabel,
    this.statusColor,
    this.assignedAt,
    this.updatedAt,
  });

  factory WorkerUser.fromJson(Map<String, dynamic> json) {
    // Handle new API response format where user data is nested
    // New format: {id, department_user_id, user: {...}, status_code, status_name, ...}
    final userObj = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;

    return WorkerUser(
      id: userObj['id'] as int? ?? 0,
      name: userObj['name'] as String? ?? '',
      phone: userObj['phone'] as String?,
      avatarUrl: userObj['avatar_url'] as String?,
      departments: (json['departments'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(WorkerDepartment.fromJson)
          .toList(),
      departmentUserId: json['department_user_id'] as int?,
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
    );
  }
}
