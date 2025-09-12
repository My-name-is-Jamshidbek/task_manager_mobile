import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';

class ApiService {
  static const String _defaultBaseUrl = 'https://your-api-domain.com/api';

  static Map<String, String> _getHeaders({String? authToken}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    return headers;
  }

  /// Register or update Firebase token
  static Future<Map<String, dynamic>> registerFirebaseToken({
    required String token,
    required String deviceType,
    String? deviceId,
    String? appVersion,
    String? authToken,
    String? baseUrl,
  }) async {
    try {
      final url = Uri.parse('${baseUrl ?? _defaultBaseUrl}/firebase/tokens');

      final body = {
        'token': token,
        'device_type': deviceType,
        if (deviceId != null) 'device_id': deviceId,
        if (appVersion != null) 'app_version': appVersion,
      };

      Logger.info('📤 POST ${url.toString()}');
      Logger.info('📋 Request body: ${jsonEncode(body)}');

      final response = await http.post(
        url,
        headers: _getHeaders(authToken: authToken),
        body: jsonEncode(body),
      );

      Logger.info('📥 Response status: ${response.statusCode}');
      Logger.info('📄 Response body: ${response.body}');

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        Logger.info('✅ Firebase token registered successfully');
        return {'success': true, 'data': responseData['data']};
      } else {
        Logger.error(
          '❌ Failed to register Firebase token: ${response.statusCode}',
        );
        return {
          'success': false,
          'error': responseData['message'] ?? 'Unknown error',
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      Logger.error('❌ API call failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Deactivate Firebase token
  static Future<Map<String, dynamic>> deactivateFirebaseToken({
    required String token,
    String? authToken,
    String? baseUrl,
  }) async {
    try {
      final url = Uri.parse('${baseUrl ?? _defaultBaseUrl}/firebase/tokens');

      final body = {'token': token};

      Logger.info('🗑️ DELETE ${url.toString()}');
      Logger.info('📋 Request body: ${jsonEncode(body)}');

      final request = http.Request('DELETE', url);
      request.headers.addAll(_getHeaders(authToken: authToken));
      request.body = jsonEncode(body);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      Logger.info('📥 Response status: ${response.statusCode}');
      Logger.info('📄 Response body: ${response.body}');

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        Logger.info('✅ Firebase token deactivated successfully');
        return {'success': true, 'message': responseData['message']};
      } else {
        Logger.error(
          '❌ Failed to deactivate Firebase token: ${response.statusCode}',
        );
        return {
          'success': false,
          'error': responseData['message'] ?? 'Unknown error',
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      Logger.error('❌ API call failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Generic GET request
  static Future<Map<String, dynamic>> get({
    required String endpoint,
    String? authToken,
    String? baseUrl,
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse('${baseUrl ?? _defaultBaseUrl}$endpoint');
      final url = queryParams != null
          ? uri.replace(queryParameters: queryParams)
          : uri;

      Logger.info('📤 GET ${url.toString()}');

      final response = await http.get(
        url,
        headers: _getHeaders(authToken: authToken),
      );

      Logger.info('📥 Response status: ${response.statusCode}');

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'status_code': response.statusCode,
        'data': responseData,
      };
    } catch (e) {
      Logger.error('❌ GET request failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Generic POST request
  static Future<Map<String, dynamic>> post({
    required String endpoint,
    required Map<String, dynamic> body,
    String? authToken,
    String? baseUrl,
  }) async {
    try {
      final url = Uri.parse('${baseUrl ?? _defaultBaseUrl}$endpoint');

      Logger.info('📤 POST ${url.toString()}');
      Logger.info('📋 Request body: ${jsonEncode(body)}');

      final response = await http.post(
        url,
        headers: _getHeaders(authToken: authToken),
        body: jsonEncode(body),
      );

      Logger.info('📥 Response status: ${response.statusCode}');

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'status_code': response.statusCode,
        'data': responseData,
      };
    } catch (e) {
      Logger.error('❌ POST request failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Generic PUT request
  static Future<Map<String, dynamic>> put({
    required String endpoint,
    required Map<String, dynamic> body,
    String? authToken,
    String? baseUrl,
  }) async {
    try {
      final url = Uri.parse('${baseUrl ?? _defaultBaseUrl}$endpoint');

      Logger.info('📤 PUT ${url.toString()}');
      Logger.info('📋 Request body: ${jsonEncode(body)}');

      final response = await http.put(
        url,
        headers: _getHeaders(authToken: authToken),
        body: jsonEncode(body),
      );

      Logger.info('📥 Response status: ${response.statusCode}');

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'status_code': response.statusCode,
        'data': responseData,
      };
    } catch (e) {
      Logger.error('❌ PUT request failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Generic DELETE request
  static Future<Map<String, dynamic>> delete({
    required String endpoint,
    Map<String, dynamic>? body,
    String? authToken,
    String? baseUrl,
  }) async {
    try {
      final url = Uri.parse('${baseUrl ?? _defaultBaseUrl}$endpoint');

      Logger.info('🗑️ DELETE ${url.toString()}');
      if (body != null) {
        Logger.info('📋 Request body: ${jsonEncode(body)}');
      }

      final request = http.Request('DELETE', url);
      request.headers.addAll(_getHeaders(authToken: authToken));
      if (body != null) {
        request.body = jsonEncode(body);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      Logger.info('📥 Response status: ${response.statusCode}');

      final responseData = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};

      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'status_code': response.statusCode,
        'data': responseData,
      };
    } catch (e) {
      Logger.error('❌ DELETE request failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
