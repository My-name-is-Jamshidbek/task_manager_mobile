class FileGroup {
  final int id;
  final String name;
  final List<FileAttachment> files;
  final DateTime createdAt;

  const FileGroup({
    required this.id,
    required this.name,
    this.files = const [],
    required this.createdAt,
  });

  factory FileGroup.fromJson(Map<String, dynamic> json) => FileGroup(
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    files:
        (json['files'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map((e) => FileAttachment.fromJson(e))
            .toList() ??
        const [],
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.now(),
  );
}

class FileAttachment {
  final String name;
  final String url;
  final int? id; // May be included in some contexts

  const FileAttachment({required this.name, required this.url, this.id});

  factory FileAttachment.fromJson(Map<String, dynamic> json) => FileAttachment(
    name: json['name'] as String? ?? '',
    url: json['url'] as String? ?? '',
    id: json['id'] as int?,
  );
}
