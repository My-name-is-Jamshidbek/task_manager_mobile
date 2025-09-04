import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/managers/app_manager.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/navigation_service.dart';
import '../../core/utils/auth_debug_helper.dart';
import '../../core/localization/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../screens/loading/loading_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/main/main_screen.dart';

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

    // Debug: Check stored auth data before initialization
    await AuthDebugHelper.printStoredAuthData();

    try {
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

      if (mounted) {
        setState(() {
          _currentState = AppState.unauthenticated;
          _isInitializing = false;
        });
      }
    }
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
    return _buildCurrentScreen();
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
