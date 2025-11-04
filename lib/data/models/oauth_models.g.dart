// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'oauth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OAuthTokenResponse _$OAuthTokenResponseFromJson(Map<String, dynamic> json) =>
    OAuthTokenResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      idToken: json['id_token'] as String?,
      tokenType: json['token_type'] as String,
      expiresIn: (json['expires_in'] as num).toInt(),
      scope: json['scope'] as String?,
    );

Map<String, dynamic> _$OAuthTokenResponseToJson(OAuthTokenResponse instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'id_token': instance.idToken,
      'token_type': instance.tokenType,
      'expires_in': instance.expiresIn,
      'scope': instance.scope,
    };

OAuthUserInfo _$OAuthUserInfoFromJson(Map<String, dynamic> json) =>
    OAuthUserInfo(
      sub: json['sub'] as String?,
      email: json['email'] as String?,
      emailVerified: json['email_verified'] as bool?,
      name: json['name'] as String?,
      givenName: json['given_name'] as String?,
      familyName: json['family_name'] as String?,
      picture: json['picture'] as String?,
      locale: json['locale'] as String?,
      extra: json['extra'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$OAuthUserInfoToJson(OAuthUserInfo instance) =>
    <String, dynamic>{
      'sub': instance.sub,
      'email': instance.email,
      'email_verified': instance.emailVerified,
      'name': instance.name,
      'given_name': instance.givenName,
      'family_name': instance.familyName,
      'picture': instance.picture,
      'locale': instance.locale,
      'extra': instance.extra,
    };

OAuthTokenRequest _$OAuthTokenRequestFromJson(Map<String, dynamic> json) =>
    OAuthTokenRequest(
      grantType: json['grant_type'] as String,
      clientId: json['client_id'] as String,
      clientSecret: json['client_secret'] as String?,
      code: json['code'] as String?,
      redirectUri: json['redirect_uri'] as String,
      codeVerifier: json['code_verifier'] as String?,
      refreshToken: json['refresh_token'] as String?,
      scope: json['scope'] as String?,
    );

Map<String, dynamic> _$OAuthTokenRequestToJson(OAuthTokenRequest instance) =>
    <String, dynamic>{
      'grant_type': instance.grantType,
      'client_id': instance.clientId,
      'client_secret': instance.clientSecret,
      'code': instance.code,
      'redirect_uri': instance.redirectUri,
      'code_verifier': instance.codeVerifier,
      'refresh_token': instance.refreshToken,
      'scope': instance.scope,
    };

OAuthErrorResponse _$OAuthErrorResponseFromJson(Map<String, dynamic> json) =>
    OAuthErrorResponse(
      error: json['error'] as String,
      errorDescription: json['error_description'] as String?,
      errorUri: json['error_uri'] as String?,
      state: json['state'] as String?,
    );

Map<String, dynamic> _$OAuthErrorResponseToJson(OAuthErrorResponse instance) =>
    <String, dynamic>{
      'error': instance.error,
      'error_description': instance.errorDescription,
      'error_uri': instance.errorUri,
      'state': instance.state,
    };
