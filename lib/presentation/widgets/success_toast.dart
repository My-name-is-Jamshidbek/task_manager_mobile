import 'package:flutter/material.dart';

enum ToastType { success, error, info }

class AppToast {
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration? duration,
  }) {
    _show(
      context,
      message: message,
      type: ToastType.success,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    Duration? duration,
  }) {
    _show(context, message: message, type: ToastType.error, duration: duration);
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    Duration? duration,
  }) {
    _show(context, message: message, type: ToastType.info, duration: duration);
  }

  static void _show(
    BuildContext context, {
    required String message,
    required ToastType type,
    Duration? duration,
  }) {
    IconData icon;
    Color backgroundColor;
    String title;

    switch (type) {
      case ToastType.success:
        icon = Icons.check_circle;
        backgroundColor = Colors.green;
        title = 'Success';
        break;
      case ToastType.error:
        icon = Icons.error;
        backgroundColor = Colors.red;
        title = 'Error';
        break;
      case ToastType.info:
        icon = Icons.info;
        backgroundColor = Colors.blue;
        title = 'Info';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? const Duration(seconds: 4),
      ),
    );
  }
}

// Backward compatibility
class SuccessToast {
  static void show(
    BuildContext context, {
    required String message,
    Duration? duration,
  }) {
    AppToast.showSuccess(context, message: message, duration: duration);
  }
}
