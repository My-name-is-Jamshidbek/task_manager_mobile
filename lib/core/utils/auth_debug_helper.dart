import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// Debug utility for testing authentication persistence
class AuthDebugHelper {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _phoneKey = 'user_phone';

  /// Print current stored authentication data
  static Future<void> printStoredAuthData() async {
    Logger.info('🔍 AuthDebug: Checking stored authentication data');

    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString(_tokenKey);
      final userData = prefs.getString(_userKey);
      final phone = prefs.getString(_phoneKey);

      Logger.info('📱 AuthDebug: Stored Phone: ${phone ?? 'None'}');
      Logger.info(
        '🔑 AuthDebug: Stored Token: ${token != null ? '${token.substring(0, 20)}...' : 'None'}',
      );
      Logger.info(
        '👤 AuthDebug: Stored User Data: ${userData != null ? 'Present (${userData.length} chars)' : 'None'}',
      );

      if (userData != null) {
        Logger.info(
          '📋 AuthDebug: User Data Preview: ${userData.length > 100 ? '${userData.substring(0, 100)}...' : userData}',
        );
      }
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AuthDebug: Failed to read stored data',
        'AuthDebugHelper',
        e,
        stackTrace,
      );
    }
  }

  /// Clear all stored authentication data (for testing)
  static Future<void> clearAllAuthData() async {
    Logger.info('🧹 AuthDebug: Clearing all stored authentication data');

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      await prefs.remove(_phoneKey);

      Logger.info('✅ AuthDebug: All authentication data cleared');
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AuthDebug: Failed to clear stored data',
        'AuthDebugHelper',
        e,
        stackTrace,
      );
    }
  }

  /// Check if authentication data exists
  static Future<bool> hasStoredAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasToken = prefs.containsKey(_tokenKey);
      final hasUser = prefs.containsKey(_userKey);

      Logger.info('🔍 AuthDebug: Has token: $hasToken, Has user: $hasUser');
      return hasToken && hasUser;
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AuthDebug: Failed to check stored data',
        'AuthDebugHelper',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// Test token persistence flow
  static Future<void> testTokenPersistence() async {
    Logger.info('🧪 AuthDebug: Starting token persistence test');

    await printStoredAuthData();

    Logger.info(
      '🧪 AuthDebug: Token persistence test completed - check logs above',
    );
  }

  /// Test SharedPreferences directly
  static Future<void> testSharedPreferences() async {
    Logger.info('🧪 AuthDebug: Testing SharedPreferences directly');

    try {
      final prefs = await SharedPreferences.getInstance();

      // Test write
      await prefs.setString('test_key', 'test_value');
      Logger.info('✅ AuthDebug: Test write successful');

      // Test read
      final testValue = prefs.getString('test_key');
      Logger.info('📖 AuthDebug: Test read result: $testValue');

      // Clean up
      await prefs.remove('test_key');
      Logger.info('🧹 AuthDebug: Test cleanup completed');
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AuthDebug: SharedPreferences test failed',
        'AuthDebugHelper',
        e,
        stackTrace,
      );
    }
  }
}
