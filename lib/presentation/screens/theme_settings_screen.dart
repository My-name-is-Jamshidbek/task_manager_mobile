import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_service.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/constants/theme_constants.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('settings.theme')),
      ),
      body: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return ListView(
            padding: const EdgeInsets.all(AppThemeConstants.spaceLG),
            children: [
              // Theme Mode Section
              _buildSectionTitle(context, 'Theme Mode'),
              const SizedBox(height: AppThemeConstants.spaceMD),
              _buildThemeModeSelector(context, themeService),

              const SizedBox(height: AppThemeConstants.space3XL),

              // Theme Color Section
              _buildSectionTitle(context, 'Theme Color'),
              const SizedBox(height: AppThemeConstants.spaceMD),
              _buildThemeColorSelector(context, themeService),

              const SizedBox(height: AppThemeConstants.space3XL),

              // Preview Section
              _buildSectionTitle(context, 'Preview'),
              const SizedBox(height: AppThemeConstants.spaceMD),
              _buildThemePreview(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: AppThemeConstants.fontWeightSemiBold,
      ),
    );
  }

  Widget _buildThemeModeSelector(
    BuildContext context,
    ThemeService themeService,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppThemeConstants.spaceLG),
        child: Column(
          children: themeService.availableThemeModes.map((modeData) {
            final AppThemeMode mode = modeData['value'];
            final bool isSelected = themeService.themeMode == mode;

            return RadioListTile<AppThemeMode>(
              title: Row(
                children: [
                  Icon(
                    modeData['icon'],
                    size: AppThemeConstants.iconSizeMD,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppThemeConstants.spaceMD),
                  Text(modeData['name']),
                ],
              ),
              value: mode,
              groupValue: themeService.themeMode,
              onChanged: (AppThemeMode? value) {
                if (value != null) {
                  themeService.setThemeMode(value);
                }
              },
              activeColor: Theme.of(context).primaryColor,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildThemeColorSelector(
    BuildContext context,
    ThemeService themeService,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppThemeConstants.spaceLG),
        child: Column(
          children: [
            // Grid of color options
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: AppThemeConstants.spaceMD,
                mainAxisSpacing: AppThemeConstants.spaceMD,
                childAspectRatio: 1,
              ),
              itemCount: themeService.availableThemeColors.length,
              itemBuilder: (context, index) {
                final colorData = themeService.availableThemeColors[index];
                final AppThemeColor color = colorData['value'];
                final bool isSelected = themeService.themeColor == color;

                return GestureDetector(
                  onTap: () {
                    themeService.setThemeColor(color);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorData['color'],
                      borderRadius: BorderRadius.circular(
                        AppThemeConstants.radiusLG,
                      ),
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.onSurface,
                              width: 3,
                            )
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: AppThemeConstants.white,
                            size: AppThemeConstants.iconSizeLG,
                          )
                        : null,
                  ),
                );
              },
            ),

            const SizedBox(height: AppThemeConstants.spaceLG),

            // Selected color name
            Text(
              'Selected: ${themeService.availableThemeColors.firstWhere((colorData) => colorData['value'] == themeService.themeColor)['name']}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: AppThemeConstants.fontWeightMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemePreview(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppThemeConstants.spaceLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sample app bar
            Container(
              height: AppThemeConstants.appBarHeight,
              decoration: BoxDecoration(
                color: Theme.of(context).appBarTheme.backgroundColor,
                borderRadius: BorderRadius.circular(AppThemeConstants.radiusMD),
              ),
              child: Row(
                children: [
                  const SizedBox(width: AppThemeConstants.spaceLG),
                  Icon(
                    Icons.menu,
                    color: Theme.of(context).appBarTheme.foregroundColor,
                  ),
                  const SizedBox(width: AppThemeConstants.spaceLG),
                  Expanded(
                    child: Text(
                      'Task Manager',
                      style: Theme.of(context).appBarTheme.titleTextStyle,
                    ),
                  ),
                  Icon(
                    Icons.search,
                    color: Theme.of(context).appBarTheme.foregroundColor,
                  ),
                  const SizedBox(width: AppThemeConstants.spaceLG),
                ],
              ),
            ),

            const SizedBox(height: AppThemeConstants.spaceLG),

            // Sample content
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Primary Button'),
                  ),
                ),
                const SizedBox(width: AppThemeConstants.spaceMD),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Outlined Button'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppThemeConstants.spaceLG),

            // Sample text field
            TextField(
              decoration: const InputDecoration(
                labelText: 'Sample Input',
                hintText: 'Enter text here...',
                prefixIcon: Icon(Icons.edit),
              ),
            ),

            const SizedBox(height: AppThemeConstants.spaceLG),

            // Sample text styles
            Text(
              'Heading Large',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            Text(
              'This is body text that shows how the theme looks in practice.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Small caption text',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// Helper method for easy theme access
extension ThemeHelper on BuildContext {
  ThemeService get themeService =>
      Provider.of<ThemeService>(this, listen: false);
}
