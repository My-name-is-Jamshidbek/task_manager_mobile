import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/core/utils/logger.dart';
import '../lib/data/services/auth_service.dart';
import '../lib/presentation/providers/auth_provider.dart';

/// Full authentication flow test to debug token storage
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.enable();
  Logger.info('🧪 Starting FULL authentication flow test');

  try {
    await testFullAuthFlow();
    Logger.info('✅ All authentication flow tests completed');
  } catch (e, stackTrace) {
    Logger.error('❌ Test failed', 'FullAuthTest', e, stackTrace);
  }
}

/// Test the complete authentication flow
Future<void> testFullAuthFlow() async {
  Logger.info('🧪 Testing complete authentication flow...');

  // Clear any existing auth data first
  await clearStoredAuthData();

  // Step 1: Initialize AuthService and AuthProvider
  final authService = AuthService();
  final authProvider = AuthProvider();

  await authService.initialize();
  await authProvider.initialize();

  Logger.info(
    '🔍 Initial state - AuthService.isLoggedIn: ${authService.isLoggedIn}',
  );
  Logger.info(
    '🔍 Initial state - AuthProvider.isLoggedIn: ${authProvider.isLoggedIn}',
  );

  // Step 2: Test login (should return true but user not logged in yet)
  Logger.info('📞 Testing login step...');
  final testPhone = '+998901234567';
  final testPassword = 'testpass123';

  final loginSuccess = await authProvider.login(testPhone, testPassword);
  Logger.info('🔍 Login result: $loginSuccess');
  Logger.info(
    '🔍 After login - AuthProvider.isLoggedIn: ${authProvider.isLoggedIn}',
  );
  Logger.info(
    '🔍 After login - AuthProvider.currentUser: ${authProvider.currentUser?.name ?? 'NULL'}',
  );

  // Check what's stored after login
  await checkStoredAuthData('After Login');

  // Step 3: Test SMS verification (should store tokens)
  Logger.info('📱 Testing SMS verification step...');
  final testCode = '123456';

  final verifySuccess = await authProvider.verifyCode(testPhone, testCode);
  Logger.info('🔍 Verification result: $verifySuccess');
  Logger.info(
    '🔍 After verification - AuthProvider.isLoggedIn: ${authProvider.isLoggedIn}',
  );
  Logger.info(
    '🔍 After verification - AuthProvider.currentUser: ${authProvider.currentUser?.name ?? 'NULL'}',
  );

  // Check what's stored after verification
  await checkStoredAuthData('After Verification');

  // Step 4: Test app restart simulation
  Logger.info('🔄 Testing app restart simulation...');

  // Create new instances (simulating app restart)
  final newAuthService = AuthService();
  final newAuthProvider = AuthProvider();

  await newAuthService.initialize();
  await newAuthProvider.initialize();

  Logger.info(
    '🔍 After restart - AuthService.isLoggedIn: ${newAuthService.isLoggedIn}',
  );
  Logger.info(
    '🔍 After restart - AuthProvider.isLoggedIn: ${newAuthProvider.isLoggedIn}',
  );
  Logger.info(
    '🔍 After restart - AuthService.currentToken: ${newAuthService.currentToken != null ? 'EXISTS' : 'NULL'}',
  );
  Logger.info(
    '🔍 After restart - AuthService.currentUser: ${newAuthService.currentUser?.name ?? 'NULL'}',
  );

  // Step 5: Test session validation
  Logger.info('🔐 Testing session validation...');
  final sessionValid = await newAuthProvider.checkSession();
  Logger.info('🔍 Session validation result: $sessionValid');

  // Final check of stored data
  await checkStoredAuthData('Final State');
}

/// Check currently stored authentication data
Future<void> checkStoredAuthData(String stage) async {
  Logger.info('🔍 [$stage] Checking stored authentication data...');

  try {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('auth_token');
    final userData = prefs.getString('user_data');
    final phone = prefs.getString('user_phone');

    Logger.info(
      '🔍 [$stage] auth_token: ${token != null ? '${token.substring(0, 20)}...' : 'NULL'}',
    );
    Logger.info(
      '🔍 [$stage] user_data: ${userData != null ? 'EXISTS (${userData.length} chars)' : 'NULL'}',
    );
    Logger.info('🔍 [$stage] user_phone: ${phone ?? 'NULL'}');

    // Show all keys for debugging
    final allKeys = prefs.getKeys();
    Logger.info('🔍 [$stage] All stored keys: ${allKeys.toList()}');
  } catch (e, stackTrace) {
    Logger.error(
      '❌ [$stage] Failed to check stored data',
      'FullAuthTest',
      e,
      stackTrace,
    );
  }
}

/// Clear all stored authentication data
Future<void> clearStoredAuthData() async {
  Logger.info('🧹 Clearing all stored authentication data...');

  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    await prefs.remove('user_phone');

    Logger.info('✅ All authentication data cleared');
  } catch (e, stackTrace) {
    Logger.error(
      '❌ Failed to clear stored data',
      'FullAuthTest',
      e,
      stackTrace,
    );
  }
}
