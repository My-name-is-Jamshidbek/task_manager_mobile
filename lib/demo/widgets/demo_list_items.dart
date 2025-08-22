import 'package:flutter/material.dart';
import '../../core/constants/theme_constants.dart';

/// CoreUI Demo List Items Section Widget
class DemoListItems extends StatelessWidget {
  final String pageId;
  final bool isEnabled;

  const DemoListItems({super.key, required this.pageId, this.isEnabled = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'List Items',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DemoListCard(pageId: pageId, isEnabled: isEnabled),
      ],
    );
  }
}

/// CoreUI List Card Container Widget
class DemoListCard extends StatelessWidget {
  final String pageId;
  final bool isEnabled;

  const DemoListCard({super.key, required this.pageId, this.isEnabled = true});

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('list_card_$pageId'),
      child: Column(
        children: [
          DemoTaskListItem(pageId: pageId, isEnabled: isEnabled),
          const Divider(height: 1),
          DemoMeetingListItem(pageId: pageId, isEnabled: isEnabled),
        ],
      ),
    );
  }
}

/// CoreUI Task List Item Widget
class DemoTaskListItem extends StatelessWidget {
  final String pageId;
  final bool isEnabled;

  const DemoTaskListItem({
    super.key,
    required this.pageId,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('list_item_1_$pageId'),
      enabled: isEnabled,
      leading: const Icon(Icons.task_alt),
      title: const Text('Complete project'),
      subtitle: const Text('Due tomorrow'),
      trailing: DemoPriorityChip(
        pageId: pageId,
        label: 'High',
        priority: PriorityLevel.high,
      ),
    );
  }
}

/// CoreUI Meeting List Item Widget
class DemoMeetingListItem extends StatelessWidget {
  final String pageId;
  final bool isEnabled;

  const DemoMeetingListItem({
    super.key,
    required this.pageId,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('list_item_2_$pageId'),
      enabled: isEnabled,
      leading: const Icon(Icons.meeting_room),
      title: const Text('Team meeting'),
      subtitle: const Text('Due today'),
      trailing: DemoPriorityChip(
        pageId: pageId,
        label: 'Medium',
        priority: PriorityLevel.medium,
      ),
    );
  }
}

/// Priority levels for demonstration
enum PriorityLevel { high, medium, low }

/// CoreUI Priority Chip Widget
class DemoPriorityChip extends StatelessWidget {
  final String pageId;
  final String label;
  final PriorityLevel priority;

  const DemoPriorityChip({
    super.key,
    required this.pageId,
    required this.label,
    required this.priority,
  });

  Color get _priorityColor {
    switch (priority) {
      case PriorityLevel.high:
        return AppThemeConstants.priorityHigh;
      case PriorityLevel.medium:
        return AppThemeConstants.priorityMedium;
      case PriorityLevel.low:
        return AppThemeConstants.priorityLow;
    }
  }

  String get _chipKey {
    switch (priority) {
      case PriorityLevel.high:
        return 'high_chip_$pageId';
      case PriorityLevel.medium:
        return 'medium_chip_$pageId';
      case PriorityLevel.low:
        return 'low_chip_$pageId';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      key: ValueKey(_chipKey),
      label: Text(label),
      backgroundColor: _priorityColor.withOpacity(0.1),
      labelStyle: TextStyle(color: _priorityColor),
    );
  }
}

/// CoreUI Simple List Item Widget
class DemoSimpleListItem extends StatelessWidget {
  final String pageId;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isEnabled;

  const DemoSimpleListItem({
    super.key,
    required this.pageId,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey(
        'simple_list_item_${title.toLowerCase().replaceAll(' ', '_')}_$pageId',
      ),
      enabled: isEnabled,
      leading: icon != null ? Icon(icon) : null,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
