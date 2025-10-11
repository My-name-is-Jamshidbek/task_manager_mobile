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
  const WorkerUser({
    required this.id,
    required this.name,
    this.phone,
    this.avatarUrl,
    this.departments = const [],
  });
  factory WorkerUser.fromJson(Map<String, dynamic> json) => WorkerUser(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    phone: json['phone'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    departments: (json['departments'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(WorkerDepartment.fromJson)
        .toList(),
  );
}
