/// Notification template definitions and parsing utilities.
///
/// Backend FCM data payload MUST include at minimum:
///   type: one of NotificationTemplateType values (e.g. task_assigned)
///   screen: destination screen identifier (e.g. task_detail)
///   vars: dynamic values required for the template (flat in data payload)
///
/// Example FCM data payload (data section):
/// {
///   "type": "task_assigned",
///   "screen": "task_detail",
///   "task_id": "123",
///   "task_title": "Prepare report",
///   "due_date": "2025-09-18T10:00:00Z"
/// }
///
/// The parsing layer validates required variables and exposes a structured
/// object to downstream navigation and UI.
library;

import '../utils/logger.dart';

/// Enum of supported notification template types.
/// Aligns with backend template keys.
enum NotificationTemplateType {
  taskAssigned('task_assigned'),
  taskUpdated('task_updated'),
  taskCommentAdded('task_comment_added'),
  taskCompleted('task_completed'),
  taskDueSoon('task_due_soon'),
  taskOverdue('task_overdue'),
  projectCreated('project_created'),
  projectStatusChanged('project_status_changed'),
  announcement('announcement'),
  appUpdate('app_update'),
  appUpdateAndroid('app_update_android'),
  appUpdateIos('app_update_ios');

  final String value;
  const NotificationTemplateType(this.value);

  static NotificationTemplateType? from(String? raw) {
    if (raw == null) return null;
    for (final t in NotificationTemplateType.values) {
      if (t.value == raw) return t;
    }
    return null;
  }
}

/// Contract describing required fields per template.
class _TemplateContract {
  final List<String> requiredVars;
  final String defaultScreen; // fallback screen if payload omits screen
  const _TemplateContract(this.requiredVars, this.defaultScreen);
}

const Map<NotificationTemplateType, _TemplateContract> _contracts = {
  NotificationTemplateType.taskAssigned: _TemplateContract([
    'task_id',
    'task_title',
    'due_date',
  ], 'task_detail'),
  NotificationTemplateType.taskUpdated: _TemplateContract([
    'task_id',
    'task_title',
    'updated_by',
    'changed_fields',
  ], 'task_detail'),
  NotificationTemplateType.taskCommentAdded: _TemplateContract([
    'task_id',
    'task_title',
    'author',
    'comment_id',
    'comment_preview',
  ], 'task_detail'),
  NotificationTemplateType.taskCompleted: _TemplateContract([
    'task_id',
    'task_title',
    'completed_by',
  ], 'task_detail'),
  NotificationTemplateType.taskDueSoon: _TemplateContract([
    'task_id',
    'task_title',
    'hours_left',
  ], 'task_detail'),
  NotificationTemplateType.taskOverdue: _TemplateContract([
    'task_id',
    'task_title',
    'hours_over',
  ], 'task_detail'),
  NotificationTemplateType.projectCreated: _TemplateContract([
    'project_id',
    'project_name',
  ], 'project_detail'),
  NotificationTemplateType.projectStatusChanged: _TemplateContract([
    'project_id',
    'project_name',
    'old_status',
    'new_status',
  ], 'project_detail'),
  NotificationTemplateType.announcement: _TemplateContract([
    'message',
  ], 'announcement'),
  // Generic update used by backend (accepts flexible fields)
  NotificationTemplateType.appUpdate: _TemplateContract([
    // We'll tolerate either of these being present, parse step will normalize
    // here we place a soft requirement by documenting but not failing hard
    // 'version_name',
  ], 'update'),
  NotificationTemplateType.appUpdateAndroid: _TemplateContract([
    'version_name',
    // Backend may send either 'version_code' or 'code'
    // We'll accept 'code' and normalize in vars
    // Keep 'version_code' for legacy
    'version_code',
  ], 'update'),
  NotificationTemplateType.appUpdateIos: _TemplateContract([
    'version_name',
    'build_number',
  ], 'update'),
};

/// Parsed notification template instance.
class ParsedNotificationTemplate {
  final NotificationTemplateType type;
  final String screen;
  final Map<String, String> vars; // normalized string map
  final List<String> missing;

  bool get isValid => missing.isEmpty;

  ParsedNotificationTemplate({
    required this.type,
    required this.screen,
    required this.vars,
    required this.missing,
  });

  @override
  String toString() =>
      'ParsedNotificationTemplate(type: ${type.value}, screen: $screen, missing: $missing, vars: $vars)';
}

/// Parse raw FCM data into a template structure.
ParsedNotificationTemplate? parseNotificationTemplate(
  Map<String, dynamic>? data,
) {
  if (data == null || data.isEmpty) return null;

  final rawType = data['type']?.toString();
  final type = NotificationTemplateType.from(rawType);
  if (type == null) {
    Logger.warning('🔔 Unknown notification type: $rawType');
    return null;
  }

  final contract = _contracts[type]!;
  final providedScreen = data['screen']?.toString();
  final screen = (providedScreen == null || providedScreen.isEmpty)
      ? contract.defaultScreen
      : providedScreen;

  final vars = <String, String>{};
  for (final entry in data.entries) {
    // Collect only simple scalar values (ignore nested objects for now)
    if (entry.value == null) continue;
    final v = entry.value;
    if (v is num || v is String || v is bool) {
      vars[entry.key] = v.toString();
    }
  }

  // Normalize flexible update payloads
  if (type == NotificationTemplateType.appUpdate ||
      type == NotificationTemplateType.appUpdateAndroid ||
      type == NotificationTemplateType.appUpdateIos) {
    // Map alternate keys to a consistent set
    // Prefer 'version_name' as display name
    if (!vars.containsKey('version_name') && vars.containsKey('name')) {
      vars['version_name'] = vars['name']!;
    }
    // Unify code/build fields from different platforms
    if (!vars.containsKey('version_code') && vars.containsKey('code')) {
      vars['version_code'] = vars['code']!;
    }
    if (!vars.containsKey('build_number') && vars.containsKey('code')) {
      vars['build_number'] = vars['code']!;
    }
    // Title/description mapping if provided
    if (!vars.containsKey('title') && vars.containsKey('update_title')) {
      vars['title'] = vars['update_title']!;
    }
    if (!vars.containsKey('description') &&
        vars.containsKey('update_description')) {
      vars['description'] = vars['update_description']!;
    }
  }

  // Determine missing required vars (soft for generic update)
  final missing = <String>[];
  for (final req in contract.requiredVars) {
    if (!vars.containsKey(req) || vars[req]!.isEmpty) missing.add(req);
  }

  final parsed = ParsedNotificationTemplate(
    type: type,
    screen: screen,
    vars: vars,
    missing: missing,
  );

  if (!parsed.isValid) {
    Logger.warning(
      '⚠️ Notification template missing required vars: ${parsed.missing} for type ${type.value}',
    );
  } else {
    Logger.info('🔔 Parsed notification template: $parsed');
  }

  return parsed;
}
