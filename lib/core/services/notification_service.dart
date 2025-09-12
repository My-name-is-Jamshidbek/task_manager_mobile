import 'package:flutter/material.dart';
import '../utils/logger.dart';
import '../utils/navigation_service.dart';

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
    final context = navigatorKey.currentContext;
    if (context == null) return;

    Logger.info('👆 Notification tapped with data: $data');

    // Handle different notification types based on data
    if (data.containsKey('screen')) {
      final screen = data['screen'];
      final taskId = data['task_id'];

      switch (screen) {
        case 'task_detail':
          if (taskId != null) {
            // Navigate to task detail
            // You'll implement this based on your routing system
            Logger.info('🧭 Navigating to task detail: $taskId');
          }
          break;
        case 'tasks':
          // Navigate to tasks list
          Logger.info('🧭 Navigating to tasks list');
          break;
        default:
          Logger.info('🏠 Unknown screen in notification data');
      }
    }
  }

  /// Show custom dialog notification
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
            if (data != null && data.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _handleNotificationTap(data);
                },
                child: const Text('View'),
              ),
          ],
        );
      },
    );
  }

  /// Show custom banner notification
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
                _handleNotificationTap(data);
              },
              child: const Text('View'),
            ),
        ],
      ),
    );

    // Auto-hide after duration
    Future.delayed(duration, () {
      if (navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(
          navigatorKey.currentContext!,
        ).hideCurrentMaterialBanner();
      }
    });
  }
}
