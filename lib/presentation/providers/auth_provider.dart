import 'package:flutter/foundation.dart';
import '../../data/models/auth_models.dart';
import '../../data/services/auth_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/logger.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _error;
  User? _currentUser;
  bool _isLoggedIn = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  // Expose current auth token (if logged in)
  String? get authToken => _authService.currentToken;

  // Initialize provider
  Future<void> initialize() async {
    await _authService.initialize();
    _currentUser = _authService.currentUser;
    _isLoggedIn = _authService.isLoggedIn;
    // If user session exists, ensure FCM token is registered with backend
    if (_isLoggedIn) {
      await FirebaseService().registerTokenWithBackend(
        authToken: _authService.currentToken,
      );
    }
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Login with phone and password
  Future<bool> login(String phone, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.login(phone, password);

      if (response.isSuccess) {
        // Check if we got a token directly (no SMS verification needed)
        if (response.data?.token != null && response.data?.user != null) {
          _currentUser = response.data!.user;
          _isLoggedIn = true;
          _setLoading(false);
          notifyListeners();
          return true;
        } else {
          // SMS verification required
          _setLoading(false);
          return true;
        }
      } else {
        // Try to get localized message from API response first
        String? errorMessage = response.error;
        if (response.data?.message != null) {
          errorMessage = response.data!.getLocalizedMessage();
        }
        _setError(errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(null); // Let UI handle the translation
      _setLoading(false);
      return false;
    }
  }

  // Verify SMS code
  Future<bool> verifyCode(String phone, String code) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.verifyCode(phone, code);

      if (response.isSuccess && response.data != null) {
        _currentUser = response.data!.user;
        _isLoggedIn = true;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        // Try to get localized message from API response first
        String? errorMessage = response.error;
        if (response.data?.message != null) {
          errorMessage = response.data!.getLocalizedMessage();
        }
        _setError(errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(null); // Let UI handle the translation
      _setLoading(false);
      return false;
    }
  }

  // Resend SMS code
  Future<bool> resendSms(String phone) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.resendSms(phone);

      if (response.isSuccess) {
        _setLoading(false);
        return true;
      } else {
        // Try to get localized message from API response first
        String? errorMessage = response.error;
        if (response.data?.message != null) {
          errorMessage = response.data!.getLocalizedMessage();
        }
        _setError(errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(null); // Let UI handle the translation
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);

    // Deactivate FCM token before logout
    await FirebaseService().deactivateTokenFromBackend(
      authToken: _authService.currentToken,
    );
    try {
      await _authService.logout();
      _currentUser = null;
      _isLoggedIn = false;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      // Even if logout fails, clear local state
      _currentUser = null;
      _isLoggedIn = false;
      notifyListeners();
    }
  }

  // Get stored phone for SMS verification
  Future<String?> getStoredPhone() async {
    return await _authService.getStoredPhone();
  }

  // Check session validity
  Future<bool> checkSession() async {
    return await _authService.isSessionValid();
  }

  // Verify current token with server
  Future<bool> verifyToken() async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.verifyToken();

      if (response.isSuccess && response.data?.tokenValid == true) {
        // Update user data if provided in response
        if (response.data?.user != null) {
          _currentUser = response.data!.user;
          notifyListeners();
        }
        _setLoading(false);
        return true;
      } else {
        // Try to get localized message from API response first
        String? errorMessage = response.error;
        if (response.data != null) {
          errorMessage = response.data!.getLocalizedMessage();
        }
        _setError(errorMessage);
        _setLoading(false);

        // If token is invalid, clear the session
        if (response.data?.tokenValid == false) {
          await logout();
        }
        return false;
      }
    } catch (e) {
      _setError(null); // Let UI handle the translation
      _setLoading(false);
      return false;
    }
  }

  // Load user profile from API
  Future<bool> loadUserProfile() async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.loadUserProfile();

      if (response.isSuccess && response.data != null) {
        _currentUser = response.data!;
        _setLoading(false);
        // Force notification to ensure UI updates
        notifyListeners();
        return true;
      } else {
        // Try to get localized message from API response first
        String? errorMessage = response.error;
        _setError(errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to load profile: $e');
      _setLoading(false);
      return false;
    }
  }

  // Refresh user profile (convenience method)
  Future<void> refreshProfile() async {
    await loadUserProfile();
  }

  // Update user profile (name and phone)
  Future<ProfileUpdateResult> updateProfile({
    required String name,
    required String phone,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.updateProfile(
        name: name,
        phone: phone,
      );

      if (response.isSuccess && response.data != null) {
        _currentUser = response.data!.user;
        _setLoading(false);
        // Force notification to ensure UI updates
        notifyListeners();
        final localizedMessage = response.data!.getLocalizedMessage();
        return ProfileUpdateResult(
          success: true,
          message: localizedMessage,
          user: _currentUser,
        );
      } else {
        String? errorMessage = response.error;
        _setError(errorMessage);
        _setLoading(false);
        return ProfileUpdateResult(success: false, message: null);
      }
    } catch (e) {
      _setError('Failed to update profile: $e');
      _setLoading(false);
      return ProfileUpdateResult(success: false, message: null);
    }
  }

  // Change user password
  Future<PasswordChangeResult> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (response.isSuccess && response.data != null) {
        _setLoading(false);
        final localizedMessage = response.data!.getLocalizedMessage();
        return PasswordChangeResult(success: true, message: localizedMessage);
      } else {
        String? errorMessage = response.error;
        _setError(errorMessage);
        _setLoading(false);
        return PasswordChangeResult(success: false, message: null);
      }
    } catch (e) {
      _setError('Failed to change password: $e');
      _setLoading(false);
      return PasswordChangeResult(success: false, message: null);
    }
  }

  // Update avatar
  Future<ProfileUpdateResult> updateAvatar(String filePath) async {
    _setLoading(true);
    _setError(null);
    try {
      final response = await _authService.updateAvatar(filePath);
      if (response.isSuccess && response.data != null) {
        _currentUser = response.data;
        _setLoading(false);
        notifyListeners();
        return ProfileUpdateResult(
          success: true,
          message: null,
          user: _currentUser,
        );
      } else {
        _setError(response.error);
        _setLoading(false);
        return ProfileUpdateResult(
          success: false,
          message: response.error,
          user: null,
        );
      }
    } catch (e) {
      _setError('Failed to update avatar: $e');
      _setLoading(false);
      return ProfileUpdateResult(success: false, message: null, user: null);
    }
  }

  // ============================================================================
  // OAuth 2.0 Authentication Methods
  // ============================================================================

  /// Login with WebView OAuth Token (RANCH ID SSO)
  /// Called when user authenticates through WebView and receives a token
  Future<bool> loginWithToken(String token) async {
    Logger.info('🔐 AuthProvider: Starting loginWithToken');
    _setLoading(true);
    _setError(null);

    try {
      Logger.info('🔐 AuthProvider: Calling authService.loginWithToken');
      final response = await _authService.loginWithToken(token);

      Logger.info(
        '🔐 AuthProvider: Response received: isSuccess=${response.isSuccess}, hasData=${response.data != null}',
      );

      if (response.isSuccess && response.data != null) {
        Logger.info('🔐 AuthProvider: Login successful, updating state');
        _currentUser = response.data!.user;
        _isLoggedIn = true;
        _setLoading(false);
        notifyListeners();

        Logger.info('🔐 AuthProvider: State notified, isLoggedIn=$_isLoggedIn');

        // Register FCM token for new session
        Logger.info('🔐 AuthProvider: Registering FCM token');
        await FirebaseService().registerTokenWithBackend(
          authToken: _authService.currentToken,
        );

        Logger.info(
          '🔐 AuthProvider: loginWithToken completed successfully, returning true',
        );
        return true;
      } else {
        Logger.error(
          '❌ AuthProvider: Response failed or no data',
          'AuthProvider',
          Exception(response.error ?? 'Token authentication failed'),
        );
        _setError(response.error ?? 'Token authentication failed');
        _setLoading(false);
        return false;
      }
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AuthProvider: Token authentication error',
        'AuthProvider',
        e,
        stackTrace,
      );
      _setError('Token authentication error: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Login with OAuth 2.0 (RANCH ID)
  Future<bool> loginWithOAuth({
    String? clientId,
    required String redirectUrl,
    List<String>? scopes,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.loginWithOAuth(
        clientId: clientId,
        redirectUrl: redirectUrl,
        scopes: scopes,
      );

      if (response.isSuccess && response.data != null) {
        _currentUser = response.data!.user;
        _isLoggedIn = true;
        _setLoading(false);
        notifyListeners();

        // Register FCM token for new session
        await FirebaseService().registerTokenWithBackend(
          authToken: _authService.currentToken,
        );

        return true;
      } else {
        _setError(response.error ?? 'OAuth login failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('OAuth login error: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Handle OAuth callback (for custom flow)
  Future<bool> handleOAuthCallback({
    required String code,
    String? state,
    String? clientId,
    String? clientSecret,
    required String redirectUrl,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _authService.handleOAuthCallback(
        code: code,
        state: state,
        clientId: clientId,
        clientSecret: clientSecret,
        redirectUrl: redirectUrl,
      );

      if (response.isSuccess && response.data != null) {
        _currentUser = response.data!.user;
        _isLoggedIn = true;
        _setLoading(false);
        notifyListeners();

        await FirebaseService().registerTokenWithBackend(
          authToken: _authService.currentToken,
        );

        return true;
      } else {
        _setError(response.error ?? 'OAuth callback handling failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('OAuth callback error: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Refresh OAuth token
  Future<bool> refreshOAuthToken() async {
    try {
      return await _authService.refreshOAuthToken();
    } catch (e) {
      _setError('Failed to refresh OAuth token: $e');
      return false;
    }
  }

  /// Logout from OAuth
  Future<void> logoutOAuth() async {
    _setLoading(true);
    try {
      await _authService.logoutOAuth();
      _currentUser = null;
      _isLoggedIn = false;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Logout failed: $e');
      _setLoading(false);
    }
  }

  /// Check if using OAuth authentication
  bool get isOAuthAuthenticated => _authService.isOAuthAuthenticated;
}

// Helper class to return both success status and localized message
class PasswordChangeResult {
  final bool success;
  final String? message;

  PasswordChangeResult({required this.success, this.message});
}

class ProfileUpdateResult {
  final bool success;
  final String? message;
  final User? user;

  ProfileUpdateResult({required this.success, this.message, this.user});
}
