import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/localization/localization_service.dart';
import '../../core/utils/logger.dart';
import '../models/auth_models.dart';

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
      _currentToken = prefs.getString(_tokenKey);
      
      if (_currentToken != null) {
        Logger.info('🔑 AuthService: Found existing token, setting up session');
        _apiClient.setAuthToken(_currentToken!);
        
        // Try to load user data
        final userJson = prefs.getString(_userKey);
        if (userJson != null) {
          try {
            final userData = Map<String, dynamic>.from(
              Map.from(Uri.splitQueryString(userJson))
            );
            _currentUser = User.fromJson(userData);
            Logger.info('👤 AuthService: User data loaded successfully for ${_currentUser?.name}');
          } catch (e, stackTrace) {
            Logger.error('❌ AuthService: User data corrupted, clearing session', 'AuthService', e, stackTrace);
            await clearSession();
          }
        }
      } else {
        Logger.info('🚫 AuthService: No existing token found');
      }
    } catch (e, stackTrace) {
      Logger.error('❌ AuthService: Failed to initialize', 'AuthService', e, stackTrace);
      await clearSession();
    }
  }

  // Login with phone number and password
  Future<ApiResponse<LoginResponse>> login(String phone, String password) async {
    // Remove + from phone number for API request
    final cleanPhone = phone.replaceAll('+', '');
    
    Logger.info('🔐 AuthService: Starting login process for phone: ${_sanitizePhone(phone)}');
    Logger.info('📞 AuthService: Cleaned phone (no +): ${_sanitizePhone(cleanPhone)}');
    
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
        if (loginData.token != null && loginData.user != null) {
          Logger.info('🎯 AuthService: Direct login successful, storing session');
          await _storeSession(loginData.token!, loginData.user!);
        } else {
          Logger.info('📱 AuthService: SMS verification required');
        }
      } else {
        Logger.warning('⚠️ AuthService: Login failed - ${response.error}');
      }

      return response;
    } catch (e, stackTrace) {
      Logger.error('❌ AuthService: Login exception', 'AuthService', e, stackTrace);
      return ApiResponse.error('Login failed: $e');
    }
  }

  // Verify SMS code (temporarily bypassed)
  Future<ApiResponse<VerifyResponse>> verifyCode(String phone, String code) async {
    // Remove + from phone number for API request
    final cleanPhone = phone.replaceAll('+', '');
    
    Logger.info('📱 AuthService: Starting SMS verification for phone: ${_sanitizePhone(phone)}');
    Logger.info('� AuthService: Cleaned phone (no +): ${_sanitizePhone(cleanPhone)}');
    Logger.info('�🔢 AuthService: Code length: ${code.length}');
    
    try {
      // For now, we'll bypass the actual SMS verification
      // and simulate a successful response
      Logger.info('⚠️ AuthService: Using mock verification (bypass mode)');
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
        message: 'Verification successful',
        token: mockToken,
        user: mockUser,
      );

      Logger.info('✅ AuthService: Mock verification successful');
      
      // Store session data
      await _storeSession(mockToken, mockUser);

      return ApiResponse.success(verifyResponse);
      
      /* 
      // TODO: Uncomment this when SMS verification API is ready
      Logger.info('📤 AuthService: Sending verification request');
      final request = VerifyRequest(phone: cleanPhone, code: code); // Use cleaned phone
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
        Logger.warning('⚠️ AuthService: SMS verification failed - ${response.error}');
      }

      return response;
      */
    } catch (e, stackTrace) {
      Logger.error('❌ AuthService: Verification exception', 'AuthService', e, stackTrace);
      return ApiResponse.error('Verification failed: $e');
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
      await prefs.setString(_userKey, user.toJson().toString());
      Logger.info('✅ AuthService: Session data stored successfully');
    } catch (e, stackTrace) {
      Logger.error('❌ AuthService: Failed to store session data', 'AuthService', e, stackTrace);
      throw e;
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
      Logger.warning('⚠️ AuthService: Logout API failed, continuing with local cleanup');
      Logger.error('❌ AuthService: Logout API error', 'AuthService', e, stackTrace);
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
      Logger.error('❌ AuthService: Failed to clear session data', 'AuthService', e, stackTrace);
    }
  }

  // Get stored phone (for SMS verification)
  Future<String?> getStoredPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString(_phoneKey);
      Logger.info('📱 AuthService: Retrieved stored phone: ${_sanitizePhone(phone)}');
      return phone;
    } catch (e, stackTrace) {
      Logger.error('❌ AuthService: Failed to get stored phone', 'AuthService', e, stackTrace);
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
      // You can add a profile check API call here
      // For now, just return true if token exists
      Logger.info('✅ AuthService: Session is valid');
      return true;
    } catch (e, stackTrace) {
      Logger.error('❌ AuthService: Session validation failed', 'AuthService', e, stackTrace);
      await clearSession();
      return false;
    }
  }

  // Helper method to sanitize phone number for logging
  String? _sanitizePhone(String? phone) {
    if (phone == null) return null;
    if (phone.length <= 4) return '***';
    return '${phone.substring(0, 4)}***${phone.substring(phone.length - 2)}';
  }
}
