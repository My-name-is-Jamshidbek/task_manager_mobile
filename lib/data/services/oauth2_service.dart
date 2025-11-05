import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/oauth_constants.dart';
import '../../core/utils/logger.dart';
import '../models/oauth_models.dart';

/// DEPRECATED: OAuth 2.0 Service with PKCE support
/// This service was designed for the Authorization Code Flow but is now deprecated
/// in favor of the WebView-based SSO flow implemented in WebViewOAuthService.
///
/// Kept for reference only. Use WebViewOAuthService for new OAuth implementations.
class OAuth2Service {
  static final OAuth2Service _instance = OAuth2Service._internal();
  factory OAuth2Service() => _instance;
  OAuth2Service._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  OAuthSession? _currentSession;

  // Getters
  OAuthSession? get currentSession => _currentSession;
  bool get isAuthenticated =>
      _currentSession != null && !_currentSession!.isExpired;
  String? get accessToken => _currentSession?.accessToken;

  /// Initialize OAuth service
  Future<void> initialize() async {
    Logger.info('🔐 OAuth2Service (DEPRECATED): Initializing');
    try {
      await _restoreSession();
      if (_currentSession != null && !_currentSession!.isExpired) {
        Logger.info('✅ OAuth2Service: Existing session restored');
      } else if (_currentSession != null) {
        Logger.info('⚠️ OAuth2Service: Stored session expired, clearing');
        await logout();
      }
    } catch (e, stackTrace) {
      Logger.error(
        '❌ OAuth2Service: Initialization failed',
        'OAuth2Service',
        e,
        stackTrace,
      );
    }
  }

  /// Logout
  Future<void> logout() async {
    Logger.info('🚪 OAuth2Service: Logging out');

    try {
      // Clear secure storage
      await _secureStorage.delete(key: OAuthConstants.accessTokenKey);
      await _secureStorage.delete(key: OAuthConstants.expiresAtKey);

      // Clear memory
      _currentSession = null;

      Logger.info('✅ OAuth2Service: Logout successful');
    } catch (e, stackTrace) {
      Logger.error(
        '❌ OAuth2Service: Logout failed',
        'OAuth2Service',
        e,
        stackTrace,
      );
    }
  }

  /// Save session to secure storage
  Future<void> _saveSession(OAuthSession session) async {
    Logger.info('💾 OAuth2Service: Saving session to secure storage');

    try {
      await _secureStorage.write(
        key: OAuthConstants.accessTokenKey,
        value: session.accessToken,
      );

      await _secureStorage.write(
        key: OAuthConstants.expiresAtKey,
        value: session.expiresAt.toIso8601String(),
      );

      Logger.info('✅ OAuth2Service: Session saved to secure storage');
    } catch (e, stackTrace) {
      Logger.error(
        '❌ OAuth2Service: Failed to save session',
        'OAuth2Service',
        e,
        stackTrace,
      );
    }
  }

  /// Restore session from secure storage
  Future<void> _restoreSession() async {
    Logger.info('📂 OAuth2Service: Restoring session from secure storage');

    try {
      final accessToken = await _secureStorage.read(
        key: OAuthConstants.accessTokenKey,
      );

      if (accessToken == null) {
        Logger.info('🚫 OAuth2Service: No stored session found');
        return;
      }

      Logger.info('📂 OAuth2Service: Restoring stored session');

      final expiresAtStr = await _secureStorage.read(
        key: OAuthConstants.expiresAtKey,
      );

      DateTime expiresAt = DateTime.now().add(const Duration(days: 1));
      if (expiresAtStr != null) {
        try {
          expiresAt = DateTime.parse(expiresAtStr);
        } catch (e) {
          Logger.warning('⚠️ OAuth2Service: Failed to parse expiration time');
        }
      }

      _currentSession = OAuthSession(
        accessToken: accessToken,
        refreshToken: null,
        idToken: null,
        expiresAt: expiresAt,
        userInfo: null,
      );

      Logger.info('✅ OAuth2Service: Session restored');
    } catch (e, stackTrace) {
      Logger.error(
        '❌ OAuth2Service: Session restoration failed',
        'OAuth2Service',
        e,
        stackTrace,
      );
    }
  }
}
