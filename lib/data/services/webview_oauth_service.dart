import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/oauth_constants.dart';
import '../../core/utils/logger.dart';
import '../models/oauth_models.dart';

/// WebView-based OAuth Service
/// Handles SSO authentication using WebView and custom URL schemes
class WebViewOAuthService {
  static final WebViewOAuthService _instance = WebViewOAuthService._internal();
  factory WebViewOAuthService() => _instance;
  WebViewOAuthService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  OAuthSession? _currentSession;

  // Getters
  OAuthSession? get currentSession => _currentSession;
  bool get isAuthenticated =>
      _currentSession != null && !_currentSession!.isExpired;
  String? get accessToken => _currentSession?.accessToken;

  /// Initialize OAuth service
  Future<void> initialize() async {
    Logger.info('🔐 WebViewOAuthService: Initializing WebView OAuth service');
    try {
      // Try to restore session from secure storage
      await _restoreSession();
      if (_currentSession != null && !_currentSession!.isExpired) {
        Logger.info('✅ WebViewOAuthService: Existing session restored');
      } else if (_currentSession != null) {
        Logger.info('⚠️ WebViewOAuthService: Stored session expired, clearing');
        await logout();
      }
    } catch (e, stackTrace) {
      Logger.error(
        '❌ WebViewOAuthService: Initialization failed',
        'WebViewOAuthService',
        e,
        stackTrace,
      );
    }
  }

  /// Get the SSO authentication URL to open in WebView
  String getSSOAuthUrl() {
    Logger.info('🌐 WebViewOAuthService: Getting SSO auth URL');
    return OAuthConstants.ssoAuthUrl;
  }

  /// Handle successful authentication from WebView callback
  /// Called when the WebView redirects to: tmsapp://login-success?token=<token>
  Future<bool> handleAuthenticationSuccess(String token) async {
    Logger.info('✅ WebViewOAuthService: Handling authentication success');

    try {
      if (token.isEmpty) {
        Logger.error(
          '❌ WebViewOAuthService: Empty token received',
          'WebViewOAuthService',
          Exception('Empty token'),
        );
        return false;
      }

      // Create session with the received token
      _currentSession = OAuthSession(
        accessToken: token,
        refreshToken: null,
        idToken: null,
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        userInfo: null,
      );

      // Save to secure storage
      await _saveSession(_currentSession!);

      Logger.info('✅ WebViewOAuthService: Session created and stored');
      return true;
    } catch (e, stackTrace) {
      Logger.error(
        '❌ WebViewOAuthService: Failed to handle authentication success',
        'WebViewOAuthService',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Handle authentication failure from WebView callback
  /// Called when the WebView redirects to: tmsapp://login-failed?error=<error>
  Future<void> handleAuthenticationFailure(String errorMessage) async {
    Logger.error(
      '❌ WebViewOAuthService: Authentication failed: $errorMessage',
      'WebViewOAuthService',
      Exception(errorMessage),
    );
  }

  /// Save session to secure storage
  Future<void> _saveSession(OAuthSession session) async {
    Logger.info('💾 WebViewOAuthService: Saving session to secure storage');

    try {
      await _secureStorage.write(
        key: OAuthConstants.accessTokenKey,
        value: session.accessToken,
      );

      await _secureStorage.write(
        key: OAuthConstants.expiresAtKey,
        value: session.expiresAt.toIso8601String(),
      );

      Logger.info('✅ WebViewOAuthService: Session saved to secure storage');
    } catch (e, stackTrace) {
      Logger.error(
        '❌ WebViewOAuthService: Failed to save session',
        'WebViewOAuthService',
        e,
        stackTrace,
      );
    }
  }

  /// Restore session from secure storage
  Future<void> _restoreSession() async {
    Logger.info(
      '📂 WebViewOAuthService: Restoring session from secure storage',
    );

    try {
      final accessToken = await _secureStorage.read(
        key: OAuthConstants.accessTokenKey,
      );

      if (accessToken == null) {
        Logger.info('🚫 WebViewOAuthService: No stored session found');
        return;
      }

      Logger.info('📂 WebViewOAuthService: Restoring stored session');

      final expiresAtStr = await _secureStorage.read(
        key: OAuthConstants.expiresAtKey,
      );

      DateTime expiresAt = DateTime.now().add(const Duration(days: 1));
      if (expiresAtStr != null) {
        try {
          expiresAt = DateTime.parse(expiresAtStr);
        } catch (e) {
          Logger.warning(
            '⚠️ WebViewOAuthService: Failed to parse expiration time',
          );
        }
      }

      _currentSession = OAuthSession(
        accessToken: accessToken,
        refreshToken: null,
        idToken: null,
        expiresAt: expiresAt,
        userInfo: null,
      );

      Logger.info('✅ WebViewOAuthService: Session restored');
    } catch (e, stackTrace) {
      Logger.error(
        '❌ WebViewOAuthService: Session restoration failed',
        'WebViewOAuthService',
        e,
        stackTrace,
      );
    }
  }

  /// Clear session and logout
  Future<void> logout() async {
    Logger.info('🚪 WebViewOAuthService: Logging out');

    try {
      // Clear secure storage
      await _secureStorage.delete(key: OAuthConstants.accessTokenKey);
      await _secureStorage.delete(key: OAuthConstants.expiresAtKey);

      // Clear memory
      _currentSession = null;

      Logger.info('✅ WebViewOAuthService: Logout successful');
    } catch (e, stackTrace) {
      Logger.error(
        '❌ WebViewOAuthService: Logout failed',
        'WebViewOAuthService',
        e,
        stackTrace,
      );
    }
  }

  /// Check if token has expired
  bool get isTokenExpired {
    if (_currentSession == null) return true;
    return _currentSession!.isExpired;
  }

  /// Check if token will expire soon (within 5 minutes)
  bool get shouldRefreshToken {
    if (_currentSession == null) return false;
    return _currentSession!.shouldRefresh;
  }
}
