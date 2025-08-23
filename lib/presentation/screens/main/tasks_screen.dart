import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        children: [
          _buildFilterChips(context, loc, theme),
          Expanded(
            child: _buildTasksList(context, loc, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, AppLocalizations loc, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(context, loc.translate('tasks.all'), true, theme),
            const SizedBox(width: 8),
            _buildFilterChip(context, loc.translate('status.pending'), false, theme),
            const SizedBox(width: 8),
            _buildFilterChip(context, loc.translate('status.inProgress'), false, theme),
            const SizedBox(width: 8),
            _buildFilterChip(context, loc.translate('status.completed'), false, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, bool isSelected, ThemeData theme) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (value) {
        // TODO: Filter tasks
      },
      selectedColor: theme.colorScheme.primary.withOpacity(0.2),
      checkmarkColor: theme.colorScheme.primary,
    );
  }

  Widget _buildTasksList(BuildContext context, AppLocalizations loc, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 10, // Mock data
      itemBuilder: (context, index) {
        return _buildTaskCard(context, index, theme, loc);
      },
    );
  }

  Widget _buildTaskCard(BuildContext context, int index, ThemeData theme, AppLocalizations loc) {
    final priorities = ['high', 'medium', 'low'];
    final priority = priorities[index % 3];
    final isCompleted = index % 4 == 0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to task detail
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: isCompleted,
                    onChanged: (value) {
                      // TODO: Toggle task completion
                    },
                  ),
                  Expanded(
                    child: Text(
                      '${loc.translate('tasks.title')} ${index + 1}: ${loc.translate('tasks.sampleTaskTitle')}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted ? theme.colorScheme.onSurfaceVariant : null,
                      ),
                    ),
                  ),
                  _buildPriorityChip(priority, theme, loc),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                loc.translate('tasks.sampleTaskDescription'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${loc.translate('tasks.due')}: Dec ${index + 15}, 2024',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.folder_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    loc.translate('tasks.sampleProjectName'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority, ThemeData theme, AppLocalizations loc) {
    Color color;
    String displayText;
    
    switch (priority) {
      case 'high':
        color = Colors.red;
        displayText = loc.translate('priority.highChip');
        break;
      case 'medium':
        color = Colors.orange;
        displayText = loc.translate('priority.mediumChip');
        break;
      case 'low':
        color = Colors.green;
        displayText = loc.translate('priority.lowChip');
        break;
      default:
        color = theme.colorScheme.primary;
        displayText = priority.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        displayText,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
