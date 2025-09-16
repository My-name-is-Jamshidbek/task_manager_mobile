import 'package:flutter/material.dart';
import '../utils/logger.dart';
import '../utils/navigation_service.dart';
import '../notifications/notification_templates.dart';
// import 'update_service.dart';
// import '../../presentation/widgets/update_dialogs.dart';
import '../../presentation/widgets/app_root.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Show in-app notification using SnackBar or custom overlay
  static void showInAppNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    Duration duration = const Duration(seconds: 4),
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      Logger.warning('⚠️ No context available for in-app notification');
      return;
    }

    Logger.info('📱 Showing in-app notification: $title');

    // Remove any existing snackbars
    ScaffoldMessenger.of(context).clearSnackBars();

    // Show custom notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(body, style: const TextStyle(fontSize: 14)),
          ],
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: data != null && data.isNotEmpty
            ? SnackBarAction(
                label: 'View',
                onPressed: () {
                  _handleNotificationTap(data);
                },
              )
            : null,
      ),
    );
  }

  /// Handle notification tap action
  static void _handleNotificationTap(Map<String, dynamic> data) {
    Logger.info('👆 Notification tapped raw data: $data');
    final parsed = parseNotificationTemplate(data);
    if (parsed == null) {
      Logger.warning(
        '⚠️ Cannot handle notification tap: unrecognized template',
      );
      return;
    }
    _navigateForTemplate(parsed);
  }

  /// Dispatch navigation based on parsed template.
  static void _navigateForTemplate(ParsedNotificationTemplate template) {
    Logger.info(
      '🧭 Navigating for template: ${template.type.value} -> ${template.screen}',
    );
    switch (template.screen) {
      case 'task_detail':
        _goToTaskDetail(template.vars['task_id']);
        break;
      case 'project_detail':
        _goToProjectDetail(template.vars['project_id']);
        break;
      case 'announcement':
        _goToAnnouncement(template.vars['announcement_id']);
        break;
      case 'update':
        _goToUpdateScreen(template.vars);
        break;
      default:
        Logger.warning(
          '⚠️ No navigation handler for screen: ${template.screen}',
        );
    }
  }

  // ---- Navigation helper stubs (to be implemented with real routes) ----
  static void _goToTaskDetail(String? taskId) {
    if (taskId == null) {
      Logger.warning('⚠️ Task detail navigation skipped: taskId null');
      return;
    }
    // TODO: Replace with Navigator push to task detail route
    Logger.info('🧭 (Stub) Navigate to Task Detail id=$taskId');
  }

  static void _goToProjectDetail(String? projectId) {
    if (projectId == null) {
      Logger.warning('⚠️ Project detail navigation skipped: projectId null');
      return;
    }
    Logger.info('🧭 (Stub) Navigate to Project Detail id=$projectId');
  }

  static void _goToAnnouncement(String? id) {
    Logger.info('🧭 (Stub) Navigate to Announcement id=${id ?? '(none)'}');
  }

  static Future<void> _goToUpdateScreen([Map<String, dynamic>? vars]) async {
    // Normalize common update keys from template vars for AppRoot
    Map<String, dynamic>? normalized = vars;
    if (vars != null && vars.isNotEmpty) {
      normalized = Map<String, dynamic>.from(vars);
      // If generic key names are present, map to what AppRootController expects
      // AppRootController expects: update_required|is_required, current_version, latest_version, title, description
      // From payload we may have version_name/code/build_number
      normalized['current_version'] ??= normalized['currentVersion'];
      normalized['latest_version'] ??=
          normalized['version_name'] ??
          normalized['code'] ??
          normalized['build_number'];
      // No-op if already provided
    }
    await AppRootController.recheckUpdates(normalized);
  }

  // Show custom dialog notification
  static void showDialogNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      Logger.warning('⚠️ No context available for dialog notification');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            if (data != null && data.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  NotificationService._handleNotificationTap(data);
                },
                child: const Text('View'),
              ),
          ],
        );
      },
    );
  }

  // Show custom banner notification
  static void showBannerNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    Duration duration = const Duration(seconds: 3),
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      Logger.warning('⚠️ No context available for banner notification');
      return;
    }

    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(body, style: const TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: const Text('Dismiss'),
          ),
          if (data != null && data.isNotEmpty)
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                NotificationService._handleNotificationTap(data);
              },
              child: const Text('View'),
            ),
        ],
      ),
    );

    Future.delayed(duration, () {
      if (navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(
          navigatorKey.currentContext!,
        ).hideCurrentMaterialBanner();
      }
    });
  }
}

// Moved outside state class: generic dialog notification helper
extension NotificationDialogs on NotificationService {
  static void showDialogNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      Logger.warning('⚠️ No context available for dialog notification');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            if (data != null && data.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  NotificationService._handleNotificationTap(data);
                },
                child: const Text('View'),
              ),
          ],
        );
      },
    );
  }

  static void showBannerNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    Duration duration = const Duration(seconds: 3),
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      Logger.warning('⚠️ No context available for banner notification');
      return;
    }

    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(body, style: const TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: const Text('Dismiss'),
          ),
          if (data != null && data.isNotEmpty)
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                NotificationService._handleNotificationTap(data);
              },
              child: const Text('View'),
            ),
        ],
      ),
    );

    Future.delayed(duration, () {
      if (navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(
          navigatorKey.currentContext!,
        ).hideCurrentMaterialBanner();
      }
    });
  }
}
