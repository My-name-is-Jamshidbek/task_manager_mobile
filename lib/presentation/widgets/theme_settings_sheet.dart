import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_service.dart';
import '../../core/localization/app_localizations.dart';

/// Theme Settings Sheet Widget
class ThemeSettingsSheet extends StatelessWidget {
  const ThemeSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.translate('settings.themeSheet.title'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _ThemeModeSelector(),
            const SizedBox(height: 24),
            _ThemeColorSelector(),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('settings.themeSheet.mode'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...AppThemeMode.values.map(
          (mode) => RadioListTile<AppThemeMode>(
            title: Text(
              localizations.translate('settings.themeSheet.modes.${mode.name}'),
            ),
            value: mode,
            groupValue: themeService.themeMode,
            onChanged: (v) => themeService.setThemeMode(v!),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

class _ThemeColorSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('settings.themeSheet.primaryColor'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...AppThemeColor.values.map(
          (color) => RadioListTile<AppThemeColor>(
            title: Text(
              localizations.translate(
                'settings.themeSheet.colors.${color.name}.label',
              ),
            ),
            subtitle: Text(
              localizations.translate(
                'settings.themeSheet.colors.${color.name}.description',
              ),
            ),
            value: color,
            groupValue: themeService.themeColor,
            onChanged: (v) => themeService.setThemeColor(v!),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
