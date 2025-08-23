import 'package:flutter/material.dart';
import '../../core/managers/app_manager.dart';
import '../../core/utils/logger.dart';
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
    
    try {
      // Initialize app manager
      final state = await _appManager.initialize();
      
      if (mounted) {
        setState(() {
          _currentState = state;
          _isInitializing = false;
        });
      }
      
    } catch (e, stackTrace) {
      Logger.error('❌ AppRoot: App initialization failed', 'AppRoot', e, stackTrace);
      
      if (mounted) {
        setState(() {
          _currentState = AppState.unauthenticated;
          _isInitializing = false;
        });
      }
    }
  }

  /// Handle authentication success callback
  void _onAuthenticationSuccess() {
    Logger.info('🎉 AppRoot: Authentication successful, switching to main screen');
    
    // Update app manager state
    _appManager.onAuthenticationSuccess();
    
    // Update UI state
    if (mounted) {
      setState(() {
        _currentState = AppState.authenticated;
      });
    }
  }

  /// Handle logout callback
  Future<void> _onLogout() async {
    Logger.info('🚪 AppRoot: Logout requested');
    
    // Handle logout in app manager
    await _appManager.onLogout();
    
    // Update UI state
    if (mounted) {
      setState(() {
        _currentState = AppState.unauthenticated;
      });
    }
  }

  /// Build the appropriate screen based on current state
  Widget _buildCurrentScreen() {
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
        return MainScreen(onLogout: _onLogout);
        
      case AppState.unauthenticated:
        Logger.info('📱 AppRoot: Showing login screen');
        return LoginScreenWrapper(onAuthSuccess: _onAuthenticationSuccess);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildCurrentScreen();
  }
}

/// Wrapper for LoginScreen to handle auth success callback
class LoginScreenWrapper extends StatelessWidget {
  final VoidCallback? onAuthSuccess;
  
  const LoginScreenWrapper({
    super.key,
    this.onAuthSuccess,
  });

  @override
  Widget build(BuildContext context) {
    // We'll modify the original LoginScreen to accept and use this callback
    return const LoginScreen(); // For now, using original LoginScreen
  }
}
