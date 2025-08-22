import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_service.dart';
import 'core/constants/theme_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final themeService = ThemeService();
  await themeService.initialize();
  
  runApp(CoreUIDemo(themeService: themeService));
}

class CoreUIDemo extends StatelessWidget {
  final ThemeService themeService;

  const CoreUIDemo({super.key, required this.themeService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: themeService,
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'CoreUI Theme Demo',
            theme: themeService.lightTheme,
            darkTheme: themeService.darkTheme,
            themeMode: themeService.flutterThemeMode,
            home: const CoreUIHomePage(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class CoreUIHomePage extends StatefulWidget {
  const CoreUIHomePage({super.key});

  @override
  State<CoreUIHomePage> createState() => _CoreUIHomePageState();
}

class _CoreUIHomePageState extends State<CoreUIHomePage> 
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isThemeChanging = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CoreUI Theme Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette),
            onPressed: _isThemeChanging ? null : () => _showThemeSettings(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          ColorsPage(),
          ComponentsPage(),
          TypographyPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (!_isThemeChanging) {
            setState(() => _selectedIndex = index);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.color_lens),
            label: 'Colors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.widgets),
            label: 'Components',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.text_fields),
            label: 'Typography',
          ),
        ],
      ),
      floatingActionButton: _isThemeChanging ? null : FloatingActionButton(
        onPressed: () => _showThemeSettings(context),
        child: const Icon(Icons.settings),
      ),
    );
  }

  void _showThemeSettings(BuildContext context) {
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ThemeSettingsSheet(
        onThemeChange: () {
          if (mounted) {
            setState(() => _isThemeChanging = true);
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() => _isThemeChanging = false);
              }
            });
          }
        },
      ),
    );
  }
}

class ColorsPage extends StatelessWidget {
  const ColorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('CoreUI Brand Colors', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        
        // Primary Colors
        const Text('Brand Colors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ColorCard('Primary', AppThemeConstants.primary, '#5856d6'),
            _ColorCard('Secondary', AppThemeConstants.secondary, '#6b7785'),
            _ColorCard('Success', AppThemeConstants.success, '#1b9e3e'),
            _ColorCard('Danger', AppThemeConstants.danger, '#e55353'),
            _ColorCard('Warning', AppThemeConstants.warning, '#f9b115'),
            _ColorCard('Info', AppThemeConstants.info, '#3399ff'),
            _ColorCard('Light', AppThemeConstants.light, '#f3f4f7'),
            _ColorCard('Dark', AppThemeConstants.dark, '#212631'),
          ],
        ),
        
        const SizedBox(height: 24),
        const Text('Gray Scale', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ColorCard('Gray 100', AppThemeConstants.gray100, '#f8f9fa'),
            _ColorCard('Gray 200', AppThemeConstants.gray200, '#e9ecef'),
            _ColorCard('Gray 300', AppThemeConstants.gray300, '#dee2e6'),
            _ColorCard('Gray 400', AppThemeConstants.gray400, '#ced4da'),
            _ColorCard('Gray 500', AppThemeConstants.gray500, '#adb5bd'),
            _ColorCard('Gray 600', AppThemeConstants.gray600, '#6c757d'),
            _ColorCard('Gray 700', AppThemeConstants.gray700, '#495057'),
            _ColorCard('Gray 800', AppThemeConstants.gray800, '#343a40'),
            _ColorCard('Gray 900', AppThemeConstants.gray900, '#212529'),
          ],
        ),
        
        const SizedBox(height: 24),
        const Text('Status Colors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ColorCard('Priority Low', AppThemeConstants.priorityLow, 'Success Green'),
            _ColorCard('Priority Medium', AppThemeConstants.priorityMedium, 'Warning Yellow'),
            _ColorCard('Priority High', AppThemeConstants.priorityHigh, 'Danger Red'),
            _ColorCard('Priority Urgent', AppThemeConstants.priorityUrgent, 'Primary Purple'),
          ],
        ),
      ],
    );
  }
}

class _ColorCard extends StatelessWidget {
  final String name;
  final Color color;
  final String hex;

  const _ColorCard(this.name, this.color, this.hex);

