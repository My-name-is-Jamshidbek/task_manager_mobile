import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
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
    );
  }

  Widget _buildProfileHeader(BuildContext context, AppLocalizations loc, ThemeData theme) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.person,
                size: 50,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'John Doe', // TODO: Get from user data
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'john.doe@example.com', // TODO: Get from user data
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () {
                // TODO: Navigate to edit profile
              },
              child: Text(loc.translate('profile.editProfile')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.task_alt,
            title: 'Completed',
            count: '45',
            color: Colors.green,
            theme: theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.pending_actions,
            title: 'Pending',
            count: '12',
            color: Colors.orange,
            theme: theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.folder,
            title: 'Projects',
            count: '8',
            color: Colors.blue,
            theme: theme,
          ),
        ),
      ],
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
            Icon(
              icon,
              size: 32,
              color: color,
            ),
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

  Widget _buildProfileMenu(BuildContext context, AppLocalizations loc, ThemeData theme) {
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
              // TODO: Navigate to edit profile
            },
            theme: theme,
          ),
          _buildMenuItem(
            context,
            icon: Icons.notifications_outlined,
            title: loc.translate('settings.notifications'),
            onTap: () {
              // TODO: Navigate to notifications settings
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
              // TODO: Navigate to theme settings
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
          _buildMenuItem(
            context,
            icon: Icons.logout,
            title: loc.translate('auth.logout'),
            onTap: () {
              // TODO: Show logout confirmation
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
      leading: Icon(
        icon,
        color: color,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}
