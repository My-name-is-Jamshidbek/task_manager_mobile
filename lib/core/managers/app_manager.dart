import '../utils/logger.dart';
import '../../data/services/auth_service.dart';
import '../../core/api/api_client.dart';

/// Central App Manager that handles app initialization and routing logic
///
/// This manager is responsible for:
/// - App startup flow
/// - Authentication state management
/// - Initial routing decisions
/// - Future extensibility (Firebase, notifications, etc.)
class AppManager {
  static final AppManager _instance = AppManager._internal();
  factory AppManager() => _instance;
  AppManager._internal();

  final AuthService _authService = AuthService();
  // Reserved for future use (API calls during initialization, etc.)
  // ignore: unused_field
  final ApiClient _apiClient = ApiClient();

  bool _isInitialized = false;
  AppState _currentState = AppState.loading;

  // Getters
  bool get isInitialized => _isInitialized;
  AppState get currentState => _currentState;

  /// Initialize the app manager and determine initial route
  Future<AppState> initialize() async {
    Logger.info('🚀 AppManager: Starting app initialization');

    try {
      _currentState = AppState.loading;

      // Step 1: Initialize core services
      await _initializeCoreServices();

      // Step 2: Check authentication state
      final authState = await _checkAuthenticationState();

      // Step 3: Determine app state
      _currentState = authState;
      _isInitialized = true;

      Logger.info(
        '✅ AppManager: Initialization completed with state: ${_currentState.name}',
      );
      return _currentState;
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AppManager: Initialization failed',
        'AppManager',
        e,
        stackTrace,
      );
      _currentState = AppState.unauthenticated;
      _isInitialized = true;
      return _currentState;
    }
  }

  /// Initialize core services
  Future<void> _initializeCoreServices() async {
    Logger.info('⚙️ AppManager: Initializing core services');

    try {
      // Initialize auth service
      await _authService.initialize();
      Logger.info('✅ AppManager: Auth service initialized');

      // TODO: Future services initialization
      // await _initializeFirebase();
      // await _initializeNotifications();
      // await _initializeAnalytics();
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AppManager: Core services initialization failed',
        'AppManager',
        e,
        stackTrace,
      );
      throw AppManagerException('Failed to initialize core services: $e');
    }
  }

  /// Check authentication state and token validity
  Future<AppState> _checkAuthenticationState() async {
    Logger.info('🔐 AppManager: Checking authentication state');

    try {
      // Step 1: Check if user has a token
      if (!_authService.isLoggedIn || _authService.currentToken == null) {
        Logger.info('🚫 AppManager: No token found - user needs to login');
        return AppState.unauthenticated;
      }

      final token = _authService.currentToken!;
      Logger.info('🔑 AppManager: Token found');

      // Step 2: Verify token with server
      Logger.info('🔍 AppManager: Verifying token with server');
      final isValid = await _verifyTokenWithServer(token);
      if (isValid) {
        Logger.info('✅ AppManager: Token verified - user is authenticated');
        return AppState.authenticated;
      } else {
        Logger.warning(
          '⚠️ AppManager: Token verification failed - clearing session',
        );
        await _authService.clearSession();
        return AppState.unauthenticated;
      }
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AppManager: Authentication check failed',
        'AppManager',
        e,
        stackTrace,
      );
      // Clear potentially corrupted session on error
      await _authService.clearSession();
      return AppState.unauthenticated;
    }
  }

  /// Verify token with the server
  Future<bool> _verifyTokenWithServer(String token) async {
    Logger.info('🔍 AppManager: Verifying token with server');

    try {
      // Use AuthService token verification
      final response = await _authService.verifyToken();

      if (response.isSuccess && response.data?.tokenValid == true) {
        Logger.info('✅ AppManager: Server token verification successful');
        return true;
      } else {
        Logger.warning(
          '⚠️ AppManager: Server token verification failed: ${response.error}',
        );
        return false;
      }
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AppManager: Token verification request failed',
        'AppManager',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Handle successful authentication
  Future<void> onAuthenticationSuccess() async {
    Logger.info('🎉 AppManager: Authentication successful');
    _currentState = AppState.authenticated;

    // TODO: Post-authentication setup
    // await _setupUserSession();
    // await _syncUserData();
    // await _registerForNotifications();
  }

  /// Handle logout
  Future<void> onLogout() async {
    Logger.info('🚪 AppManager: Handling logout');

    try {
      await _authService.logout();
      _currentState = AppState.unauthenticated;
      Logger.info('✅ AppManager: Logout completed');
    } catch (e, stackTrace) {
      Logger.error('❌ AppManager: Logout failed', 'AppManager', e, stackTrace);
      // Force clear session even if logout API fails
      await _authService.clearSession();
      _currentState = AppState.unauthenticated;
    }
  }

  /// Refresh authentication state (for use when token might have changed)
  Future<AppState> refreshAuthState() async {
    Logger.info('🔄 AppManager: Refreshing authentication state');
    return await _checkAuthenticationState();
  }

  /// Get the appropriate initial route based on current state
  String getInitialRoute() {
    switch (_currentState) {
      case AppState.loading:
        return '/loading';
      case AppState.authenticated:
        return '/main';
      case AppState.unauthenticated:
        return '/login';
    }
  }

  /// Reset manager state (useful for testing)
  void reset() {
    Logger.info('🔄 AppManager: Resetting state');
    _isInitialized = false;
    _currentState = AppState.loading;
  }

  // TODO: Future functionality expansions

  /// Initialize Firebase services
  // Future<void> _initializeFirebase() async {
  //   Logger.info('🔥 AppManager: Initializing Firebase');
  //   // Firebase initialization logic
  // }

  /// Initialize push notifications
  // Future<void> _initializeNotifications() async {
  //   Logger.info('🔔 AppManager: Initializing notifications');
  //   // Notification setup logic
  // }

  /// Initialize analytics
  // Future<void> _initializeAnalytics() async {
  //   Logger.info('📊 AppManager: Initializing analytics');
  //   // Analytics setup logic
  // }

  /// Setup user session data
  // Future<void> _setupUserSession() async {
  //   Logger.info('👤 AppManager: Setting up user session');
  //   // User session setup logic
  // }
}

/// App state enumeration
enum AppState { loading, authenticated, unauthenticated }

/// Extension for AppState enum
extension AppStateExtension on AppState {
  String get name {
    switch (this) {
      case AppState.loading:
        return 'Loading';
      case AppState.authenticated:
        return 'Authenticated';
      case AppState.unauthenticated:
        return 'Unauthenticated';
    }
  }
}

/// Custom exception for AppManager
class AppManagerException implements Exception {
  final String message;
  const AppManagerException(this.message);

  @override
  String toString() => 'AppManagerException: $message';
}