  @override
  Widget build(BuildContext context) {
    final isLight = color.computeLuminance() > 0.5;
    
    return Container(
      width: 160,
      height: 100,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: TextStyle(
                color: isLight ? Colors.black87 : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            Text(
              hex,
              style: TextStyle(
                color: isLight ? Colors.black54 : Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ComponentsPage extends StatefulWidget {
  const ComponentsPage({super.key});

  @override
  State<ComponentsPage> createState() => _ComponentsPageState();
}

class _ComponentsPageState extends State<ComponentsPage> {
  late String _pageId;

  @override
  void initState() {
    super.initState();
    _pageId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) return const SizedBox.shrink();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('CoreUI Components', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        
        // Buttons
        const Text('Buttons', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(
              key: ValueKey('primary_button_$_pageId'),
              onPressed: mounted ? () {} : null, 
              child: const Text('Primary'),
            ),
            OutlinedButton(
              key: ValueKey('outlined_button_$_pageId'),
              onPressed: mounted ? () {} : null, 
              child: const Text('Outlined'),
            ),
            TextButton(
              key: ValueKey('text_button_$_pageId'),
              onPressed: mounted ? () {} : null, 
              child: const Text('Text'),
            ),
            ElevatedButton.icon(
              key: ValueKey('icon_button_$_pageId'),
              onPressed: mounted ? () {} : null,
              icon: const Icon(Icons.check),
              label: const Text('With Icon'),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        const Text('Cards', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Card(
          key: ValueKey('sample_card_$_pageId'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sample Card', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('This is a sample card using CoreUI design system with proper spacing and typography.'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      key: ValueKey('card_action_button_$_pageId'),
                      onPressed: mounted ? () {} : null, 
                      child: const Text('Action'),
                    ),
                    TextButton(
                      key: ValueKey('card_cancel_button_$_pageId'),
                      onPressed: mounted ? () {} : null, 
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        const Text('Form Elements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (mounted) ...[
          TextField(
            key: ValueKey('email_field_$_pageId'),
            decoration: const InputDecoration(
              labelText: 'Sample Input',
              hintText: 'Enter some text',
              prefixIcon: Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: ValueKey('password_field_$_pageId'),
            decoration: const InputDecoration(
              labelText: 'Password',
              hintText: 'Enter password',
              prefixIcon: Icon(Icons.lock),
              suffixIcon: Icon(Icons.visibility),
            ),
            obscureText: true,
          ),
        ],
        
        const SizedBox(height: 24),
        const Text('List Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Card(
          key: ValueKey('list_card_$_pageId'),
          child: Column(
            children: [
              ListTile(
                key: ValueKey('list_item_1_$_pageId'),
                leading: const Icon(Icons.task_alt),
                title: const Text('Complete project'),
                subtitle: const Text('Due tomorrow'),
                trailing: Chip(
                  key: ValueKey('high_chip_$_pageId'),
                  label: const Text('High'),
                  backgroundColor: AppThemeConstants.priorityHigh.withOpacity(0.1),
                  labelStyle: TextStyle(color: AppThemeConstants.priorityHigh),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                key: ValueKey('list_item_2_$_pageId'),
                leading: const Icon(Icons.meeting_room),
                title: const Text('Team meeting'),
                subtitle: const Text('Due today'),
                trailing: Chip(
                  key: ValueKey('medium_chip_$_pageId'),
                  label: const Text('Medium'),
                  backgroundColor: AppThemeConstants.priorityMedium.withOpacity(0.1),
                  labelStyle: TextStyle(color: AppThemeConstants.priorityMedium),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TypographyPage extends StatelessWidget {
  const TypographyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('CoreUI Typography', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        
        // Display Styles
        const Text('Display Styles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Display Large', style: theme.textTheme.displayLarge),
        Text('Display Medium', style: theme.textTheme.displayMedium),
        Text('Display Small', style: theme.textTheme.displaySmall),
        
        const SizedBox(height: 24),
        const Text('Headlines', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Headline Large', style: theme.textTheme.headlineLarge),
        Text('Headline Medium', style: theme.textTheme.headlineMedium),
        Text('Headline Small', style: theme.textTheme.headlineSmall),
        
        const SizedBox(height: 24),
        const Text('Titles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Title Large', style: theme.textTheme.titleLarge),
        Text('Title Medium', style: theme.textTheme.titleMedium),
        Text('Title Small', style: theme.textTheme.titleSmall),
        
        const SizedBox(height: 24),
        const Text('Body Text', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Body Large - This is a sample text to demonstrate the body large typography style from CoreUI design system.', style: theme.textTheme.bodyLarge),
        const SizedBox(height: 8),
        Text('Body Medium - This is a sample text to demonstrate the body medium typography style from CoreUI design system.', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        Text('Body Small - This is a sample text to demonstrate the body small typography style from CoreUI design system.', style: theme.textTheme.bodySmall),
        
        const SizedBox(height: 24),
        const Text('Labels', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Label Large', style: theme.textTheme.labelLarge),
        Text('Label Medium', style: theme.textTheme.labelMedium),
        Text('Label Small', style: theme.textTheme.labelSmall),
        
        const SizedBox(height: 24),
        const Text('Font Weights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Light (300)', style: TextStyle(fontWeight: FontWeight.w300)),
        const Text('Regular (400)', style: TextStyle(fontWeight: FontWeight.w400)),
        const Text('Medium (500)', style: TextStyle(fontWeight: FontWeight.w500)),
        const Text('Semi-bold (600)', style: TextStyle(fontWeight: FontWeight.w600)),
        const Text('Bold (700)', style: TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class ThemeSettingsSheet extends StatelessWidget {
  final VoidCallback? onThemeChange;
  
  const ThemeSettingsSheet({super.key, this.onThemeChange});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Theme Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          const Text('Theme Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: themeService.availableThemeModes.map((mode) {
              final isSelected = themeService.themeMode == mode['value'];
              return ChoiceChip(
                key: ValueKey('theme_mode_${mode['value'].toString()}'),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(mode['icon'], size: 16),
                    const SizedBox(width: 4),
                    Text(mode['name']),
                  ],
                ),
                selected: isSelected,
                onSelected: (_) async {
                  if (!isSelected) {
                    onThemeChange?.call();
                    await themeService.setThemeMode(mode['value']);
                  }
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          const Text('Theme Color', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: themeService.availableThemeColors.map((colorData) {
              final isSelected = themeService.themeColor == colorData['value'];
              return GestureDetector(
                key: ValueKey('theme_color_${colorData['value'].toString()}'),
                onTap: () async {
                  if (!isSelected) {
                    onThemeChange?.call();
                    await themeService.setThemeColor(colorData['value']);
                  }
                },
                child: Container(
                  width: 80,
                  height: 60,
                  decoration: BoxDecoration(
                    color: colorData['color'],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isSelected)
                        const Icon(Icons.check, color: Colors.white, size: 16),
                      const SizedBox(height: 2),
                      Text(
                        colorData['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Theme', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Mode: ${themeService.currentThemeModeName}'),
                  Text('Color: ${themeService.currentThemeName}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
