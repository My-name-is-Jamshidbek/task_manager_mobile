import 'package:flutter/material.dart';
import '../pages/demo_components_page.dart';
import '../pages/demo_colors_page.dart';
import '../pages/demo_typography_page.dart';
import '../pages/demo_settings_page.dart';
import '../widgets/demo_theme_settings.dart';
import '../widgets/language_settings_widget.dart';
import '../token_verification_demo.dart';

/// CoreUI Demo Navigation Widget
class DemoNavigation extends StatefulWidget {
  const DemoNavigation({super.key});

  @override
  State<DemoNavigation> createState() => _DemoNavigationState();
}

class _DemoNavigationState extends State<DemoNavigation>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isThemeChanging = false;

  List<DemoNavigationItem> get _navigationItems => [
    DemoNavigationItem(
      icon: Icons.widgets,
      label: 'Components',
      page: const DemoComponentsPage(),
    ),
    DemoNavigationItem(
      icon: Icons.color_lens,
      label: 'Colors',
      page: const DemoColorsPage(),
    ),
    DemoNavigationItem(
      icon: Icons.text_fields,
      label: 'Typography',
      page: const DemoTypographyPage(),
    ),
    DemoNavigationItem(
      icon: Icons.verified_user,
      label: 'Auth Test',
      page: const TokenVerificationDemo(),
    ),
    DemoNavigationItem(
      icon: Icons.settings,
      label: 'Settings',
      page: const DemoSettingsPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: ValueKey('demo_scaffold_$_isThemeChanging'),
      appBar: DemoAppBar(
        onThemeSettingsPressed: _showThemeSettings,
        isThemeChanging: _isThemeChanging,
      ),
      body: IndexedStack(
        key: ValueKey('indexed_stack_$_isThemeChanging'),
        index: _selectedIndex,
        children: _navigationItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Container(
            key: ValueKey('page_container_${index}_$_isThemeChanging'),
            child: item.page,
          );
        }).toList(),
      ),
      bottomNavigationBar: DemoBottomNavigationBar(
        selectedIndex: _selectedIndex,
        items: _navigationItems,
        onTap: _onItemTapped,
        isEnabled: !_isThemeChanging,
      ),
    );
  }

  void _onItemTapped(int index) {
    if (!_isThemeChanging && mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _showThemeSettings() {
    if (!_isThemeChanging && mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (BuildContext context) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(icon: Icon(Icons.palette), text: 'Theme'),
                      Tab(icon: Icon(Icons.language), text: 'Language'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        DemoThemeSettingsSheet(onThemeChanged: _onThemeChanged),
                        const LanguageSettingsWidget(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {
        _isThemeChanging = true;
      });

      // Allow theme to settle with shorter duration
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          setState(() {
            _isThemeChanging = false;
          });
        }
      });
    }
  }
}

/// CoreUI Demo App Bar Widget
class DemoAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onThemeSettingsPressed;
  final bool isThemeChanging;

  const DemoAppBar({
    super.key,
    this.onThemeSettingsPressed,
    this.isThemeChanging = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('CoreUI Theme Demo'),
      actions: [
        DemoThemeButton(
          onPressed: isThemeChanging ? null : onThemeSettingsPressed,
          isLoading: isThemeChanging,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// CoreUI Demo Theme Button Widget
class DemoThemeButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const DemoThemeButton({super.key, this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.settings),
      tooltip: 'Theme & Language Settings',
    );
  }
}

/// CoreUI Demo Bottom Navigation Bar Widget
class DemoBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final List<DemoNavigationItem> items;
  final ValueChanged<int> onTap;
  final bool isEnabled;

  const DemoBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: isEnabled ? onTap : null,
      items: items.map((item) => item.toBottomNavigationBarItem()).toList(),
    );
  }
}

/// CoreUI Demo Navigation Item Model
class DemoNavigationItem {
  final IconData icon;
  final String label;
  final Widget page;

  const DemoNavigationItem({
    required this.icon,
    required this.label,
    required this.page,
  });

  BottomNavigationBarItem toBottomNavigationBarItem() {
    return BottomNavigationBarItem(icon: Icon(icon), label: label);
  }
}

/// CoreUI Demo Drawer Widget (Alternative Navigation)
class DemoDrawer extends StatelessWidget {
  final int selectedIndex;
  final List<DemoNavigationItem> items;
  final ValueChanged<int> onTap;

  const DemoDrawer({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DemoDrawerHeader(),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return DemoDrawerItem(
              icon: item.icon,
              label: item.label,
              isSelected: index == selectedIndex,
              onTap: () {
                onTap(index);
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}

/// CoreUI Demo Drawer Header Widget
class DemoDrawerHeader extends StatelessWidget {
  const DemoDrawerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(color: Theme.of(context).primaryColor),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'CoreUI Demo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Theme System Showcase',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// CoreUI Demo Drawer Item Widget
class DemoDrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const DemoDrawerItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: isSelected,
      onTap: onTap,
    );
  }
}
