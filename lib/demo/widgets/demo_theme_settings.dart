import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_service.dart';

/// CoreUI Theme Settings Sheet Widget
class DemoThemeSettingsSheet extends StatelessWidget {
  final VoidCallback? onThemeChanged;

  const DemoThemeSettingsSheet({super.key, this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DemoThemeSettingsTitle(),
            SizedBox(height: 24),
            DemoThemeModeSelector(),
            SizedBox(height: 24),
            DemoThemeColorSelector(),
          ],
        ),
      ),
    );
  }
}

/// CoreUI Theme Settings Title Widget
class DemoThemeSettingsTitle extends StatelessWidget {
  const DemoThemeSettingsTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Theme Settings',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }
}

/// CoreUI Theme Mode Selector Widget
class DemoThemeModeSelector extends StatelessWidget {
  const DemoThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Theme Mode',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Consumer<ThemeService>(
          builder: (context, themeService, _) {
            final modes = [
              {'label': 'Light', 'value': AppThemeMode.light},
              {'label': 'Dark', 'value': AppThemeMode.dark},
              {'label': 'System', 'value': AppThemeMode.system},
            ];

            return Column(
              children: modes.map((mode) {
                return DemoThemeModeOption(
                  label: mode['label'] as String,
                  value: mode['value'] as AppThemeMode,
                  groupValue: themeService.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      themeService.setThemeMode(value);
                    }
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

/// CoreUI Theme Mode Option Widget
class DemoThemeModeOption extends StatelessWidget {
  final String label;
  final AppThemeMode value;
  final AppThemeMode groupValue;
  final ValueChanged<AppThemeMode?> onChanged;

  const DemoThemeModeOption({
    super.key,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<AppThemeMode>(
      key: ValueKey('theme_mode_${value.toString()}'),
      title: Text(label),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}

/// CoreUI Theme Color Selector Widget
class DemoThemeColorSelector extends StatelessWidget {
  const DemoThemeColorSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Primary Color',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Consumer<ThemeService>(
          builder: (context, themeService, _) {
            final colors = [
              {
                'label': 'CoreUI Primary',
                'value': AppThemeColor.primary,
                'description': 'Classic CoreUI Purple',
              },
              {
                'label': 'CoreUI Secondary',
                'value': AppThemeColor.secondary,
                'description': 'Professional Gray',
              },
              {
                'label': 'CoreUI Success',
                'value': AppThemeColor.success,
                'description': 'Fresh Green',
              },
              {
                'label': 'CoreUI Danger',
                'value': AppThemeColor.danger,
                'description': 'Alert Red',
              },
              {
                'label': 'CoreUI Warning',
                'value': AppThemeColor.warning,
                'description': 'Attention Orange',
              },
              {
                'label': 'CoreUI Info',
                'value': AppThemeColor.info,
                'description': 'Informative Blue',
              },
            ];

            return Column(
              children: colors.map((colorData) {
                return DemoThemeColorOption(
                  label: colorData['label'] as String,
                  description: colorData['description'] as String,
                  value: colorData['value'] as AppThemeColor,
                  groupValue: themeService.themeColor,
                  onChanged: (value) {
                    if (value != null) {
                      themeService.setThemeColor(value);
                    }
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

/// CoreUI Theme Color Option Widget
class DemoThemeColorOption extends StatelessWidget {
  final String label;
  final String description;
  final AppThemeColor value;
  final AppThemeColor groupValue;
  final ValueChanged<AppThemeColor?> onChanged;

  const DemoThemeColorOption({
    super.key,
    required this.label,
    required this.description,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final previewColor = _getColorPreview(themeService, value);

    return RadioListTile<AppThemeColor>(
      key: ValueKey('theme_color_${value.toString()}'),
      title: Text(label),
      subtitle: Text(description),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      secondary: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: previewColor,
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
    );
  }

  Color _getColorPreview(ThemeService themeService, AppThemeColor colorType) {
    switch (colorType) {
      case AppThemeColor.primary:
        return const Color(0xFF5856D6);
      case AppThemeColor.secondary:
        return const Color(0xFF6B7785);
      case AppThemeColor.success:
        return const Color(0xFF1B9E3E);
      case AppThemeColor.danger:
        return const Color(0xFFE55353);
      case AppThemeColor.warning:
        return const Color(0xFFF9B115);
      case AppThemeColor.info:
        return const Color(0xFF3399FF);
    }
  }
}

/// CoreUI Theme Settings Action Buttons Widget
class DemoThemeSettingsActions extends StatelessWidget {
  final VoidCallback? onClose;
  final VoidCallback? onReset;

  const DemoThemeSettingsActions({super.key, this.onClose, this.onReset});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onReset != null)
          TextButton(
            onPressed: onReset,
            child: Text(
              'Reset',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(inherit: true),
            ),
          ),
        const SizedBox(width: 8),
        if (onClose != null)
          ElevatedButton(
            onPressed: onClose,
            child: Text(
              'Done',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(inherit: true),
            ),
          ),
      ],
    );
  }
}
