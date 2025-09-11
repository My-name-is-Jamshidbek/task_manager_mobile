import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/core/utils/logger.dart';
import '../lib/core/utils/auth_debug_helper.dart';
import '../lib/data/services/auth_service.dart';

/// Test script to debug authentication token storage
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.enable();
  Logger.info('🧪 Starting authentication storage test');

  try {
    // Test 1: Check SharedPreferences directly
    await testSharedPreferences();

    // Test 2: Check current stored data
    await AuthDebugHelper.printStoredAuthData();

    // Test 3: Test AuthService initialization
    await testAuthServiceInitialization();

    // Test 4: Test token persistence
    await AuthDebugHelper.testTokenPersistence();

    Logger.info('✅ All tests completed');
  } catch (e, stackTrace) {
    Logger.error('❌ Test failed', 'TestMain', e, stackTrace);
  }
}

/// Test SharedPreferences directly
Future<void> testSharedPreferences() async {
  Logger.info('🧪 Testing SharedPreferences directly...');

  try {
    final prefs = await SharedPreferences.getInstance();

    // Test write
    await prefs.setString('test_token', 'test_token_value_123');
    await prefs.setString('test_user', '{"name": "Test User", "id": 1}');

    Logger.info('✅ Test data written successfully');

    // Test read
    final token = prefs.getString('test_token');
    final user = prefs.getString('test_user');

    Logger.info('📖 Test token read: $token');
    Logger.info('📖 Test user read: $user');

    // Check if actual auth keys exist
    final authToken = prefs.getString('auth_token');
    final authUser = prefs.getString('user_data');
    final authPhone = prefs.getString('user_phone');

    Logger.info('🔍 Real auth_token: ${authToken ?? 'NULL'}');
    Logger.info(
      '🔍 Real user_data: ${authUser != null ? 'EXISTS (${authUser.length} chars)' : 'NULL'}',
    );
    Logger.info('🔍 Real user_phone: ${authPhone ?? 'NULL'}');

    // Clean up test data
    await prefs.remove('test_token');
    await prefs.remove('test_user');

    Logger.info('✅ SharedPreferences test completed');
  } catch (e, stackTrace) {
    Logger.error('❌ SharedPreferences test failed', 'TestMain', e, stackTrace);
  }
}

/// Test AuthService initialization
Future<void> testAuthServiceInitialization() async {
  Logger.info('🧪 Testing AuthService initialization...');

  try {
    final authService = AuthService();
    await authService.initialize();

    Logger.info('🔍 AuthService.isLoggedIn: ${authService.isLoggedIn}');
    Logger.info(
      '🔍 AuthService.currentToken: ${authService.currentToken != null ? 'EXISTS' : 'NULL'}',
    );
    Logger.info(
      '🔍 AuthService.currentUser: ${authService.currentUser?.name ?? 'NULL'}',
    );

    Logger.info('✅ AuthService initialization test completed');
  } catch (e, stackTrace) {
    Logger.error(
      '❌ AuthService initialization test failed',
      'TestMain',
      e,
      stackTrace,
    );
  }
}
