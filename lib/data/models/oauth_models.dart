import 'package:json_annotation/json_annotation.dart';

part 'oauth_models.g.dart';

/// OAuth 2.0 Token Response
@JsonSerializable()
class OAuthTokenResponse {
  @JsonKey(name: 'access_token')
  final String accessToken;

  @JsonKey(name: 'refresh_token')
  final String? refreshToken;

  @JsonKey(name: 'id_token')
  final String? idToken;

  @JsonKey(name: 'token_type')
  final String tokenType;

  @JsonKey(name: 'expires_in')
  final int expiresIn;

  @JsonKey(name: 'scope')
  final String? scope;

  /// Timestamp when token will expire (UTC)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final DateTime? expiresAt;

  OAuthTokenResponse({
    required this.accessToken,
    this.refreshToken,
    this.idToken,
    required this.tokenType,
    required this.expiresIn,
    this.scope,
    this.expiresAt,
  });

  factory OAuthTokenResponse.fromJson(Map<String, dynamic> json) {
    final response = _$OAuthTokenResponseFromJson(json);
    // Calculate expiration time
    final expiresAt = DateTime.now().add(Duration(seconds: response.expiresIn));
    return OAuthTokenResponse(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      idToken: response.idToken,
      tokenType: response.tokenType,
      expiresIn: response.expiresIn,
      scope: response.scope,
      expiresAt: expiresAt,
    );
  }

  Map<String, dynamic> toJson() => _$OAuthTokenResponseToJson(this);

  /// Check if token is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if token should be refreshed (within 5 minutes of expiry)
  bool get shouldRefresh {
    if (expiresAt == null) return false;
    final refreshThreshold = Duration(minutes: 5);
    return DateTime.now().isAfter(expiresAt!.subtract(refreshThreshold));
  }
}

/// OAuth 2.0 User Info Response
@JsonSerializable()
class OAuthUserInfo {
  final String? sub; // Subject (unique user identifier)
  final String? email;
  @JsonKey(name: 'email_verified')
  final bool? emailVerified;
  final String? name;
  @JsonKey(name: 'given_name')
  final String? givenName;
  @JsonKey(name: 'family_name')
  final String? familyName;
  final String? picture;
  final String? locale;
  final Map<String, dynamic>? extra; // Extra claims from ID token

  OAuthUserInfo({
    this.sub,
    this.email,
    this.emailVerified,
    this.name,
    this.givenName,
    this.familyName,
    this.picture,
    this.locale,
    this.extra,
  });

  factory OAuthUserInfo.fromJson(Map<String, dynamic> json) =>
      _$OAuthUserInfoFromJson(json);

  Map<String, dynamic> toJson() => _$OAuthUserInfoToJson(this);
}

/// OAuth 2.0 Authorization Request (for PKCE flow)
class OAuthAuthorizationRequest {
  final String clientId;
  final String redirectUrl;
  final List<String> scopes;
  final String? state;
  final String? nonce;
  final String? codeChallenge;
  final String? codeChallengeMethod;
  final String responseType;
  final String? prompt; // 'login', 'consent', 'none'
  final Map<String, String>? additionalParameters;

  OAuthAuthorizationRequest({
    required this.clientId,
    required this.redirectUrl,
    required this.scopes,
    this.state,
    this.nonce,
    this.codeChallenge,
    this.codeChallengeMethod = 'S256',
    this.responseType = 'code',
    this.prompt,
    this.additionalParameters,
  });

  /// Build authorization URL
  String buildAuthorizationUrl(String authorizationUrl) {
    final params = <String, String>{
      'client_id': clientId,
      'redirect_uri': redirectUrl,
      'response_type': responseType,
      'scope': scopes.join(' '),
      if (state != null) 'state': state!,
      if (nonce != null) 'nonce': nonce!,
      if (codeChallenge != null) 'code_challenge': codeChallenge!,
      if (codeChallengeMethod != null)
        'code_challenge_method': codeChallengeMethod!,
      if (prompt != null) 'prompt': prompt!,
      ...?additionalParameters,
    };

    final uri = Uri.parse(authorizationUrl);
    return uri.replace(queryParameters: params).toString();
  }
}

/// OAuth 2.0 Token Request (for Authorization Code Exchange)
@JsonSerializable()
class OAuthTokenRequest {
  @JsonKey(name: 'grant_type')
  final String grantType;

  @JsonKey(name: 'client_id')
  final String clientId;

  @JsonKey(name: 'client_secret')
  final String? clientSecret;

  final String? code;

  @JsonKey(name: 'redirect_uri')
  final String redirectUri;

  @JsonKey(name: 'code_verifier')
  final String? codeVerifier;

  @JsonKey(name: 'refresh_token')
  final String? refreshToken;

  final String? scope;

  final Map<String, dynamic>? _extra;

  OAuthTokenRequest({
    required this.grantType,
    required this.clientId,
    this.clientSecret,
    this.code,
    required this.redirectUri,
    this.codeVerifier,
    this.refreshToken,
    this.scope,
    Map<String, dynamic>? extra,
  }) : _extra = extra;

  factory OAuthTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$OAuthTokenRequestFromJson(json);

  Map<String, dynamic> toJson() {
    final json = _$OAuthTokenRequestToJson(this);
    if (_extra != null) {
      json.addAll(_extra);
    }
    return json;
  }
}

/// OAuth 2.0 Authorization Error Response
@JsonSerializable()
class OAuthErrorResponse {
  final String error;
  @JsonKey(name: 'error_description')
  final String? errorDescription;

  @JsonKey(name: 'error_uri')
  final String? errorUri;

  final String? state;

  OAuthErrorResponse({
    required this.error,
    this.errorDescription,
    this.errorUri,
    this.state,
  });

  factory OAuthErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$OAuthErrorResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OAuthErrorResponseToJson(this);

  @override
  String toString() =>
      'OAuthError: $error${errorDescription != null ? ' - $errorDescription' : ''}';
}

/// OAuth 2.0 Authorization Code Response
class OAuthAuthorizationResponse {
  final String code;
  final String? state;
  final String? sessionState;

  OAuthAuthorizationResponse({
    required this.code,
    this.state,
    this.sessionState,
  });
}

/// OAuth Session Information
class OAuthSession {
  final String accessToken;
  final String? refreshToken;
  final String? idToken;
  final DateTime expiresAt;
  final OAuthUserInfo? userInfo;
  final DateTime createdAt;

  OAuthSession({
    required this.accessToken,
    this.refreshToken,
    this.idToken,
    required this.expiresAt,
    this.userInfo,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get shouldRefresh {
    final refreshThreshold = Duration(minutes: 5);
    return DateTime.now().isAfter(expiresAt.subtract(refreshThreshold));
  }

  Duration get timeUntilExpiry {
    final now = DateTime.now();
    return expiresAt.difference(now);
  }
}
