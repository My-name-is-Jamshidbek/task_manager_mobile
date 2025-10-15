import 'api_task_models.dart';

class ProjectTasksResult {
  final Map<String, int> counts;
  final Map<String, List<ApiTask>> lists;
  final List<ApiTask> items;
  final PaginationMeta? meta;

  const ProjectTasksResult({
    this.counts = const {},
    this.lists = const {},
    this.items = const [],
    this.meta,
  });

  factory ProjectTasksResult.fromResponse(Map<String, dynamic> payload) {
    final counts = <String, int>{};
    final lists = <String, List<ApiTask>>{};
    final items = <ApiTask>[];

    void mergeCounts(dynamic source) {
      if (source is Map<String, dynamic>) {
        for (final entry in source.entries) {
          final value = entry.value;
          int? parsed;
          if (value is num) {
            parsed = value.toInt();
          } else if (value is String) {
            parsed = int.tryParse(value);
          }
          if (parsed != null) {
            counts[entry.key] = parsed;
          }
        }
      }
    }

    void mergeLists(dynamic source) {
      if (source is Map<String, dynamic>) {
        for (final entry in source.entries) {
          final value = entry.value;
          if (value is List) {
            lists[entry.key] = value
                .whereType<Map<String, dynamic>>()
                .map(ApiTask.fromJson)
                .toList();
          }
        }
      }
    }

    void appendItems(dynamic source) {
      if (source is List) {
        items.addAll(
          source
              .whereType<Map<String, dynamic>>()
              .map(ApiTask.fromJson)
              .toList(),
        );
      }
    }

    mergeCounts(payload['counts']);
    mergeLists(payload['lists']);

    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      mergeCounts(data['counts']);
      mergeLists(data['lists']);
      appendItems(data['items']);
    } else if (data is List) {
      appendItems(data);
    }

    // Some responses wrap paginated items under data.data
    if (data is Map<String, dynamic> && data['data'] is List) {
      appendItems(data['data']);
    }

    final meta = payload['meta'] is Map<String, dynamic>
        ? PaginationMeta.fromJson(payload['meta'] as Map<String, dynamic>)
        : (data is Map<String, dynamic> && data['meta'] is Map<String, dynamic>)
        ? PaginationMeta.fromJson(data['meta'] as Map<String, dynamic>)
        : null;

    return ProjectTasksResult(
      counts: counts,
      lists: lists,
      items: items,
      meta: meta,
    );
  }
}

class PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    int parse(dynamic value, [int fallback = 0]) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    return PaginationMeta(
      currentPage: parse(json['current_page'], 1),
      lastPage: parse(json['last_page'], 1),
      perPage: parse(json['per_page'], 10),
      total: parse(json['total'], 0),
    );
  }
}
