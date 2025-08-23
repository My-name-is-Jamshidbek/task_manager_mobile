import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../utils/logger.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();
  String? _authToken;

  // Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }

  // Clear authentication token
  void clearAuthToken() {
    _authToken = null;
  }

  // Get common headers
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  // GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      Logger.info('GET: $uri');

      final response = await _client.get(uri, headers: _headers);
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      Logger.error('GET Error: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  // POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final jsonBody = body != null ? jsonEncode(body) : null;
      Logger.info('POST: $uri');
      Logger.info('Body: $jsonBody');

      final response = await _client.post(
        uri,
        headers: _headers,
        body: jsonBody,
      );
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      Logger.error('POST Error: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  // PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final jsonBody = body != null ? jsonEncode(body) : null;
      Logger.info('PUT: $uri');

      final response = await _client.put(
        uri,
        headers: _headers,
        body: jsonBody,
      );
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      Logger.error('PUT Error: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  // DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      Logger.info('DELETE: $uri');

      final response = await _client.delete(uri, headers: _headers);
      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      Logger.error('DELETE Error: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  // Build URI with base URL and query parameters
  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    return Uri.parse(
      '${ApiConstants.baseUrl}$endpoint',
    ).replace(queryParameters: queryParams);
  }

  // Handle HTTP response
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    Logger.info('Response Status: ${response.statusCode}');
    Logger.info('Response Body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);

        if (fromJson != null) {
          final data = fromJson(jsonData);
          return ApiResponse.success(data);
        } else {
          return ApiResponse.success(jsonData as T);
        }
      } catch (e) {
        Logger.error('JSON Parse Error: $e');
        return ApiResponse.error('Failed to parse response');
      }
    } else {
      try {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        final message = errorData['message'] ?? 'Unknown error occurred';
        return ApiResponse.error(message);
      } catch (e) {
        return ApiResponse.error(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    }
  }

  // Dispose client
  void dispose() {
    _client.close();
  }
}

// API Response wrapper class
class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  ApiResponse._({this.data, this.error, required this.isSuccess});

  factory ApiResponse.success(T data) {
    return ApiResponse._(data: data, isSuccess: true);
  }

  factory ApiResponse.error(String error) {
    return ApiResponse._(error: error, isSuccess: false);
  }
}
