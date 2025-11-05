/// OAuth 2.0 Configuration Constants (WebView-based SSO)
class OAuthConstants {
  // RANCH ID WebView Authentication URL
  // This is the entry point for the SSO flow
  static const String ssoAuthUrl =
      'https://tms.amusoft.uz/mobile/auth/redirect';

  // Custom URL scheme for handling OAuth callbacks from WebView
  // Format: tmsapp://login-success?token=<token>
  // or: tmsapp://login-failed?error=<error_message>
  static const String customUrlScheme = 'tmsapp';
  static const String loginSuccessPath = 'login-success';
  static const String loginFailedPath = 'login-failed';

  // Query parameter names
  static const String tokenParamName = 'token';
  static const String errorParamName = 'error';

  // Token Storage Keys
  static const String accessTokenKey = 'oauth_access_token';
  static const String expiresAtKey = 'oauth_expires_at';
  static const String userInfoKey = 'oauth_user_info';

  // Security Configuration
  static const bool useSecureStorage = true; // Store tokens securely

  // Timeout Configuration
  static const int tokenRefreshThresholdSeconds =
      300; // Refresh token 5 minutes before expiry
  static const int tokenExpirationCheckIntervalSeconds =
      60; // Check token expiration every minute

  // WebView Configuration
  static const int webViewLoadTimeoutMs = 30000; // 30 seconds

  // Error Messages
  static const String authorizationFailedMessage =
      'Authorization failed. Please try again.';
  static const String tokenFetchFailedMessage =
      'Failed to fetch authentication token.';
  static const String webViewErrorMessage =
      'Failed to load authentication page.';

  // RANCH ID Specific Configuration
  static const String ranchIdName = 'RANCH ID';
  static const String ranchIdDescription =
      'Authentication via RANCH ID provider';
}
