import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/models/api_task_models.dart';
import '../../data/models/task_action.dart';

class TaskActionHelper {
  static const int statusAccept = 0;
  static const int statusInProgress = 1;
  static const int statusCompleted = 2;
  static const int statusCheckedFinished = 3;
  static const int statusRejected = 4;
  static const int statusRejectedConfirmed = 5;

  static List<TaskActionKind> deriveActions(ApiTask task, int? currentUserId) {
    final isCreator =
        currentUserId != null && task.creator?.id == currentUserId;
    final isWorker =
        currentUserId != null &&
        task.workers.any((worker) => worker.id == currentUserId);
    final statusId = task.status?.id;

    final candidateActions = <TaskActionKind>{};

    for (final raw in task.availableActions) {
      final mapped = _mapAction(raw);
      if (mapped != null &&
          _isActionAllowed(
            mapped,
            isCreator: isCreator,
            isWorker: isWorker,
            statusId: statusId,
          )) {
        candidateActions.add(mapped);
      }
    }

    if (isWorker) {
      if (statusId == statusAccept) {
        candidateActions
          ..add(TaskActionKind.accept)
          ..add(TaskActionKind.reject);
      } else if (statusId == statusInProgress) {
        candidateActions
          ..add(TaskActionKind.complete)
          ..add(TaskActionKind.reject);
      } else if (statusId == statusRejected) {
        candidateActions.add(TaskActionKind.accept);
      }
    }

    if (isCreator) {
      if (statusId == statusCompleted) {
        candidateActions
          ..add(TaskActionKind.approveCompletion)
          ..add(TaskActionKind.rework);
      } else if (statusId == statusRejected) {
        candidateActions.add(TaskActionKind.rework);
      }
    }

    if (candidateActions.isEmpty && task.availableActions.isNotEmpty) {
      for (final raw in task.availableActions) {
        final mapped = _mapAction(raw);
        if (mapped != null) {
          candidateActions.add(mapped);
        }
      }
    }

    final sorted = candidateActions.toList()..sort(_actionComparator);
    return sorted;
  }

  static IconData iconForAction(TaskActionKind action) {
    switch (action) {
      case TaskActionKind.accept:
        return Icons.task_alt;
      case TaskActionKind.complete:
        return Icons.check_circle_outline;
      case TaskActionKind.reject:
        return Icons.cancel;
      case TaskActionKind.approveCompletion:
        return Icons.verified;
      case TaskActionKind.rework:
        return Icons.restart_alt;
    }
  }

  static ButtonStyle? buttonStyleForAction(
    ThemeData theme,
    TaskActionKind action,
  ) {
    switch (action) {
      case TaskActionKind.reject:
        return FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.error,
          foregroundColor: theme.colorScheme.onError,
        );
      case TaskActionKind.rework:
        return FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.secondaryContainer,
          foregroundColor: theme.colorScheme.onSecondaryContainer,
        );
      case TaskActionKind.approveCompletion:
        return FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
        );
      case TaskActionKind.accept:
      case TaskActionKind.complete:
        return null;
    }
  }

  static Color progressColor(ThemeData theme, TaskActionKind action) {
    switch (action) {
      case TaskActionKind.reject:
        return theme.colorScheme.onError;
      case TaskActionKind.rework:
        return theme.colorScheme.onSecondaryContainer;
      case TaskActionKind.approveCompletion:
        return theme.colorScheme.onPrimaryContainer;
      case TaskActionKind.accept:
      case TaskActionKind.complete:
        return theme.colorScheme.onPrimary;
    }
  }

  static Future<bool> confirmAction(
    BuildContext context,
    AppLocalizations loc,
    TaskActionKind action,
  ) async {
    final actionLabel = loc.translate(action.translationKey);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('tasks.actions.confirmTitle')),
        content: Text(
          loc.translateWithParams('tasks.actions.confirmMessage', {
            'action': actionLabel,
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.translate('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.translate('tasks.actions.proceed')),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<String?> promptForReason(
    BuildContext context,
    AppLocalizations loc,
    TaskActionKind action,
  ) async {
    final controller = TextEditingController();
    String? errorText;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(loc.translate(action.translationKey)),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: loc.translate('tasks.actions.reasonLabel'),
              hintText: loc.translate('tasks.actions.reasonHint'),
              errorText: errorText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(loc.translate('common.cancel')),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) {
                  setState(
                    () => errorText = loc.translate(
                      'tasks.actions.reasonRequired',
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop(text);
              },
              child: Text(loc.translate('tasks.actions.proceed')),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
  }

  static String buildSuccessMessage(
    AppLocalizations loc,
    TaskActionKind action,
  ) {
    return loc.translateWithParams('tasks.actions.successMessage', {
      'action': loc.translate(action.translationKey),
    });
  }

  static int _actionComparator(TaskActionKind a, TaskActionKind b) {
    return TaskActionKind.values.indexOf(a) - TaskActionKind.values.indexOf(b);
  }

  static TaskActionKind? _mapAction(String raw) {
    final normalized = _normalizeActionValue(raw);
    for (final action in TaskActionKind.values) {
      final nameMatch = _normalizeActionValue(action.name);
      final pathMatch = _normalizeActionValue(action.pathSegment);
      if (normalized == nameMatch || normalized == pathMatch) {
        return action;
      }
    }
    return null;
  }

  static bool _isActionAllowed(
    TaskActionKind action, {
    required bool isCreator,
    required bool isWorker,
    required int? statusId,
  }) {
    switch (action) {
      case TaskActionKind.accept:
        return isWorker &&
            (statusId == statusAccept || statusId == statusRejected);
      case TaskActionKind.complete:
        return isWorker && statusId == statusInProgress;
      case TaskActionKind.reject:
        return isWorker &&
            (statusId == statusAccept || statusId == statusInProgress);
      case TaskActionKind.approveCompletion:
        return isCreator && statusId == statusCompleted;
      case TaskActionKind.rework:
        return isCreator &&
            (statusId == statusCompleted || statusId == statusRejected);
    }
  }

  static String _normalizeActionValue(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
}
