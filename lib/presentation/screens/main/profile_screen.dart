import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/network_avatar.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/auth_debug_helper.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/logout_confirmation_dialog.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import '../debug/firebase_notification_debug_screen.dart';
import '../../providers/dashboard_provider.dart';
import '../theme_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Future<void> Function()? onLogout;

  const ProfileScreen({super.key, this.onLogout});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.loadUserProfile();
        // Also refresh stats
        await Provider.of<DashboardProvider>(context, listen: false).refresh();
        if (!success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      authProvider.error ?? 'Failed to refresh profile',
                    ),
                  ),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      },
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildProfileHeader(context, loc, theme),
              const SizedBox(height: 24),
              _buildStatsCards(context, theme),
              const SizedBox(height: 24),
              _buildProfileMenu(context, loc, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                NetworkAvatar(
                  imageUrl: user?.avatar,
                  size: 100,
                  initials: user?.name != null
                      ? _getInitials(user!.name!)
                      : null,
                  overlay: null,
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? loc.translate('profile.sampleUser.name'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.phone ??
                      user?.email ??
                      loc.translate('profile.sampleUser.email'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (user?.id != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${user!.id}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.7,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to get user initials
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0].substring(0, 1)}${parts[parts.length - 1].substring(0, 1)}'
        .toUpperCase();
  }

  Widget _buildStatsCards(BuildContext context, ThemeData theme) {
    final loc = AppLocalizations.of(context);
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        // Trigger initial load once when widget builds and no data yet
        if (provider.stats == null && !provider.isLoading) {
          // schedule microtask to avoid setState in build
          Future.microtask(() => provider.fetchUserStats());
        }

        if (provider.isLoading && provider.stats == null) {
          return Row(
            children: [
              Expanded(child: _buildLoadingStat(theme)),
              const SizedBox(width: 12),
              Expanded(child: _buildLoadingStat(theme)),
              const SizedBox(width: 12),
              Expanded(child: _buildLoadingStat(theme)),
            ],
          );
        }

        if (provider.error != null && provider.stats == null) {
          return _buildErrorStats(context, theme, provider.error!, () {
            provider.fetchUserStats();
          });
        }

        final stats = provider.stats;
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.task_alt,
                title: loc.translate('profile.completed'),
                count: (stats?.completedTasksCount ?? 0).toString(),
                color: Colors.green,
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.pending_actions,
                title: loc.translate('profile.pending'),
                count: (stats?.pendingTasksCount ?? 0).toString(),
                color: Colors.orange,
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.folder,
                title: loc.translate('profile.projects'),
                count: (stats?.totalProjectsCount ?? 0).toString(),
                color: Colors.blue,
                theme: theme,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingStat(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 22,
              width: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 14,
              width: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorStats(
    BuildContext context,
    ThemeData theme,
    String message,
    VoidCallback onRetry,
  ) {
    final loc = AppLocalizations.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(height: 8),
            Text(
              loc.translate('common.error'),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(loc.translate('common.retry')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String count,
    required Color color,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              count,
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenu(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildMenuItem(
            context,
            icon: Icons.person_outline,
            title: loc.translate('profile.editProfile'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
            theme: theme,
          ),
          _buildMenuItem(
            context,
            icon: Icons.lock_outline,
            title: loc.translate('profile.changePassword'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
            theme: theme,
          ),
          _buildMenuItem(
            context,
            icon: Icons.notifications_outlined,
            title: loc.translate('settings.notifications'),
            onTap: () {
              // Navigate to Firebase notification debug page
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FirebaseNotificationDebugScreen(),
                ),
              );
            },
            theme: theme,
          ),
          _buildMenuItem(
            context,
            icon: Icons.security_outlined,
            title: loc.translate('settings.privacy'),
            onTap: () {
              // TODO: Navigate to privacy settings
            },
            theme: theme,
          ),
          _buildMenuItem(
            context,
            icon: Icons.language_outlined,
            title: loc.translate('settings.language'),
            onTap: () {
              // TODO: Navigate to language settings
            },
            theme: theme,
          ),
          _buildMenuItem(
            context,
            icon: Icons.color_lens_outlined,
            title: loc.translate('settings.theme'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ThemeSettingsScreen(),
                ),
              );
            },
            theme: theme,
          ),
          _buildMenuItem(
            context,
            icon: Icons.help_outline,
            title: loc.translate('settings.about'),
            onTap: () {
              // TODO: Navigate to about/help
            },
            theme: theme,
          ),
          // Debug section for authentication testing
          _buildMenuItem(
            context,
            icon: Icons.bug_report_outlined,
            title: 'Debug: Check Auth Data',
            onTap: () async {
              await AuthDebugHelper.printStoredAuthData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Auth data logged to console - check debug output',
                    ),
                    backgroundColor: Colors.blue,
                  ),
                );
              }
            },
            theme: theme,
          ),
          _buildMenuItem(
            context,
            icon: Icons.storage_outlined,
            title: 'Debug: Test SharedPreferences',
            onTap: () async {
              await AuthDebugHelper.testSharedPreferences();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'SharedPreferences test completed - check console',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            theme: theme,
          ),
          _buildMenuItem(
            context,
            icon: Icons.person_pin_outlined,
            title: 'Debug: Load Profile from API',
            onTap: () async {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final success = await authProvider.loadUserProfile();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Profile loaded successfully from API'
                          : 'Failed to load profile: ${authProvider.error}',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            theme: theme,
          ),
          _buildMenuItem(
            context,
            icon: Icons.logout,
            title: loc.translate('auth.logout'),
            onTap: () {
              LogoutConfirmationDialog.show(
                context: context,
                onConfirm: () async {
                  if (onLogout != null) {
                    await onLogout!();
                  }
                },
                onCancel: () {},
              );
            },
            theme: theme,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ThemeData theme,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : theme.colorScheme.onSurface;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
