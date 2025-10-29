import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/managers/app_manager.dart';
import '../../core/managers/websocket_manager.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/navigation_service.dart';
import '../../core/utils/auth_debug_helper.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/authentication_manager.dart';
import '../../core/services/update_service.dart';
import '../../core/services/websocket_auth_service.dart';
import '../providers/auth_provider.dart';
import '../providers/projects_provider.dart';
import '../providers/tasks_api_provider.dart';
import '../providers/chat_provider.dart';
import '../screens/loading/loading_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/main/main_screen.dart';
import 'update_dialogs.dart';

/// Public controller to interact with AppRoot from other layers (e.g., services)
/// without exposing the private _AppRootState type.
class AppRootController {
  AppRootController._();

  // GlobalKey bound to AppRoot to access its state safely within this file
  static final GlobalKey<_AppRootState> key = GlobalKey<_AppRootState>();

  /// Re-run the update check from anywhere. If payload vars are provided
  /// (e.g., from notification), immediately show the appropriate dialog
  /// using AppRoot's standard widgets and localization.
  static Future<void> recheckUpdates([Map<String, dynamic>? vars]) async {
    final state = key.currentState;
    if (state == null) return;

    if (vars != null && vars.isNotEmpty) {
      final isRequired =
          (vars['update_required'] ?? vars['is_required']) == true;
      final current = (vars['current_version'] ?? '').toString();
      final latest = (vars['latest_version'] ?? '').toString();
      final title = (vars['title'] ?? 'Update Available').toString();
      final desc =
          (vars['description'] ?? UpdateService.getUpdateInstructions())
              .toString();

      if (isRequired) {
        state._showRequiredUpdateDialog({
          'currentVersion': current,
          'latestVersion': latest,
          'updateTitle': title,
          'updateDescription': desc,
        });
      } else {
        state._scheduleOptionalUpdateDialog({
          'currentVersion': current,
          'latestVersion': latest,
          'updateTitle': title,
          'updateDescription': desc,
        });
      }
    } else {
      await state._checkForUpdates();
    }
  }

  /// Restart the app initialization flow (rarely needed)
  static Future<void> restartInitialization() async {
    final state = key.currentState;
    if (state == null) return;
    await state._initializeApp();
  }

  /// Force app to show login screen (used on 401 auto logout)
  static void setUnauthenticated() {
    final state = key.currentState;
    if (state == null) return;
    state._forceUnauthenticated();
  }

