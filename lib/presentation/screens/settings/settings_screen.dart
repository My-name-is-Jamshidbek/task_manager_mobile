import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/version_service.dart';

/// Settings screen with detailed version and app information
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _platformInfo;
  String? _debugInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    try {
      final info = await VersionService.getPlatformInfo();
      final debugInfo = await VersionService.getDebugVersionInfo();

      if (mounted) {
        setState(() {
          _platformInfo = info;
          _debugInfo = debugInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('settings.title')),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          loc.translate('settings.about'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      context,
                      loc.translate('app.title'),
                      loc.translate('app.title'),
                      Icons.apps,
                    ),
                    const Divider(),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_platformInfo != null) ...[
                      _buildInfoRow(
                        context,
                        loc.translate('app.platformVersion'),
                        '${_platformInfo!['platform']} ${_platformInfo!['displayVersion']}',
                        _getPlatformIcon(_platformInfo!['platform']),
                      ),
                      const Divider(),
                      _buildInfoRow(
                        context,
                        'Version',
                        _platformInfo!['version'],
                        Icons.tag,
                      ),
                      const Divider(),
                      _buildInfoRow(
                        context,
                        'Build Number',
                        _platformInfo!['buildNumber'].toString(),
                        Icons.build,
                      ),
                      const Divider(),
                      _buildInfoRow(
                        context,
                        'Build Mode',
                        VersionService.getBuildMode(),
                        Icons.engineering,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Platform Details Card
            if (!_isLoading && _platformInfo != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.phone_android,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Platform Details',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        context,
                        'Platform',
                        _platformInfo!['platform'],
                        Icons.computer,
                      ),
                      const Divider(),
                      _buildInfoRow(
                        context,
                        'Application Type',
                        VersionService.isDebugBuild()
                            ? 'Development'
                            : 'Production',
                        Icons.apps,
                      ),
                      if (_debugInfo != null) ...[
                        const Divider(),
                        ExpansionTile(
                          leading: Icon(
                            Icons.bug_report,
                            color: theme.colorScheme.secondary,
                          ),
                          title: Text(
                            'Debug Information',
                            style: theme.textTheme.bodyMedium,
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _debugInfo!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Version Comparison Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.compare_arrows,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Platform Versions',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildVersionRow(context, '🤖', 'Android', 'v1.2.0 (12)'),
                    const Divider(),
                    _buildVersionRow(context, '📱', 'iOS', 'v1.1.5 (15)'),
                    const Divider(),
                    _buildVersionRow(context, '🌐', 'Web', 'v1.0.8 (8)'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionRow(
    BuildContext context,
    String icon,
    String platform,
    String version,
  ) {
    final theme = Theme.of(context);
    final isCurrentPlatform =
        platform.toLowerCase() ==
        VersionService.getPlatformName().toLowerCase();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: isCurrentPlatform
          ? BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isCurrentPlatform ? 12 : 0),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        platform,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isCurrentPlatform
                              ? theme.colorScheme.primary
                              : null,
                        ),
                      ),
                      if (isCurrentPlatform) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Current',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    version,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'android':
        return Icons.android;
      case 'ios':
        return Icons.phone_iphone;
      case 'web':
        return Icons.web;
      case 'windows':
        return Icons.desktop_windows;
      case 'macos':
        return Icons.laptop_mac;
      case 'linux':
        return Icons.computer;
      default:
        return Icons.device_unknown;
    }
  }
}
