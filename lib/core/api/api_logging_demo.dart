import '../utils/logger.dart';
import 'api_client.dart';

/// Demo class to show API logging functionality
/// 
/// This class demonstrates the enhanced logging features added to the API client.
/// You can use this to test the logging without making actual API calls.
class ApiLoggingDemo {
  final ApiClient _apiClient = ApiClient();

  /// Demonstrates various types of API logging
  Future<void> demonstrateLogging() async {
    Logger.info('🎬 API Logging Demo Started');
    
    // Demo 1: GET request with query parameters
    Logger.info('📊 Demo 1: GET request with query parameters');
    try {
      await _apiClient.get(
        '/users',
        queryParams: {'page': '1', 'limit': '10'},
      );
    } catch (e) {
      // Expected to fail since this is just a demo
    }

    // Demo 2: POST request with body
    Logger.info('📊 Demo 2: POST request with sensitive data');
    try {
      await _apiClient.post(
        '/auth/login',
        body: {
          'phone': '+998901234567',
          'password': 'supersecret123',
          'device_id': 'mobile_device_123'
        },
      );
    } catch (e) {
      // Expected to fail since this is just a demo
    }

    // Demo 3: PUT request
    Logger.info('📊 Demo 3: PUT request');
    try {
      await _apiClient.put(
        '/profile',
        body: {
          'name': 'John Doe',
          'email': 'john@example.com'
        },
      );
    } catch (e) {
      // Expected to fail since this is just a demo
    }

    // Demo 4: DELETE request
    Logger.info('📊 Demo 4: DELETE request');
    try {
      await _apiClient.delete('/tasks/123');
    } catch (e) {
      // Expected to fail since this is just a demo
    }

    Logger.info('🎬 API Logging Demo Completed');
    Logger.info('');
    Logger.info('🔍 Key Logging Features:');
    Logger.info('  ✅ Unique request IDs for tracking');
    Logger.info('  ✅ Request/Response timing');
    Logger.info('  ✅ Headers and body sanitization');
    Logger.info('  ✅ Status codes and error details');
    Logger.info('  ✅ Response body truncation');
    Logger.info('  ✅ Sensitive data masking');
  }

  /// Shows how logging works with different log levels
  void demonstrateLogLevels() {
    Logger.info('🎯 Demonstrating different log levels:');
    
    Logger.info('ℹ️ INFO: General information about API calls');
    Logger.warning('⚠️ WARNING: Non-critical issues like failed requests');
    Logger.error('❌ ERROR: Critical errors with stack traces', 'Demo', 
                 Exception('This is a demo error'));
    Logger.debug('🐛 DEBUG: Detailed debugging information');
  }

  /// Shows request/response logging format
  void showLoggingFormat() {
    Logger.info('📋 API Logging Format Examples:');
    Logger.info('');
    
    Logger.info('🚀 Request Logs:');
    Logger.info('  📍 [REQ_ID] URL: https://api.example.com/endpoint');
    Logger.info('  📤 [REQ_ID] Headers: {Content-Type: application/json, Authorization: Bearer abc...}');
    Logger.info('  📦 [REQ_ID] Request Body: {"phone":"9989***67","password":"supe***"}');
    Logger.info('');
    
    Logger.info('📥 Response Logs:');
    Logger.info('  📥 [REQ_ID] Response Status: 200');
    Logger.info('  📥 [REQ_ID] Response Headers: {content-type: application/json}');
    Logger.info('  📥 [REQ_ID] Response Body: {"success":true,"data":{...}}');
    Logger.info('  ⏱️ [REQ_ID] Duration: 1234ms');
    Logger.info('  ✅ [REQ_ID] Request Successful');
  }
}
