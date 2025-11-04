import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/oauth_constants.dart';
import '../../core/localization/localization_service.dart';
import '../../core/services/firebase_service.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/multilingual_message.dart';
import '../models/auth_models.dart';
import 'oauth2_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiClient _apiClient = ApiClient();

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _phoneKey = 'user_phone';

  String? _currentToken;
  User? _currentUser;

  // Getters
  String? get currentToken => _currentToken;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentToken != null;

  // Initialize auth service (call on app start)
  Future<void> initialize() async {
    Logger.info('🔐 AuthService: Initializing authentication service');

    try {
      final prefs = await SharedPreferences.getInstance();

      // Debug: Check what keys exist
      final allKeys = prefs.getKeys();
      Logger.info('🔍 AuthService: All stored keys: ${allKeys.toList()}');

      _currentToken = prefs.getString(_tokenKey);
      Logger.info(
        '🔍 AuthService: Raw token from storage: ${_currentToken != null ? '${_currentToken!.substring(0, 20)}...' : 'NULL'}',
      );

      if (_currentToken != null) {
        Logger.info('🔑 AuthService: Found existing token, setting up session');
        _apiClient.setAuthToken(_currentToken!);

        // Try to load user data
        final userJson = prefs.getString(_userKey);
        Logger.info(
          '🔍 AuthService: Raw user data from storage: ${userJson != null ? 'YES (${userJson.length} chars)' : 'NULL'}',
        );

        if (userJson != null) {
          try {
            final userData = jsonDecode(userJson) as Map<String, dynamic>;
            _currentUser = _withNormalizedAvatar(User.fromJson(userData));
            Logger.info(
              '👤 AuthService: User data loaded successfully for ${_currentUser?.name}',
            );
          } catch (e, stackTrace) {
            Logger.error(
              '❌ AuthService: User data corrupted, clearing session',
              'AuthService',
              e,
              stackTrace,
            );
            await clearSession();
          }
        }
      } else {
        Logger.info('🚫 AuthService: No existing token found');
      }
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AuthService: Failed to initialize',
        'AuthService',
        e,
        stackTrace,
      );
      await clearSession();
    }
  }

  // Login with phone number and password
  Future<ApiResponse<LoginResponse>> login(
    String phone,
    String password,
  ) async {
    // Remove + from phone number for API request
    final cleanPhone = phone.replaceAll('+', '');

    Logger.info(
      '🔐 AuthService: Starting login process for phone: ${_sanitizePhone(phone)}',
    );
    Logger.info(
      '📞 AuthService: Cleaned phone (no +): ${_sanitizePhone(cleanPhone)}',
    );

    try {
      final request = LoginRequest(phone: cleanPhone, password: password);

      // Get current language for API headers
      final localizationService = LocalizationService();
      final currentLanguage = localizationService.currentLocale.languageCode;

      Logger.info('🌐 AuthService: Using language: $currentLanguage');

      // Create headers with language preference
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Accept-Language': currentLanguage,
        'X-Locale': currentLanguage,
      };

      Logger.info('📤 AuthService: Sending login request');
      final response = await _apiClient.post<LoginResponse>(
        ApiConstants.login,
        body: request.toJson(),
        headers: headers,
        fromJson: (json) => LoginResponse.fromJson(json),
      );

      if (response.isSuccess && response.data != null) {
        Logger.info('✅ AuthService: Login request successful');

        // Store original phone (with +) for verification step
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_phoneKey, phone);
        Logger.info('💾 AuthService: Phone number stored for verification');

        // If the API returns a token directly (successful login), store it
        final loginData = response.data!;
        Logger.info(
          '🔍 AuthService: Checking login response - hasToken: ${loginData.token != null}, hasUser: ${loginData.user != null}',
        );

        if (loginData.token != null && loginData.user != null) {
          Logger.info(
            '🎯 AuthService: Direct login successful, storing session',
          );
          Logger.info(
            '🔑 AuthService: Token received: ${loginData.token!.substring(0, 20)}...',
          );
          Logger.info('👤 AuthService: User received: ${loginData.user!.name}');
          await _storeSession(loginData.token!, loginData.user!);
        } else {
          Logger.info('📱 AuthService: SMS verification required');
        }
      } else {
        Logger.warning('⚠️ AuthService: Login failed - ${response.error}');
      }

      return response;
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AuthService: Login exception',
        'AuthService',
        e,
        stackTrace,
      );
      return ApiResponse.error('Login failed: $e');
    }
  }

  // Verify SMS code (temporarily bypassed)
  Future<ApiResponse<VerifyResponse>> verifyCode(
    String phone,
    String code,
  ) async {
    // Remove + from phone number for API request
    final cleanPhone = phone.replaceAll('+', '');

    Logger.info(
      '📱 AuthService: Starting SMS verification for phone: ${_sanitizePhone(phone)}',
    );
    Logger.info(
      '� AuthService: Cleaned phone (no +): ${_sanitizePhone(cleanPhone)}',
    );
    Logger.info('�🔢 AuthService: Code length: ${code.length}');

    try {
      // Check if we should use mock verification for testing
      if (_shouldUseMockVerification(phone, code)) {
        Logger.info('⚠️ AuthService: Using mock verification (test mode)');
        return await _mockVerification(phone);
      }

      // Real SMS verification with API
      Logger.info('📤 AuthService: Sending verification request to API');
      final request = VerifyRequest(
        phone: cleanPhone,
        code: code,
      ); // Use cleaned phone
      final response = await _apiClient.post<VerifyResponse>(
        ApiConstants.verify,
        body: request.toJson(),
        fromJson: (json) => VerifyResponse.fromJson(json),
      );

      if (response.isSuccess && response.data != null) {
        Logger.info('✅ AuthService: SMS verification successful');
        final verifyData = response.data!;
        if (verifyData.token != null && verifyData.user != null) {
          await _storeSession(verifyData.token!, verifyData.user!);
        }
      } else {
        Logger.warning(
          '⚠️ AuthService: SMS verification failed - ${response.error}',
        );
      }

      return response;
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AuthService: Verification exception',
        'AuthService',
        e,
        stackTrace,
      );
      return ApiResponse.error('Verification failed: $e');
    }
  }

  // Resend SMS code
  Future<ApiResponse<ResendSmsResponse>> resendSms(String phone) async {
    // Remove + from phone number for API request
    final cleanPhone = phone.replaceAll('+', '');

    Logger.info(
      '📱 AuthService: Resending SMS for phone: ${_sanitizePhone(phone)}',
    );

    try {
      // Check if we should use mock for test numbers
      if (_shouldUseMockVerification(phone, '')) {
        Logger.info('⚠️ AuthService: Using mock resend SMS (test mode)');
        await Future.delayed(const Duration(seconds: 1));

        final response = ResendSmsResponse(
          success: true,
          message: const MultilingualMessage(
            uzbek: 'SMS qayta yuborildi',
            russian: 'SMS отправлено повторно',
            english: 'SMS resent successfully',
          ),
        );

        return ApiResponse.success(data: response);
      }

      // Real resend SMS API call
      Logger.info('📤 AuthService: Sending resend SMS request to API');
      final request = ResendSmsRequest(phone: cleanPhone);
      final response = await _apiClient.post<ResendSmsResponse>(
        ApiConstants.resendSms,
        body: request.toJson(),
        fromJson: (json) => ResendSmsResponse.fromJson(json),
      );

      if (response.isSuccess) {
        Logger.info('✅ AuthService: SMS resent successfully');
      } else {
        Logger.warning('⚠️ AuthService: Resend SMS failed - ${response.error}');
      }

      return response;
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AuthService: Resend SMS exception',
        'AuthService',
        e,
        stackTrace,
      );
      return ApiResponse.error('Resend SMS failed: $e');
    }
  }

  // Store session data
  Future<void> _storeSession(String token, User user) async {
    Logger.info('💾 AuthService: Storing session data for user: ${user.name}');

    _currentToken = token;
    _currentUser = user;

    _apiClient.setAuthToken(token);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      Logger.info('✅ AuthService: Session data stored successfully');

      // Debug: Verify data was actually stored
      final storedToken = prefs.getString(_tokenKey);
      final storedUser = prefs.getString(_userKey);
      Logger.info(
        '🔍 AuthService: Verification - Token stored: ${storedToken != null ? '${storedToken.substring(0, 20)}...' : 'NULL'}',
      );
      Logger.info(
        '🔍 AuthService: Verification - User stored: ${storedUser != null ? 'YES (${storedUser.length} chars)' : 'NULL'}',
      );
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AuthService: Failed to store session data',
        'AuthService',
        e,
        stackTrace,
      );
      rethrow;
    }

    // Ensure FCM token is registered for this session
    try {
      final registered = await FirebaseService().registerTokenWithBackend(
        authToken: token,
      );
      if (!registered) {
        Logger.warning('⚠️ AuthService: Failed to register FCM token');
      }
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AuthService: Error registering FCM token',
        'AuthService',
        e,
        stackTrace,
      );
    }
  }

  // Logout
  Future<void> logout() async {
    Logger.info('🚪 AuthService: Starting logout process');

    try {
      // Try to call logout API if we have a token
      if (_currentToken != null) {
        Logger.info('📤 AuthService: Calling logout API');
        await _apiClient.post(ApiConstants.logout);
        Logger.info('✅ AuthService: Logout API call successful');
      }
    } catch (e, stackTrace) {
      Logger.warning(
        '⚠️ AuthService: Logout API failed, continuing with local cleanup',
      );
      Logger.error(
        '❌ AuthService: Logout API error',
        'AuthService',
        e,
        stackTrace,
      );
    } finally {
      Logger.info('🧹 AuthService: Clearing local session');
      await clearSession();
    }
  }

  // Clear local session
  Future<void> clearSession() async {
    Logger.info('🧹 AuthService: Clearing session data');

    _currentToken = null;
    _currentUser = null;
    _apiClient.clearAuthToken();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      await prefs.remove(_phoneKey);
      Logger.info('✅ AuthService: Session cleared successfully');
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AuthService: Failed to clear session data',
        'AuthService',
        e,
        stackTrace,
      );
    }
  }

  // Get stored phone (for SMS verification)
  Future<String?> getStoredPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString(_phoneKey);
      Logger.info(
        '📱 AuthService: Retrieved stored phone: ${_sanitizePhone(phone)}',
      );
      return phone;
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AuthService: Failed to get stored phone',
        'AuthService',
        e,
        stackTrace,
      );
      return null;
    }
  }

  // Check if user session is valid
  Future<bool> isSessionValid() async {
    Logger.info('🔍 AuthService: Checking session validity');

    if (_currentToken == null) {
      Logger.info('🚫 AuthService: No token found, session invalid');
      return false;
    }

    try {
      // Call the token verification API
      final verifyResult = await verifyToken();
      if (verifyResult.isSuccess && verifyResult.data?.tokenValid == true) {
        Logger.info('✅ AuthService: Session is valid');

        // Update user data if provided in response
        if (verifyResult.data?.user != null) {
          _currentUser = verifyResult.data!.user;
          Logger.info(
            '👤 AuthService: User data updated from token verification',
          );
        }

        return true;
      } else {
        Logger.warning(
          '⚠️ AuthService: Token verification failed - ${verifyResult.error}',
        );
        await clearSession();
        return false;
      }
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AuthService: Session validation failed',
        'AuthService',
        e,
        stackTrace,
      );
      await clearSession();
      return false;
    }
  }

  // Verify current token with server
  Future<ApiResponse<TokenVerifyResponse>> verifyToken() async {
    Logger.info('🔍 AuthService: Verifying current token with server');

    if (_currentToken == null) {
      Logger.warning('⚠️ AuthService: No token to verify');
      return ApiResponse.error('No authentication token found');
    }

    // Development bypass: If using mock token, simulate success
    if (_currentToken!.startsWith('mock_token_')) {
      Logger.info(
        '🧪 AuthService: Mock token detected, bypassing server verification',
      );

      final mockResponse = TokenVerifyResponse(
        message: const MultilingualMessage(
          uzbek: 'Token yaroqli',
          russian: 'Токен действителен',
          english: 'Token is valid',
        ),
        user: _currentUser,
        tokenValid: true,
      );

      Logger.info('✅ AuthService: Mock token verification successful');
      return ApiResponse.success(data: mockResponse);
    }

    try {
      // Set current language for API headers
      final localizationService = LocalizationService();
      final currentLanguage = localizationService.currentLocale.languageCode;

      // Create headers with language preference (token will be auto-added by ApiClient)
      final headers = {
        'Accept-Language': currentLanguage,
        'X-Locale': currentLanguage,
      };

      Logger.info('🌐 AuthService: Using language: $currentLanguage');
      Logger.info('📤 AuthService: Sending token verification request');

      final response = await _apiClient.post<TokenVerifyResponse>(
        ApiConstants.verify,
        headers: headers,
        body: {}, // Empty body for token verification POST request
        fromJson: (json) => TokenVerifyResponse.fromJson(json),
      );

      if (response.isSuccess && response.data != null) {
        Logger.info('✅ AuthService: Token verification successful');

        if (response.data!.tokenValid) {
          Logger.info('🎯 AuthService: Token is valid and active');
        } else {
          Logger.warning('⚠️ AuthService: Token is invalid or expired');
        }
      } else {
        Logger.warning(
          '⚠️ AuthService: Token verification failed - ${response.error}',
        );
      }

      return response;
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AuthService: Token verification exception',
        'AuthService',
        e,
        stackTrace,
      );
      return ApiResponse.error('Token verification failed: $e');
    }
  }

  // Load user profile from API
  Future<ApiResponse<User>> loadUserProfile() async {
    Logger.info('👤 AuthService: Loading user profile from API');

    if (_currentToken == null) {
      Logger.warning('⚠️ AuthService: No token available for profile loading');
      return ApiResponse.error('No authentication token found');
    }

    try {
      // Set current language for API headers
      final localizationService = LocalizationService();
      final currentLanguage = localizationService.currentLocale.languageCode;

      // Create headers with language preference (token will be auto-added by ApiClient)
      final headers = {
        'Accept-Language': currentLanguage,
        'X-Locale': currentLanguage,
      };

      Logger.info('🌐 AuthService: Using language: $currentLanguage');
      Logger.info('📤 AuthService: Sending profile request');

      final response = await _apiClient.get<User>(
        ApiConstants.profile,
        headers: headers,
        fromJson: (json) {
          // Handle nested response structure: {"data": {user_data}}
          final userData = json['data'] ?? json;
          final user = User.fromJson(userData);
          return _withNormalizedAvatar(user);
        },
      );

      if (response.isSuccess && response.data != null) {
        Logger.info(
          '✅ AuthService: Profile loaded successfully for ${response.data!.name}',
        );

        // Update current user data
        _currentUser = response.data!;

        // Store updated user data
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
          Logger.info('💾 AuthService: Updated user data stored');
        } catch (e, stackTrace) {
          Logger.error(
            '❌ AuthService: Failed to store updated user data',
            'AuthService',
            e,
            stackTrace,
          );
        }
      } else {
        Logger.warning(
          '⚠️ AuthService: Profile loading failed - ${response.error}',
        );
      }

      return response;
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AuthService: Profile loading exception',
        'AuthService',
        e,
        stackTrace,
      );
      return ApiResponse.error('Profile loading failed: $e');
    }
  }

  // Update user profile (name and phone)
  Future<ApiResponse<ProfileUpdateResponse>> updateProfile({
    required String name,
    required String phone,
  }) async {
    Logger.info('📝 AuthService: Starting profile update');

    try {
      final response = await _apiClient.post(
        ApiConstants.updateProfile,
        body: {'name': name, 'phone': phone},
        fromJson: (json) => ProfileUpdateResponse.fromJson(json),
      );

      Logger.info('📝 AuthService: Profile update response received');

      if (response.isSuccess && response.data != null) {
        // Update local user data
        _currentUser = _withNormalizedAvatar(response.data!.user);

        // Store updated user data
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
          Logger.info('💾 AuthService: Updated profile data stored');
        } catch (e, stackTrace) {
          Logger.error(
            '❌ AuthService: Failed to store updated profile data',
            'AuthService',
            e,
            stackTrace,
          );
        }

        final localizedMessage = response.data!.getLocalizedMessage();
        if (localizedMessage != null) {
          Logger.info('📝 AuthService: Success message - $localizedMessage');
        }

        return ApiResponse.success(data: response.data!);
      } else {
        Logger.warning(
          '⚠️ AuthService: Profile update failed - ${response.error}',
        );
        return ApiResponse.error(response.error ?? 'Profile update failed');
      }
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AuthService: Profile update exception',
        'AuthService',
        e,
        stackTrace,
      );
      return ApiResponse.error('Profile update failed: $e');
    }
  }

  // Change user password
  Future<ApiResponse<PasswordChangeResponse>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    Logger.info('🔐 AuthService: Starting password change');

    try {
      final response = await _apiClient.post(
        ApiConstants.changePassword,
        body: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        },
        fromJson: (json) => PasswordChangeResponse.fromJson(json),
      );

      Logger.info('🔐 AuthService: Password change response received');

      if (response.isSuccess && response.data != null) {
        Logger.info('✅ AuthService: Password changed successfully');
        final localizedMessage = response.data!.getLocalizedMessage();
        Logger.info('📝 AuthService: Success message - $localizedMessage');
        return ApiResponse.success(data: response.data!);
      } else {
        Logger.warning(
          '⚠️ AuthService: Password change failed - ${response.error}',
        );
        return ApiResponse.error(response.error ?? 'Password change failed');
      }
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AuthService: Password change exception',
        'AuthService',
        e,
        stackTrace,
      );
      return ApiResponse.error('Password change failed: $e');
    }
  }

  // Update avatar (multipart upload)
  Future<ApiResponse<User>> updateAvatar(String filePath) async {
    Logger.info('🖼️ AuthService: Starting avatar upload');
    try {
      final file = await http.MultipartFile.fromPath('avatar', filePath);
      final response = await _apiClient.uploadMultipart<User>(
        ApiConstants.updateAvatar,
        fields: {},
        files: {'avatar': file},
        fromJson: (json) {
          final data = json['data'] ?? json; // handle nested
          final user = User.fromJson(data);
          return _withNormalizedAvatar(user);
        },
      );

      if (response.isSuccess && response.data != null) {
        _currentUser = response.data;
        // persist
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
          Logger.info('💾 AuthService: Stored updated avatar user');
        } catch (e, st) {
          Logger.error(
            '❌ AuthService: Failed storing avatar user',
            'AuthService',
            e,
            st,
          );
        }
      } else {
        Logger.warning(
          '⚠️ AuthService: Avatar upload failed ${response.error}',
        );
      }
      return response;
    } catch (e, st) {
      Logger.error(
        '❌ AuthService: Avatar upload exception',
        'AuthService',
        e,
        st,
      );
      return ApiResponse.error('Avatar upload failed: $e');
    }
  }

  // Helper method to sanitize phone number for logging
  String? _sanitizePhone(String? phone) {
    if (phone == null) return null;
    if (phone.length <= 4) return '***';
    return '${phone.substring(0, 4)}***${phone.substring(phone.length - 2)}';
  }

  // Check if we should use mock verification for testing
  bool _shouldUseMockVerification(String phone, String code) {
    // Use mock verification for test phone numbers or specific test codes
    return phone.contains('test') ||
        phone == '+998901234567' ||
        code == '123456' ||
        code == '000000';
  }

  // Mock verification for testing purposes
  Future<ApiResponse<VerifyResponse>> _mockVerification(String phone) async {
    Logger.info('⚠️ AuthService: Using mock verification (test mode)');
    await Future.delayed(const Duration(seconds: 1));

    // Create a mock successful response (use original phone for user object)
    final mockUser = User(
      id: 1,
      name: 'Test User',
      phone: phone, // Keep original format for user display
      email: 'test@example.com',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final mockToken = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';

    final verifyResponse = VerifyResponse(
      success: true,
      message: const MultilingualMessage(
        uzbek: 'Tasdiqlash muvaffaqiyatli',
        russian: 'Подтверждение успешно',
        english: 'Verification successful',
      ),
      token: mockToken,
      user: mockUser,
    );

    Logger.info('✅ AuthService: Mock verification successful');

    // Store session data
    await _storeSession(mockToken, mockUser);

    return ApiResponse.success(data: verifyResponse);
  }

  // ============================================================================
  // OAuth 2.0 Authentication Methods (RANCH ID)
  // ============================================================================

  /// Login with OAuth 2.0 (RANCH ID)
  Future<ApiResponse<LoginResponse>> loginWithOAuth({
    String? clientId,
    required String redirectUrl,
    List<String>? scopes,
  }) async {
    Logger.info('🚀 AuthService: Starting OAuth 2.0 login flow (RANCH ID)');

    try {
      final oauth2Service = OAuth2Service();

      // Initialize OAuth service
      await oauth2Service.initialize();

      // Start authorization flow
      final success = await oauth2Service.startAuthorizationFlow(
        clientId: clientId,
        redirectUrl: redirectUrl,
        scopes: scopes,
      );

      if (!success) {
        Logger.warning('⚠️ AuthService: OAuth authorization failed');
        return ApiResponse.error('OAuth authorization cancelled');
      }

      Logger.info('✅ AuthService: OAuth authorization successful');

      // Get the session with user info
      final session = oauth2Service.currentSession;
      if (session == null) {
        Logger.error(
          '❌ AuthService: OAuth session not found',
          'AuthService',
          Exception('No OAuth session'),
        );
        return ApiResponse.error('OAuth session not found');
      }

      // Create User object from OAuth user info
      final user = _createUserFromOAuthUserInfo(session.userInfo);

      // Store session using the OAuth token
      await _storeSession(session.accessToken, user);

      Logger.info(
        '✅ AuthService: OAuth login successful for user: ${user.name}',
      );

      // Create response matching existing LoginResponse format
      final loginResponse = LoginResponse(
        success: true,
        message: const MultilingualMessage(
          uzbek: 'OAuth orqali kirish muvaffaqiyatli',
          russian: 'Успешный вход через OAuth',
          english: 'OAuth login successful',
        ),
        token: session.accessToken,
        user: user,
      );

      return ApiResponse.success(data: loginResponse);
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AuthService: OAuth login exception',
        'AuthService',
        e,
        stackTrace,
      );
      return ApiResponse.error('OAuth login failed: $e');
    }
  }

  /// Handle OAuth authorization code callback (for custom flow)
  Future<ApiResponse<LoginResponse>> handleOAuthCallback({
    required String code,
    String? state,
    String? clientId,
    String? clientSecret,
    required String redirectUrl,
  }) async {
    Logger.info('🔄 AuthService: Handling OAuth callback');

    try {
      final oauth2Service = OAuth2Service();

      // Handle the callback
      final success = await oauth2Service.handleAuthorizationCodeCallback(
        code,
        state: state,
        clientId: clientId,
        clientSecret: clientSecret,
        redirectUrl: redirectUrl,
      );

      if (!success) {
        Logger.warning('⚠️ AuthService: OAuth callback handling failed');
        return ApiResponse.error('OAuth callback handling failed');
      }

      // Get the session
      final session = oauth2Service.currentSession;
      if (session == null) {
        return ApiResponse.error('OAuth session not found');
      }

      // Create User from OAuth info
      final user = _createUserFromOAuthUserInfo(session.userInfo);

      // Store session
      await _storeSession(session.accessToken, user);

      Logger.info('✅ AuthService: OAuth callback handled successfully');

      final loginResponse = LoginResponse(
        success: true,
        message: const MultilingualMessage(
          uzbek: 'OAuth orqali kirish muvaffaqiyatli',
          russian: 'Успешный вход через OAuth',
          english: 'OAuth login successful',
        ),
        token: session.accessToken,
        user: user,
      );

      return ApiResponse.success(data: loginResponse);
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AuthService: OAuth callback handling exception',
        'AuthService',
        e,
        stackTrace,
      );
      return ApiResponse.error('OAuth callback handling failed: $e');
    }
  }

  /// Refresh OAuth token
  Future<bool> refreshOAuthToken() async {
    Logger.info('🔄 AuthService: Refreshing OAuth token');

    try {
      final oauth2Service = OAuth2Service();
      await oauth2Service.initialize();

      final success = await oauth2Service.refreshToken();

      if (success && oauth2Service.accessToken != null) {
        // Update stored token
        _currentToken = oauth2Service.accessToken;
        _apiClient.setAuthToken(_currentToken!);

        // Store in preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, _currentToken!);

        Logger.info('✅ AuthService: OAuth token refreshed successfully');
        return true;
      }

      Logger.warning('⚠️ AuthService: OAuth token refresh failed');
      return false;
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AuthService: OAuth token refresh exception',
        'AuthService',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Logout from OAuth session
  Future<void> logoutOAuth() async {
    Logger.info('🚪 AuthService: Logging out from OAuth');

    try {
      final oauth2Service = OAuth2Service();
      await oauth2Service.logout();
      Logger.info('✅ AuthService: OAuth logout successful');
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AuthService: OAuth logout exception',
        'AuthService',
        e,
        stackTrace,
      );
    } finally {
      await clearSession();
    }
  }

  /// Helper: Create User object from OAuth user info
  User _createUserFromOAuthUserInfo(dynamic userInfo) {
    Logger.info('👤 AuthService: Creating user from OAuth info');

    try {
      if (userInfo == null) {
        Logger.warning(
          '⚠️ AuthService: OAuth user info is null, creating default user',
        );
        return User(
          id: 0,
          name: 'OAuth User',
          phone: '',
          email: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      // Parse user info from OAuth
      final name = userInfo.name ?? userInfo.givenName ?? 'OAuth User';
      final email = userInfo.email ?? '';
      final avatar = userInfo.picture;
      final phone = userInfo.sub ?? '';

      Logger.info('👤 AuthService: Created user - Name: $name, Email: $email');

      return User(
        id: 0, // OAuth users might not have a numeric ID from our system
        name: name,
        phone: phone,
        email: email,
        avatar: avatar,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AuthService: Failed to create user from OAuth info',
        'AuthService',
        e,
        stackTrace,
      );
      return User(
        id: 0,
        name: 'OAuth User',
        phone: '',
        email: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Check if using OAuth authentication
  bool get isOAuthAuthenticated {
    // Check if current token looks like an OAuth token (implementation specific)
    return _currentToken != null &&
        (_currentToken!.startsWith(
              'eyJ',
            ) || // JWT tokens typically start with eyJ in base64
            _currentToken!.length > 50); // OAuth tokens are usually long
  }
}

// Normalize avatar URL (convert relative /uploads/... to full URL if base provided)
User _withNormalizedAvatar(User user) {
  try {
    if (user.avatar == null || user.avatar!.isEmpty) return user;
    final avatar = user.avatar!;
    // If already absolute but contains '/api/uploads/', correct it
    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      if (avatar.contains('/api/uploads/')) {
        final fixed = avatar.replaceFirst('/api/uploads/', '/uploads/');
        return user.copyWith(avatar: fixed);
      }
      return user; // Already correct absolute URL
    }

    // Build origin without trailing /api path segment
    final baseUri = Uri.parse(ApiConstants.baseUrl);
    String origin = '${baseUri.scheme}://${baseUri.host}';
    if (baseUri.hasPort) origin += ':${baseUri.port}';
    // If avatar path does not start with '/', add it
    final path = avatar.startsWith('/') ? avatar : '/$avatar';
    final normalized = '$origin$path';
    return User(
      id: user.id,
      name: user.name,
      phone: user.phone,
      email: user.email,
      avatar: normalized,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  } catch (_) {
    return user;
  }
}
