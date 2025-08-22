import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_service.dart';
import 'core/constants/theme_constants.dart';
import 'presentation/screens/theme_settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize theme service
  final themeService = ThemeService();
  await themeService.initialize();

  runApp(ThemeDemo(themeService: themeService));
}

class ThemeDemo extends StatelessWidget {
  final ThemeService themeService;

  const ThemeDemo({super.key, required this.themeService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: themeService,
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'Multi-Theme Task Manager',
            debugShowCheckedModeBanner: false,

            // Use theme service for themes
            theme: themeService.lightTheme,
            darkTheme: themeService.darkTheme,
            themeMode: themeService.flutterThemeMode,

            home: const ThemeDemoHome(),
          );
        },
      ),
    );
  }
}

class ThemeDemoHome extends StatelessWidget {
  const ThemeDemoHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-Theme Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThemeSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppThemeConstants.spaceLG),
        children: [
          // Current theme info
          Consumer<ThemeService>(
            builder: (context, themeService, child) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppThemeConstants.spaceLG),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Theme',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppThemeConstants.spaceMD),
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: themeService.primaryColor,
                              borderRadius: BorderRadius.circular(
                                AppThemeConstants.radiusSM,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppThemeConstants.spaceMD),
                          Text(
                            'Color: ${themeService.themeColor.name.toUpperCase()}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppThemeConstants.spaceSM),
                      Text(
                        'Mode: ${themeService.themeMode.name.toUpperCase()}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: AppThemeConstants.spaceLG),

          // Quick theme switcher
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppThemeConstants.spaceLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Theme Switch',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppThemeConstants.spaceMD),

                  // Theme mode buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.read<ThemeService>().setThemeMode(
                              AppThemeMode.light,
                            );
                          },
                          icon: const Icon(Icons.light_mode),
                          label: const Text('Light'),
                        ),
                      ),
                      const SizedBox(width: AppThemeConstants.spaceMD),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.read<ThemeService>().setThemeMode(
                              AppThemeMode.dark,
                            );
                          },
                          icon: const Icon(Icons.dark_mode),
                          label: const Text('Dark'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppThemeConstants.spaceMD),

                  // Color picker
                  Wrap(
                    spacing: AppThemeConstants.spaceMD,
                    runSpacing: AppThemeConstants.spaceMD,
                    children: AppThemeColor.values.map((color) {
                      return Consumer<ThemeService>(
                        builder: (context, themeService, child) {
                          final colorData = themeService.availableThemeColors
                              .firstWhere((data) => data['value'] == color);

                          return GestureDetector(
                            onTap: () {
                              themeService.setThemeColor(color);
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colorData['color'],
                                borderRadius: BorderRadius.circular(
                                  AppThemeConstants.radiusLG,
                                ),
                                border: themeService.themeColor == color
                                    ? Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        width: 3,
                                      )
                                    : Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline,
                                        width: 1,
                                      ),
                              ),
                              child: themeService.themeColor == color
                                  ? const Icon(
                                      Icons.check,
                                      color: AppThemeConstants.white,
                                      size: AppThemeConstants.iconSizeMD,
                                    )
                                  : null,
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppThemeConstants.spaceLG),

          // Component showcase
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppThemeConstants.spaceLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Component Showcase',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppThemeConstants.spaceLG),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          child: const Text('Elevated'),
                        ),
                      ),
                      const SizedBox(width: AppThemeConstants.spaceMD),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          child: const Text('Outlined'),
                        ),
                      ),
                      const SizedBox(width: AppThemeConstants.spaceMD),
                      Expanded(
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Text'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppThemeConstants.spaceLG),

                  // Text field
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Sample Input',
                      hintText: 'Enter something...',
                      prefixIcon: Icon(Icons.edit),
                      suffixIcon: Icon(Icons.clear),
                    ),
                  ),

                  const SizedBox(height: AppThemeConstants.spaceLG),

                  // Typography showcase
                  Text(
                    'Display Large',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  Text(
                    'Headline Medium',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    'Title Large',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Body Large',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    'Body Medium',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Body Small',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Label Small',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This is a themed snackbar!')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
