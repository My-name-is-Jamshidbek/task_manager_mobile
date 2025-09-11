import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/managers/app_manager.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/navigation_service.dart';
import '../../core/utils/auth_debug_helper.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/authentication_manager.dart';
import '../../core/services/update_service.dart';
import '../providers/auth_provider.dart';
import '../screens/loading/loading_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/main/main_screen.dart';
import 'update_dialogs.dart';

/// Root widget that manages app-wide state and routing based on AppManager
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final AppManager _appManager = AppManager();
  AppState _currentState = AppState.loading;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Initialize the app and determine initial state
  Future<void> _initializeApp() async {
    Logger.info('🎯 AppRoot: Starting app initialization');

    // Record start time for minimum loading duration
    final startTime = DateTime.now();
    const minimumLoadingDuration = Duration(seconds: 5);

    // Debug: Check stored auth data before initialization
    await AuthDebugHelper.printStoredAuthData();

    try {
      // Initialize authentication manager for automatic logout on 401 responses
      Logger.info('🔐 AppRoot: Initializing authentication manager');
      AuthenticationManager().initialize();

      // Initialize app manager
      final state = await _appManager.initialize();

      // Initialize auth provider to sync with auth service
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize();
      Logger.info('✅ AppRoot: AuthProvider synchronized with AuthService');

      // If user is authenticated, load their profile data
      if (state == AppState.authenticated && authProvider.isLoggedIn) {
        Logger.info('👤 AppRoot: Loading user profile data');
        await authProvider.loadUserProfile();
        Logger.info('✅ AppRoot: User profile data loaded');
      }

      // Check for app updates after initialization
      Logger.info('🔄 AppRoot: Checking for app updates');
      await _checkForUpdates();

      // Calculate elapsed time and ensure minimum loading duration
      final elapsedTime = DateTime.now().difference(startTime);
      if (elapsedTime < minimumLoadingDuration) {
        final remainingTime = minimumLoadingDuration - elapsedTime;
        Logger.info(
          '⏱️ AppRoot: Waiting ${remainingTime.inMilliseconds}ms more for minimum loading duration',
        );
        await Future.delayed(remainingTime);
      }

      // Add a small buffer for smoother transition
      await Future.delayed(const Duration(milliseconds: 300));

      Logger.info(
        '✅ AppRoot: Initialization completed after ${DateTime.now().difference(startTime).inMilliseconds}ms',
      );

      if (mounted) {
        setState(() {
          _currentState = state;
          _isInitializing = false;
        });
      }
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AppRoot: App initialization failed',
        'AppRoot',
        e,
        stackTrace,
      );

      // Ensure minimum loading time even on error
      final elapsedTime = DateTime.now().difference(startTime);
      if (elapsedTime < minimumLoadingDuration) {
        final remainingTime = minimumLoadingDuration - elapsedTime;
        Logger.info(
          '⏱️ AppRoot: Waiting ${remainingTime.inMilliseconds}ms more for minimum loading duration (error case)',
        );
        await Future.delayed(remainingTime);
      }

      // Add a small buffer for smoother transition even on error
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          _currentState = AppState.unauthenticated;
          _isInitializing = false;
        });
      }
    }
  }

  /// Check for app updates and handle required/optional updates
  Future<void> _checkForUpdates() async {
    try {
      // Only check for updates on supported platforms
      if (!UpdateService.isPlatformSupported()) {
        Logger.info(
          'ℹ️ AppRoot: Update check skipped - platform not supported',
        );
        return;
      }

      Logger.info('🔄 AppRoot: Starting update check');
      final updateInfo = await UpdateService.getUpdateInfo();

      if (updateInfo == null) {
        Logger.info('ℹ️ AppRoot: No update information available');
        return;
      }

      final hasUpdate = updateInfo['hasUpdate'] ?? false;
      final isRequired = updateInfo['isRequired'] ?? false;

      if (!hasUpdate) {
        Logger.info('✅ AppRoot: App is up to date');
        return;
      }

      Logger.info('📱 AppRoot: Update available - Required: $isRequired');

      if (mounted) {
        if (isRequired) {
          // Required update - show blocking dialog
          Logger.info('🚨 AppRoot: Showing required update dialog');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showRequiredUpdateDialog(updateInfo);
          });
        } else {
          // Optional update - show after app loads
          Logger.info('💡 AppRoot: Scheduling optional update dialog');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scheduleOptionalUpdateDialog(updateInfo);
          });
        }
      }
    } catch (e, stackTrace) {
      Logger.error('❌ AppRoot: Update check failed', 'AppRoot', e, stackTrace);
    }
  }

  /// Show required update dialog (blocking)
  void _showRequiredUpdateDialog(Map<String, dynamic> updateInfo) {
    RequiredUpdateDialog.show(
      context: context,
      currentVersion: updateInfo['currentVersion'] ?? '',
      latestVersion: updateInfo['latestVersion'] ?? '',
      updateTitle: updateInfo['updateTitle'] ?? 'Update Required',
      updateDescription:
          updateInfo['updateDescription'] ?? 'Please update to continue.',
    );
  }

  /// Schedule optional update dialog to show after a delay
  void _scheduleOptionalUpdateDialog(Map<String, dynamic> updateInfo) {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        OptionalUpdateDialog.show(
          context: context,
          currentVersion: updateInfo['currentVersion'] ?? '',
          latestVersion: updateInfo['latestVersion'] ?? '',
          updateTitle: updateInfo['updateTitle'] ?? 'Update Available',
          updateDescription:
              updateInfo['updateDescription'] ?? 'A new version is available.',
        );
      }
    });
  }

  /// Handle authentication success callback
  Future<void> _onAuthenticationSuccess() async {
    Logger.info(
      '🎉 AppRoot: Authentication successful, switching to main screen',
    );

    try {
      // Update app manager state first
      await _appManager.onAuthenticationSuccess();

      // Sync auth provider state with auth service
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize();
      Logger.info('✅ AppRoot: AuthProvider state synchronized after login');

      // Load user profile data
      Logger.info('👤 AppRoot: Loading user profile after authentication');
      await authProvider.loadUserProfile();
      Logger.info('✅ AppRoot: User profile loaded after authentication');

      // Update UI state to trigger rebuild with main screen
      if (mounted) {
        setState(() {
          _currentState = AppState.authenticated;
        });

        // Show login success toast after a brief delay to ensure main screen is rendered
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && navigatorKey.currentContext != null) {
            final loc = AppLocalizations.of(navigatorKey.currentContext!);
            ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(
                        navigatorKey.currentContext!,
                      ).colorScheme.onSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(loc.translate('messages.loginSuccessful')),
                  ],
                ),
                duration: const Duration(seconds: 3),
                backgroundColor: Theme.of(
                  navigatorKey.currentContext!,
                ).colorScheme.secondary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        });
      }

      Logger.info(
        '✅ AppRoot: Successfully transitioned to authenticated state',
      );
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AppRoot: Failed to handle authentication success',
        'AppRoot',
        e,
        stackTrace,
      );

      // Fallback: show error and stay on current screen
      if (mounted) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          const SnackBar(
            content: Text(
              'Authentication successful but transition failed. Please restart the app.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Handle logout callback
  Future<void> _onLogout() async {
    Logger.info('🚪 AppRoot: Logout requested');

    try {
      // Show logout success toast before transitioning
      if (mounted && navigatorKey.currentContext != null) {
        final loc = AppLocalizations.of(navigatorKey.currentContext!);
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.logout,
                  color: Theme.of(
                    navigatorKey.currentContext!,
                  ).colorScheme.onPrimary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(loc.translate('messages.logoutSuccessful')),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(
              navigatorKey.currentContext!,
            ).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }

      // Clear authentication state in app manager
      await _appManager.onLogout();
      Logger.info('✅ AppRoot: AppManager logout completed');

      // Sync auth provider state
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize();
      Logger.info('✅ AppRoot: AuthProvider state synchronized after logout');

      // Brief delay to let user see the toast
      await Future.delayed(const Duration(milliseconds: 800));

      // Update UI state to show login screen
      if (mounted) {
        setState(() {
          _currentState = AppState.unauthenticated;
        });
      }

      Logger.info(
        '✅ AppRoot: Successfully transitioned to unauthenticated state',
      );
    } catch (e, stackTrace) {
      Logger.error('❌ AppRoot: Logout failed', 'AppRoot', e, stackTrace);

      // Force logout even if there's an error
      if (mounted) {
        setState(() {
          _currentState = AppState.unauthenticated;
        });
      }
    }
  }

  /// Build the appropriate screen based on current state
  Widget _buildCurrentScreen() {
    Logger.info(
      '🔍 AppRoot: Building screen - isInitializing: $_isInitializing, currentState: $_currentState',
    );

    if (_isInitializing) {
      Logger.info('📱 AppRoot: Showing loading screen');
      return const LoadingScreen();
    }

    switch (_currentState) {
      case AppState.loading:
        Logger.info('📱 AppRoot: Showing loading screen');
        return const LoadingScreen();

      case AppState.authenticated:
        Logger.info('📱 AppRoot: Showing main screen');
        return MainScreen(
          key: const ValueKey('main_screen'),
          onLogout: _onLogout,
        );

      case AppState.unauthenticated:
        Logger.info('📱 AppRoot: Showing login screen');
        return LoginScreenWrapper(
          key: const ValueKey('login_screen'),
          onAuthSuccess: _onAuthenticationSuccess,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    Logger.info('🔍 AppRoot: Build method called');
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.0, 0.1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          ),
        );
      },
      child: _buildCurrentScreen(),
    );
  }
}

/// Wrapper for LoginScreen to handle auth success callback
class LoginScreenWrapper extends StatelessWidget {
  final Future<void> Function()? onAuthSuccess;

  const LoginScreenWrapper({super.key, this.onAuthSuccess});

  @override
  Widget build(BuildContext context) {
    // Pass the callback to the LoginScreen - convert to sync callback
    return LoginScreen(
      onAuthSuccess: onAuthSuccess != null ? () => onAuthSuccess!() : null,
    );
  }
}
