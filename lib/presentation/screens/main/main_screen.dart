import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../widgets/language_selector.dart';
import '../../widgets/theme_settings_sheet.dart';
import '../../widgets/logout_confirmation_dialog.dart';
import '../../widgets/platform_version_widget.dart';
import '../settings/settings_screen.dart';
import 'home_screen.dart';
import 'tasks_screen.dart';
import 'projects_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  final Future<void> Function()? onLogout;

  const MainScreen({super.key, this.onLogout});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const TasksScreen(),
      const ProjectsScreen(),
      ProfileScreen(onLogout: widget.onLogout),
    ];
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_getScreenTitle(loc)),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Show search
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, loc, theme),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNavigationBar(loc, theme),
    );
  }

  String _getScreenTitle(AppLocalizations loc) {
    switch (_currentIndex) {
      case 0:
        return loc.translate('navigation.home');
      case 1:
        return loc.translate('navigation.tasks');
      case 2:
        return loc.translate('navigation.projects');
      case 3:
        return loc.translate('navigation.profile');
      default:
        return loc.translate('app.title');
    }
  }

  Widget _buildBottomNavigationBar(AppLocalizations loc, ThemeData theme) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      onTap: _onTabTapped,
      selectedItemColor: theme.colorScheme.primary,
      unselectedItemColor: theme.colorScheme.onSurfaceVariant,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home),
          label: loc.translate('navigation.home'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.task_outlined),
          activeIcon: const Icon(Icons.task),
          label: loc.translate('navigation.tasks'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.folder_outlined),
          activeIcon: const Icon(Icons.folder),
          label: loc.translate('navigation.projects'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          activeIcon: const Icon(Icons.person),
          label: loc.translate('navigation.profile'),
        ),
      ],
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.task_alt,
                  size: 48,
                  color: theme.colorScheme.onPrimary,
                ),
                const SizedBox(height: 8),
                Text(
                  loc.translate('app.title'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  loc.translate('app.version'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.home_outlined,
                  title: loc.translate('navigation.home'),
                  onTap: () {
                    Navigator.pop(context);
                    _onTabTapped(0);
                  },
                  isSelected: _currentIndex == 0,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.task_outlined,
                  title: loc.translate('navigation.tasks'),
                  onTap: () {
                    Navigator.pop(context);
                    _onTabTapped(1);
                  },
                  isSelected: _currentIndex == 1,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.folder_outlined,
                  title: loc.translate('navigation.projects'),
                  onTap: () {
                    Navigator.pop(context);
                    _onTabTapped(2);
                  },
                  isSelected: _currentIndex == 2,
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.person_outline,
                  title: loc.translate('navigation.profile'),
                  onTap: () {
                    Navigator.pop(context);
                    _onTabTapped(3);
                  },
                  isSelected: _currentIndex == 3,
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: loc.translate('navigation.settings'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.language,
                  title: loc.translate('settings.language'),
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => const LanguageSelector(),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.color_lens,
                  title: loc.translate('settings.theme'),
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => const ThemeSettingsSheet(),
                    );
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  title: loc.translate('auth.logout'),
                  onTap: () {
                    Navigator.pop(context);
                    LogoutConfirmationDialog.show(
                      context: context,
                      onConfirm: () async {
                        if (widget.onLogout != null) {
                          await widget.onLogout!();
                        }
                      },
                      onCancel: () {},
                    );
                  },
                  isDestructive: true,
                ),
                const SizedBox(height: 16),
                // Version Information
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: FullPlatformVersion(
                      textStyle: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.6,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final Color baseColor = isDestructive
        ? Colors.red
        : (isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant);

    return ListTile(
      leading: Icon(icon, color: baseColor),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive
              ? Colors.red
              : (isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface),
          fontWeight: isSelected ? FontWeight.w600 : null,
        ),
      ),
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
      trailing: isSelected
          ? Icon(Icons.check, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
