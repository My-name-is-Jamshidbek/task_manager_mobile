/// OAuth 2.0 Configuration Constants
class OAuthConstants {
  // RANCH ID OAuth Configuration
  static const String authorizationUrl = 'https://tms.amusoft.uz/auth/redirect';
  static const String tokenUrl = 'https://tms.amusoft.uz/oauth/token';
  static const String revokeUrl = 'https://tms.amusoft.uz/oauth/revoke';
  static const String userInfoUrl = 'https://tms.amusoft.uz/api/oauth/user';

  // OAuth Client Configuration
  // Note: These should be configured from backend or secure configuration
  static const String clientId = ''; // Set from backend
  static const String clientSecret = ''; // Set from secure storage/backend
  static const String redirectUrl =
      'uz.amusoft.tms://oauth-callback'; // Custom scheme for deep linking

  // Alternative redirect URLs for different platforms (for development)
  static const String iosRedirectUrl =
      'uz.amusoft.tms://oauth-callback'; // iOS uses custom scheme
  static const String androidRedirectUrl =
      'uz.amusoft.tms://oauth-callback'; // Android uses custom scheme

  // OAuth Scopes
  static const List<String> defaultScopes = [
    'openid',
    'profile',
    'email',
    'offline_access',
  ];

  // Token Storage Keys
  static const String accessTokenKey = 'oauth_access_token';
  static const String refreshTokenKey = 'oauth_refresh_token';
  static const String idTokenKey = 'oauth_id_token';
  static const String expiresAtKey = 'oauth_expires_at';
  static const String userInfoKey = 'oauth_user_info';

  // PKCE Configuration
  static const int pkceCodeVerifierLength = 128;
  static const String pkceCodeChallengeMethod = 'S256'; // SHA256

  // Security Configuration
  static const bool usePKCE = true; // Use Proof Key for Public Clients
  static const bool useSecureStorage = true; // Store tokens securely
  static const bool validateRedirectUrl = true; // Validate redirect URL

  // Timeout Configuration
  static const int tokenRefreshThresholdSeconds =
      300; // Refresh token 5 minutes before expiry
  static const int tokenExpirationCheckIntervalSeconds =
      60; // Check token expiration every minute

  // Error Messages
  static const String authorizationFailedMessage =
      'Authorization failed. Please try again.';
  static const String tokenFetchFailedMessage =
      'Failed to fetch authentication token.';
  static const String tokenRefreshFailedMessage =
      'Failed to refresh authentication token.';
  static const String userInfoFetchFailedMessage =
      'Failed to fetch user information.';

  // RANCH ID Specific Configuration
  static const String ranchIdName = 'RANCH ID';
  static const String ranchIdDescription =
      'Authentication via RANCH ID provider';
  static const String ranchIdAuthProvider =
      'ranch_id'; // Provider identifier for backend
}