  /// Force app to show main screen (rarely used; normally done via onAuthSuccess)
  static void setAuthenticated() {
    final state = key.currentState;
    if (state == null) return;
    state._forceAuthenticated();
  }
}

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
  bool _updateRequired =
      false; // Flag to pause initialization on required updates

  Future<bool> _waitForSocketReady(WebSocketManager webSocketManager) async {
    const timeout = Duration(seconds: 5);
    const pollInterval = Duration(milliseconds: 100);
    final start = DateTime.now();

    while ((webSocketManager.socketId == null ||
            webSocketManager.socketId!.isEmpty) &&
        DateTime.now().difference(start) < timeout) {
      await Future.delayed(pollInterval);
    }

    return webSocketManager.socketId != null &&
        webSocketManager.socketId!.isNotEmpty;
  }

  Future<void> _initializeWebSocketForUser(AuthProvider authProvider) async {
    final token = authProvider.authToken;
    final userId = authProvider.currentUser?.id;

    if (token == null || userId == null) {
      Logger.warning(
        '⚠️ AppRoot: Skipping WebSocket setup - token or userId missing',
      );
      return;
    }

    try {
      final webSocketManager = Provider.of<WebSocketManager>(
        context,
        listen: false,
      );

      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.bindWebSocket(webSocketManager);

      final alreadyConnected = webSocketManager.isConnected;
      final connected = alreadyConnected
          ? true
          : await webSocketManager.connect(token: token, userId: userId);

      if (!connected) {
        Logger.warning('⚠️ AppRoot: WebSocket connection failed');
        return;
      }

      if (!alreadyConnected) {
        Logger.info('✅ AppRoot: WebSocket connection established');
      }

      final socketReady = await _waitForSocketReady(webSocketManager);
      if (!socketReady) {
        Logger.warning(
          '⚠️ AppRoot: Socket ID not available after waiting - skipping subscription',
        );
        return;
      }

      final channelName = 'private-user.$userId';

      if (webSocketManager.isSubscribedTo(channelName)) {
        Logger.info(
          'ℹ️ AppRoot: Already subscribed to default channel $channelName',
        );
        return;
      }

      final subscribed = await webSocketManager.subscribeToChannel(
        channelName: channelName,
        onAuthRequired: (channel) async {
          final socketId = webSocketManager.socketId;
          if (socketId == null || socketId.isEmpty) {
            throw Exception('Socket ID not available for channel auth');
          }
          return WebSocketAuthService.authorize(
            channelName: channel,
            socketId: socketId,
          );
        },
      );

      if (subscribed) {
        Logger.info('✅ AppRoot: Subscribed to default channel $channelName');
      } else {
        Logger.warning(
          '⚠️ AppRoot: Failed to subscribe to default channel $channelName',
        );
      }
    } catch (e, st) {
      Logger.warning('⚠️ AppRoot: WebSocket initialization error: $e');
      Logger.debug(st.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // Force transition helpers (public via AppRootController)
  void _forceUnauthenticated() {
    Logger.info('🚫 AppRoot: Forcing unauthenticated state');
    if (mounted) {
      setState(() {
        _currentState = AppState.unauthenticated;
        _isInitializing = false;
      });
    }
  }

  void _forceAuthenticated() {
    Logger.info('🔓 AppRoot: Forcing authenticated state');
    if (mounted) {
      setState(() {
        _currentState = AppState.authenticated;
        _isInitializing = false;
      });
    }
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
      // Check for app updates before authentication
      Logger.info('🔄 AppRoot: Checking for app updates early');
      await _checkForUpdates();
      // If an update is required, halt further initialization
      if (_updateRequired) {
        Logger.warning(
          '🚨 AppRoot: Required update detected, pausing initialization',
        );
        _isInitializing = false;
        return;
      }

      // Initialize authentication manager for automatic logout on 401 responses
      Logger.info('🔐 AppRoot: Initializing authentication manager');
      AuthenticationManager().initialize();

      // Initialize app manager
      final state = await _appManager.initialize();

      // Initialize auth provider to sync with auth service
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize();
      Logger.info('✅ AppRoot: AuthProvider synchronized with AuthService');

      // Verify existing token validity
      Logger.info('🔍 AppRoot: Verifying auth token validity');
      final tokenValid = await authProvider.verifyToken();
      if (!tokenValid) {
        Logger.warning(
          '🚫 AppRoot: Auth token invalid, marking unauthenticated',
        );
        if (mounted) setState(() => _currentState = AppState.unauthenticated);
        _isInitializing = false;
        return;
      }

      // If user is authenticated, load their profile data + prefetch domain lists
      if (state == AppState.authenticated && authProvider.isLoggedIn) {
        Logger.info('👤 AppRoot: Loading user profile data');
        await authProvider.loadUserProfile();
        Logger.info('✅ AppRoot: User profile data loaded');

        await _initializeWebSocketForUser(authProvider);

        try {
          // Prefetch tasks & projects in parallel so main screen shows ready content
          final projectsProvider = Provider.of<ProjectsProvider>(
            context,
            listen: false,
          );
          final tasksProvider = Provider.of<TasksApiProvider>(
            context,
            listen: false,
          );

          Logger.info('🚀 AppRoot: Prefetching projects & tasks');
          await Future.wait([
            projectsProvider.projects.isEmpty
                ? projectsProvider.fetchProjects()
                : Future.value(),
            tasksProvider.tasks.isEmpty
                ? tasksProvider.fetchTasks()
                : Future.value(),
          ]);
          Logger.info('✅ AppRoot: Prefetch complete');
        } catch (e, st) {
          Logger.warning('⚠️ AppRoot: Prefetch failed: $e');
          Logger.debug(st.toString());
        }
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

      // Get current locale for localized update messages
      String? currentLocale;
      if (mounted) {
        try {
          final loc = AppLocalizations.of(context);
          currentLocale = loc.locale.languageCode;
        } catch (e) {
          Logger.warning('⚠️ AppRoot: Could not get current locale: $e');
          currentLocale = 'en'; // Default to English
        }
      }

      final updateInfo = await UpdateService.getUpdateInfo(currentLocale);

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
      Logger.info('🌐 AppRoot: Update content localized for: $currentLocale');

      if (mounted) {
        if (isRequired) {
          // Required update - pause app and show blocking dialog
          Logger.info('🚨 AppRoot: Required update detected');
          _updateRequired = true;
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

      await _initializeWebSocketForUser(authProvider);

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

      // Ensure WebSocket connection is closed on logout
      final webSocketManager = Provider.of<WebSocketManager>(
        context,
        listen: false,
      );
      await webSocketManager.disconnect();
      Logger.info('✅ AppRoot: WebSocket disconnected after logout');

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
