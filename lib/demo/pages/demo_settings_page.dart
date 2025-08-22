import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../widgets/demo_theme_settings.dart';
import '../widgets/demo_language_selector.dart';

/// CoreUI Demo Settings Page Widget
class DemoSettingsPage extends StatelessWidget {
  const DemoSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Page Title
        Text(
          localizations.translate('demo.settings'),
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        Text(
          localizations.translate('demo.settingsDescription'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 24),

        // Theme Settings Section
        const DemoSettingsSection(
          title: 'Theme Settings',
          icon: Icons.palette,
          child: DemoThemeSettingsContent(),
        ),

        const SizedBox(height: 24),

        // Language Settings Section
        const DemoSettingsSection(
          title: 'Language Settings',
          icon: Icons.language,
          child: DemoLanguageSettingsContent(),
        ),

        const SizedBox(height: 24),

        // Additional Settings Section
        DemoSettingsSection(
          title: localizations.translate('demo.additionalSettings'),
          icon: Icons.tune,
          child: const DemoAdditionalSettingsContent(),
        ),
      ],
    );
  }
}

/// CoreUI Demo Settings Section Widget
class DemoSettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const DemoSettingsSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// CoreUI Demo Theme Settings Content Widget
class DemoThemeSettingsContent extends StatelessWidget {
  const DemoThemeSettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        DemoThemeModeSelector(),
        SizedBox(height: 20),
        DemoThemeColorSelector(),
      ],
    );
  }
}

/// CoreUI Demo Language Settings Content Widget
class DemoLanguageSettingsContent extends StatelessWidget {
  const DemoLanguageSettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('demo.languageDescription'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        const DemoLanguageSelector(),
      ],
    );
  }
}

/// CoreUI Demo Additional Settings Content Widget
class DemoAdditionalSettingsContent extends StatelessWidget {
  const DemoAdditionalSettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.animation),
          title: Text(localizations.translate('demo.animations')),
          subtitle: Text(localizations.translate('demo.animationsDescription')),
          trailing: Switch(
            value: true,
            onChanged: (value) {
              // Handle animation toggle
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value ? 'Animations enabled' : 'Animations disabled',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          contentPadding: EdgeInsets.zero,
        ),

        const Divider(),

        ListTile(
          leading: const Icon(Icons.developer_mode),
          title: Text(localizations.translate('demo.developerMode')),
          subtitle: Text(
            localizations.translate('demo.developerModeDescription'),
          ),
          trailing: Switch(
            value: false,
            onChanged: (value) {
              // Handle developer mode toggle
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value
                        ? 'Developer mode enabled'
                        : 'Developer mode disabled',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          contentPadding: EdgeInsets.zero,
        ),

        const Divider(),

        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(localizations.translate('demo.about')),
          subtitle: Text(localizations.translate('demo.aboutDescription')),
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'CoreUI Demo',
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2025 CoreUI Demo App',
              children: [
                const SizedBox(height: 16),
                Text(localizations.translate('demo.aboutContent')),
              ],
            );
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
