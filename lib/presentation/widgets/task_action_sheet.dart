import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../data/datasources/tasks_api_remote_datasource.dart';
import '../../data/models/api_task_models.dart';
import '../../data/models/task_action.dart';
import '../utils/task_action_helper.dart';

class TaskActionSheetResult {
  final TaskActionKind action;
  final ApiTask? updatedTask;

  const TaskActionSheetResult({required this.action, this.updatedTask});
}

class TaskActionSheet extends StatefulWidget {
  final ApiTask task;
  final int? currentUserId;
  final List<TaskActionKind> initialActions;

  const TaskActionSheet({
    super.key,
    required this.task,
    required this.currentUserId,
    required this.initialActions,
  });

  static Future<TaskActionSheetResult?> show(
    BuildContext context, {
    required ApiTask task,
    required int? currentUserId,
    List<TaskActionKind>? presetActions,
  }) {
    final actions =
        presetActions ?? TaskActionHelper.deriveActions(task, currentUserId);
    return showModalBottomSheet<TaskActionSheetResult>(
      context: context,
      isScrollControlled: false,
      builder: (_) => TaskActionSheet(
        task: task,
        currentUserId: currentUserId,
        initialActions: actions,
      ),
    );
  }

  @override
  State<TaskActionSheet> createState() => _TaskActionSheetState();
}

class _TaskActionSheetState extends State<TaskActionSheet> {
  late final TasksApiRemoteDataSource _remote;
  late List<TaskActionKind> _availableActions;
  TaskActionKind? _busyAction;
  String? _error;

  @override
  void initState() {
    super.initState();
    _remote = TasksApiRemoteDataSource();
    _availableActions = List<TaskActionKind>.from(widget.initialActions);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              loc.translate('tasks.actions.title'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_availableActions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  loc.translate('tasks.actions.noAvailable'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ..._availableActions.map(
                (action) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildActionButton(theme, loc, action),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    ThemeData theme,
    AppLocalizations loc,
    TaskActionKind action,
  ) {
    final busy = _busyAction == action;
    final style = TaskActionHelper.buttonStyleForAction(theme, action);
    final icon = TaskActionHelper.iconForAction(action);
    final label = loc.translate(action.translationKey);
    return FilledButton(
      style: style,
      onPressed: busy ? null : () => _onActionPressed(loc, action),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: TaskActionHelper.progressColor(theme, action),
              ),
            )
          else
            Icon(icon, size: 18),
          const SizedBox(width: 8),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Future<void> _onActionPressed(
    AppLocalizations loc,
    TaskActionKind action,
  ) async {
    if (!mounted) return;

    String? reason;
    if (action.requiresReason) {
      reason = await TaskActionHelper.promptForReason(context, loc, action);
      if (!mounted || reason == null) return;
    } else {
      final confirmed = await TaskActionHelper.confirmAction(
        context,
        loc,
        action,
      );
      if (!mounted || !confirmed) return;
    }

    setState(() {
      _busyAction = action;
      _error = null;
    });

    final response = await _remote.performTaskAction(
      taskId: widget.task.id,
      action: action,
      reason: reason,
    );

    if (!mounted) return;

    if (response.isSuccess) {
      ApiTask? refreshed = response.data;
      if (refreshed == null) {
        final reload = await _remote.getTaskById(widget.task.id);
        if (!mounted) return;
        if (reload.isSuccess) {
          refreshed = reload.data;
        }
      }
      if (!mounted) return;
      Navigator.of(
        context,
      ).pop(TaskActionSheetResult(action: action, updatedTask: refreshed));
      return;
    }

    setState(() {
      _busyAction = null;
      _error = response.error ?? loc.translate('tasks.actions.genericError');
    });
  }
}
