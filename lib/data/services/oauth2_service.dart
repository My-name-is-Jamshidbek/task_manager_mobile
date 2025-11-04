import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/oauth_constants.dart';
import '../../core/api/api_client.dart';
import '../../core/utils/logger.dart';
import '../models/oauth_models.dart';

/// OAuth 2.0 Service with PKCE support
/// Handles authorization flow, token refresh, and user info retrieval
class OAuth2Service {
  static final OAuth2Service _instance = OAuth2Service._internal();
  factory OAuth2Service() => _instance;
  OAuth2Service._internal();

  final FlutterAppAuth _appAuth = const FlutterAppAuth();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final ApiClient _apiClient = ApiClient();

  OAuthSession? _currentSession;
  String? _codeVerifier;
  String? _state;

  // Getters
  OAuthSession? get currentSession => _currentSession;
  bool get isAuthenticated =>
      _currentSession != null && !_currentSession!.isExpired;
  String? get accessToken => _currentSession?.accessToken;

  /// Initialize OAuth service
  Future<void> initialize() async {
    Logger.info('🔐 OAuth2Service: Initializing OAuth 2.0 service');
    try {
      // Try to restore session from secure storage
      await _restoreSession();
      if (_currentSession != null && !_currentSession!.isExpired) {
        Logger.info('✅ OAuth2Service: Existing session restored');
      } else if (_currentSession != null) {
        Logger.info(
          '⚠️ OAuth2Service: Stored session expired, attempting refresh',
        );
        await refreshToken();
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

  /// Generate PKCE code verifier and challenge
  Map<String, String> _generatePKCE() {
    Logger.info('🔐 OAuth2Service: Generating PKCE parameters');

    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();

    _codeVerifier = List<int>.generate(
      OAuthConstants.pkceCodeVerifierLength,
      (_) => charset.codeUnitAt(random.nextInt(charset.length)),
    ).map((i) => String.fromCharCode(i)).join();

    // Calculate code challenge (SHA256 hash of code verifier, base64url encoded)
    final bytes = utf8.encode(_codeVerifier!);
    final digest = sha256.convert(bytes);
    final codeChallenge = base64Url
        .encode(digest.bytes)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');

    Logger.info('✅ OAuth2Service: PKCE parameters generated');

    return {'code_verifier': _codeVerifier!, 'code_challenge': codeChallenge};
  }

  /// Generate random state parameter for CSRF protection
  String _generateState() {
    const charset =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    _state = List<int>.generate(
      32,
      (_) => charset.codeUnitAt(random.nextInt(charset.length)),
    ).map((i) => String.fromCharCode(i)).join();
    return _state!;
  }

  /// Start OAuth 2.0 authorization flow with RANCH ID
  Future<bool> startAuthorizationFlow({
    String? clientId,
    required String redirectUrl,
    List<String>? scopes,
    Map<String, String>? additionalParameters,
  }) async {
    Logger.info('🚀 OAuth2Service: Starting authorization flow');

    try {
      // Use flutter_appauth for platform-native OAuth handling
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          clientId ?? OAuthConstants.clientId,
          redirectUrl,
          discoveryUrl: OAuthConstants.authorizationUrl,
          scopes: scopes ?? OAuthConstants.defaultScopes,
          promptValues: ['login'], // Force login for RANCH ID
          additionalParameters: {
            'provider': OAuthConstants.ranchIdAuthProvider,
            ...?additionalParameters,
          },
        ),
      );

      Logger.info('✅ OAuth2Service: Authorization successful');
      Logger.info('🔑 OAuth2Service: Access token received');

      // Create session from result
      _currentSession = OAuthSession(
        accessToken: result.accessToken ?? '',
        refreshToken: result.refreshToken,
        idToken: result.idToken,
        expiresAt:
            result.accessTokenExpirationDateTime ??
            DateTime.now().add(const Duration(hours: 1)),
        userInfo: result.scopes?.contains('openid') == true
            ? await _fetchUserInfo(result.accessToken ?? '')
            : null,
      );

      // Save session to secure storage
      await _saveSession(_currentSession!);

      // Set auth token in API client
      _apiClient.setAuthToken(_currentSession!.accessToken);

      Logger.info('✅ OAuth2Service: Session stored and API client updated');
      return true;
    } catch (e, stackTrace) {
      Logger.error(
        '❌ OAuth2Service: Authorization flow failed',
        'OAuth2Service',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Alternative: Start authorization flow with custom URL opening
  /// (Use this if flutter_appauth doesn't work with RANCH ID)
  Future<bool> startCustomAuthorizationFlow({
    String? clientId,
    required String redirectUrl,
    List<String>? scopes,
  }) async {
    Logger.info('🚀 OAuth2Service: Starting custom authorization flow');

    try {
      final pkce = _generatePKCE();
      final state = _generateState();

      final authRequest = OAuthAuthorizationRequest(
        clientId: clientId ?? OAuthConstants.clientId,
        redirectUrl: redirectUrl,
        scopes: scopes ?? OAuthConstants.defaultScopes,
        state: state,
        codeChallenge: pkce['code_challenge'],
        codeChallengeMethod: OAuthConstants.pkceCodeChallengeMethod,
        additionalParameters: {'provider': OAuthConstants.ranchIdAuthProvider},
      );

      final authUrl = authRequest.buildAuthorizationUrl(
        OAuthConstants.authorizationUrl,
      );

      Logger.info('📱 OAuth2Service: Opening authorization URL');
      Logger.info('🔗 OAuth2Service: Auth URL: $authUrl');

      // Note: In a real app, you would use url_launcher to open this URL
      // and handle the redirect callback through deep linking
      // For now, this is just a helper method

      return true;
    } catch (e, stackTrace) {
      Logger.error(
        '❌ OAuth2Service: Custom authorization flow setup failed',
        'OAuth2Service',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Handle authorization code callback (for custom flow)
  Future<bool> handleAuthorizationCodeCallback(
    String code, {
    String? state,
    String? clientId,
    String? clientSecret,
    required String redirectUrl,
  }) async {
    Logger.info('🔄 OAuth2Service: Handling authorization code callback');

    try {
      if (state != null && state != _state) {
        throw Exception('State mismatch - possible CSRF attack');
      }

      if (_codeVerifier == null) {
        throw Exception(
          'Code verifier not found - authorization flow not initiated',
        );
      }

      // Exchange authorization code for token
      final tokenResponse = await _exchangeAuthorizationCode(
        code: code,
        clientId: clientId ?? OAuthConstants.clientId,
        clientSecret: clientSecret ?? OAuthConstants.clientSecret,
        redirectUrl: redirectUrl,
        codeVerifier: _codeVerifier,
      );

      if (tokenResponse != null) {
        Logger.info('✅ OAuth2Service: Token exchange successful');

        // Create session
        final userInfo = await _fetchUserInfo(tokenResponse.accessToken);

        _currentSession = OAuthSession(
          accessToken: tokenResponse.accessToken,
          refreshToken: tokenResponse.refreshToken,
          idToken: tokenResponse.idToken,
          expiresAt:
              tokenResponse.expiresAt ??
              DateTime.now().add(Duration(seconds: tokenResponse.expiresIn)),
          userInfo: userInfo,
        );

        await _saveSession(_currentSession!);
        _apiClient.setAuthToken(_currentSession!.accessToken);

        Logger.info('✅ OAuth2Service: Session created and stored');
        return true;
      }

      return false;
    } catch (e, stackTrace) {
      Logger.error(
        '❌ OAuth2Service: Authorization code callback handling failed',
        'OAuth2Service',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Exchange authorization code for access token
  Future<OAuthTokenResponse?> _exchangeAuthorizationCode({
    required String code,
    required String clientId,
    String? clientSecret,
    required String redirectUrl,
    String? codeVerifier,
  }) async {
    Logger.info('🔄 OAuth2Service: Exchanging authorization code for token');

    try {
      final body = {
        'grant_type': 'authorization_code',
        'client_id': clientId,
        if (clientSecret != null) 'client_secret': clientSecret,
        'code': code,
        'redirect_uri': redirectUrl,
        if (codeVerifier != null) 'code_verifier': codeVerifier,
      };

      Logger.info('📤 OAuth2Service: Sending token request');

      final response = await http.post(
        Uri.parse(OAuthConstants.tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        Logger.info('✅ OAuth2Service: Token received');
        final tokenResponse = OAuthTokenResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
        return tokenResponse;
      } else {
        final error = jsonDecode(response.body);
        Logger.error(
          '❌ OAuth2Service: Token exchange failed - ${error['error_description']}',
          'OAuth2Service',
          Exception(error['error']),
        );
        return null;
      }
    } catch (e, stackTrace) {
      Logger.error(
        '❌ OAuth2Service: Token exchange exception',
        'OAuth2Service',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// Refresh access token using refresh token
  Future<bool> refreshToken() async {
    Logger.info('🔄 OAuth2Service: Refreshing access token');

    if (_currentSession?.refreshToken == null) {
      Logger.warning('⚠️ OAuth2Service: No refresh token available');
      return false;
    }

    try {
      final body = {
        'grant_type': 'refresh_token',
        'client_id': OAuthConstants.clientId,
        'client_secret': OAuthConstants.clientSecret,
        'refresh_token': _currentSession!.refreshToken,
      };

      Logger.info('📤 OAuth2Service: Sending token refresh request');

      final response = await http.post(
        Uri.parse(OAuthConstants.tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        Logger.info('✅ OAuth2Service: Token refreshed successfully');

        final tokenResponse = OAuthTokenResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );

        // Update session
        _currentSession = OAuthSession(
          accessToken: tokenResponse.accessToken,
          refreshToken:
              tokenResponse.refreshToken ?? _currentSession!.refreshToken,
          idToken: _currentSession!.idToken,
          expiresAt:
              tokenResponse.expiresAt ??
              DateTime.now().add(Duration(seconds: tokenResponse.expiresIn)),
          userInfo: _currentSession!.userInfo,
          createdAt: _currentSession!.createdAt,
        );

        await _saveSession(_currentSession!);
        _apiClient.setAuthToken(_currentSession!.accessToken);

        Logger.info('✅ OAuth2Service: Session updated and stored');
        return true;
      } else {
        Logger.error(
          '❌ OAuth2Service: Token refresh failed',
          'OAuth2Service',
          Exception('HTTP ${response.statusCode}'),
        );
        return false;
      }
    } catch (e, stackTrace) {
      Logger.error(
        '❌ OAuth2Service: Token refresh exception',
        'OAuth2Service',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Fetch user information
  Future<OAuthUserInfo?> _fetchUserInfo(String accessToken) async {
    Logger.info('👤 OAuth2Service: Fetching user information');

    try {
      final response = await http.get(
        Uri.parse(OAuthConstants.userInfoUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        Logger.info('✅ OAuth2Service: User info retrieved');
        final userInfo = OAuthUserInfo.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
        Logger.info(
          '👤 OAuth2Service: User: ${userInfo.name} (${userInfo.email})',
        );
        return userInfo;
      } else {
        Logger.warning(
          '⚠️ OAuth2Service: Failed to fetch user info - HTTP ${response.statusCode}',
        );
        return null;
      }
    } catch (e, stackTrace) {
      Logger.error(
        '❌ OAuth2Service: User info fetch failed',
        'OAuth2Service',
        e,
        stackTrace,
      );
      return null;
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

      if (session.refreshToken != null) {
        await _secureStorage.write(
          key: OAuthConstants.refreshTokenKey,
          value: session.refreshToken!,
        );
      }

      if (session.idToken != null) {
        await _secureStorage.write(
          key: OAuthConstants.idTokenKey,
          value: session.idToken!,
        );
      }

      await _secureStorage.write(
        key: OAuthConstants.expiresAtKey,
        value: session.expiresAt.toIso8601String(),
      );

      if (session.userInfo != null) {
        await _secureStorage.write(
          key: OAuthConstants.userInfoKey,
          value: jsonEncode(session.userInfo!.toJson()),
        );
      }

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

      final refreshToken = await _secureStorage.read(
        key: OAuthConstants.refreshTokenKey,
      );
      final idToken = await _secureStorage.read(key: OAuthConstants.idTokenKey);
      final expiresAtStr = await _secureStorage.read(
        key: OAuthConstants.expiresAtKey,
      );
      final userInfoStr = await _secureStorage.read(
        key: OAuthConstants.userInfoKey,
      );

      DateTime expiresAt = DateTime.now().add(const Duration(hours: 1));
      if (expiresAtStr != null) {
        try {
          expiresAt = DateTime.parse(expiresAtStr);
        } catch (e) {
          Logger.warning('⚠️ OAuth2Service: Failed to parse expiration time');
        }
      }

      OAuthUserInfo? userInfo;
      if (userInfoStr != null) {
        try {
          userInfo = OAuthUserInfo.fromJson(
            jsonDecode(userInfoStr) as Map<String, dynamic>,
          );
        } catch (e) {
          Logger.warning('⚠️ OAuth2Service: Failed to parse user info');
        }
      }

      _currentSession = OAuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        idToken: idToken,
        expiresAt: expiresAt,
        userInfo: userInfo,
      );

      Logger.info('✅ OAuth2Service: Session restored');
      _apiClient.setAuthToken(accessToken);
    } catch (e, stackTrace) {
      Logger.error(
        '❌ OAuth2Service: Session restoration failed',
        'OAuth2Service',
        e,
        stackTrace,
      );
    }
  }

  /// Clear session and logout
  Future<void> logout() async {
    Logger.info('🚪 OAuth2Service: Logging out');

    try {
      // Try to revoke token
      if (_currentSession?.accessToken != null) {
        try {
          await _revokeToken(_currentSession!.accessToken);
        } catch (e) {
          Logger.warning(
            '⚠️ OAuth2Service: Token revocation failed, continuing with logout',
          );
        }
      }

      // Clear secure storage
      await _secureStorage.delete(key: OAuthConstants.accessTokenKey);
      await _secureStorage.delete(key: OAuthConstants.refreshTokenKey);
      await _secureStorage.delete(key: OAuthConstants.idTokenKey);
      await _secureStorage.delete(key: OAuthConstants.expiresAtKey);
      await _secureStorage.delete(key: OAuthConstants.userInfoKey);

      // Clear memory
      _currentSession = null;
      _codeVerifier = null;
      _state = null;

      // Clear auth token from API client
      _apiClient.clearAuthToken();

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

  /// Revoke access token
  Future<void> _revokeToken(String token) async {
    Logger.info('🔄 OAuth2Service: Revoking token');

    try {
      final response = await http.post(
        Uri.parse(OAuthConstants.revokeUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'token': token,
          'client_id': OAuthConstants.clientId,
          'client_secret': OAuthConstants.clientSecret,
        },
      );

      if (response.statusCode == 200) {
        Logger.info('✅ OAuth2Service: Token revoked successfully');
      } else {
        Logger.warning(
          '⚠️ OAuth2Service: Token revocation returned HTTP ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      Logger.error(
        '❌ OAuth2Service: Token revocation failed',
        'OAuth2Service',
        e,
        stackTrace,
      );
    }
  }

  /// Check if token needs refresh and refresh if necessary
  Future<void> ensureValidToken() async {
    if (_currentSession == null) {
      Logger.warning('⚠️ OAuth2Service: No active session');
      return;
    }

    if (_currentSession!.shouldRefresh) {
      Logger.info('⚠️ OAuth2Service: Token expiring soon, refreshing');
      await refreshToken();
    } else if (_currentSession!.isExpired) {
      Logger.warning('⚠️ OAuth2Service: Token already expired');
      await logout();
    }
  }
}
