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
import 'chat_screen.dart';

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
      const ChatScreen(),
      ProfileScreen(onLogout: widget.onLogout),
    ];
  }

  void _onTabTapped(int index) {
    if (index > 2) {
      setState(() => _currentIndex = 4); 
    } else {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

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
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      drawer: _buildDrawer(context, loc),
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _currentIndex = 3; // ChatScreen index
          });
        },
        child: const Icon(Icons.chat_bubble_outline),
        elevation: 2.0,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, 
      bottomNavigationBar: _buildBottomAppBar(context, loc),
    );
  }

  String _getScreenTitle(AppLocalizations loc) {
    switch (_currentIndex) {
      case 0: return loc.translate('navigation.home');
      case 1: return loc.translate('navigation.tasks');
      case 2: return loc.translate('navigation.projects');
      case 3: return loc.translate('navigation.chat');
      case 4: return loc.translate('navigation.profile');
      default: return loc.translate('app.title');
    }
  }

  Widget _buildBottomAppBar(BuildContext context, AppLocalizations loc) {
    int bottomBarIndex = -1;
    if (_currentIndex < 3) {
        bottomBarIndex = _currentIndex;
    } else if (_currentIndex == 4) {
        bottomBarIndex = 3;
    }

    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround, 
        children: <Widget>[
          _buildBottomNavItem(
            context: context,
            icon: Icons.home_outlined,
            index: 0,
            isSelected: bottomBarIndex == 0,
          ),
          _buildBottomNavItem(
            context: context,
            icon: Icons.task_alt,
            index: 1,
            isSelected: bottomBarIndex == 1,
          ),
          _buildBottomNavItem(
            context: context,
            icon: Icons.folder_outlined,
            index: 2,
            isSelected: bottomBarIndex == 2,
          ),
          _buildBottomNavItem(
            context: context,
            icon: Icons.person_outline,
            index: 3, 
            isSelected: bottomBarIndex == 3,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem({
    required BuildContext context,
    required IconData icon,
    required int index,
    required bool isSelected,
  }) {
    final Color color = isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant;

    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: () => _onTabTapped(index),
      tooltip: 'Tooltip', // You can add dynamic tooltips here
    );
  }

  Widget _buildDrawer(BuildContext context, AppLocalizations loc) {
    final theme = Theme.of(context);
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
                Icon(Icons.task_alt, size: 48, color: theme.colorScheme.onPrimary),
                const SizedBox(height: 8),
                Text(loc.translate('app.title'), style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                Text(loc.translate('app.version'), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimary.withOpacity(0.8))),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(context, icon: Icons.home_outlined, title: loc.translate('navigation.home'), onTap: () { Navigator.pop(context); _onTabTapped(0); }, isSelected: _currentIndex == 0),
                _buildDrawerItem(context, icon: Icons.task_outlined, title: loc.translate('navigation.tasks'), onTap: () { Navigator.pop(context); _onTabTapped(1); }, isSelected: _currentIndex == 1),
                _buildDrawerItem(context, icon: Icons.folder_outlined, title: loc.translate('navigation.projects'), onTap: () { Navigator.pop(context); _onTabTapped(2); }, isSelected: _currentIndex == 2),
                _buildDrawerItem(context, icon: Icons.chat_outlined, title: loc.translate('navigation.chat'), onTap: () { Navigator.pop(context); setState(() => _currentIndex = 3); }, isSelected: _currentIndex == 3),
                _buildDrawerItem(context, icon: Icons.person_outline, title: loc.translate('navigation.profile'), onTap: () { Navigator.pop(context); _onTabTapped(4); }, isSelected: _currentIndex == 4),
                const Divider(),
                _buildDrawerItem(context, icon: Icons.settings_outlined, title: loc.translate('navigation.settings'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())); }),
                _buildDrawerItem(context, icon: Icons.language, title: loc.translate('settings.language'), onTap: () { Navigator.pop(context); showModalBottomSheet(context: context, builder: (_) => const LanguageSelector()); }),
                _buildDrawerItem(context, icon: Icons.color_lens, title: loc.translate('settings.theme'), onTap: () { Navigator.pop(context); showModalBottomSheet(context: context, builder: (_) => const ThemeSettingsSheet()); }),
                const Divider(),
                _buildDrawerItem(context, icon: Icons.logout, title: loc.translate('auth.logout'), onTap: () { Navigator.pop(context); LogoutConfirmationDialog.show(context: context, onConfirm: () async { if (widget.onLogout != null) { await widget.onLogout!(); } }, onCancel: () {}); }, isDestructive: true),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: FullPlatformVersion(
                      textStyle: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6)),
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

  Widget _buildDrawerItem(BuildContext context, { required IconData icon, required String title, required VoidCallback onTap, bool isSelected = false, bool isDestructive = false }) {
    final theme = Theme.of(context);
    final Color baseColor = isDestructive ? Colors.red : (isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant);

    return ListTile(
      leading: Icon(icon, color: baseColor),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : (isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface), fontWeight: isSelected ? FontWeight.w600 : null)),
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
      trailing: isSelected ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
      onTap: onTap,
    );
  }
}
