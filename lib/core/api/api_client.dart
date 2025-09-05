import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../utils/logger.dart';
import '../utils/multilingual_message.dart';

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
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final String requestId = _generateRequestId();
    try {
      final uri = _buildUri(endpoint, queryParams);

      // Merge custom headers with default headers
      final finalHeaders = {..._headers};
      if (headers != null) {
        finalHeaders.addAll(headers);
      }

      Logger.info('🚀 [$requestId] GET Request Started');
      Logger.info('📍 [$requestId] URL: $uri');
      Logger.info('📤 [$requestId] Headers: ${_sanitizeHeaders(finalHeaders)}');
      if (queryParams != null && queryParams.isNotEmpty) {
        Logger.info('🔍 [$requestId] Query Params: $queryParams');
      }

      final stopwatch = Stopwatch()..start();
      final response = await _client.get(uri, headers: finalHeaders);
      stopwatch.stop();

      Logger.info(
        '⏱️ [$requestId] Duration: ${stopwatch.elapsedMilliseconds}ms',
      );
      return _handleResponse<T>(response, fromJson, requestId);
    } catch (e, stackTrace) {
      Logger.error(
        '❌ [$requestId] GET Request Failed',
        'ApiClient',
        e,
        stackTrace,
      );
      return ApiResponse.error('Network error: $e');
    }
  }

  // POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final String requestId = _generateRequestId();
    try {
      final uri = _buildUri(endpoint);
      final jsonBody = body != null ? jsonEncode(body) : null;

      // Merge custom headers with default headers
      final finalHeaders = {..._headers};
      if (headers != null) {
        finalHeaders.addAll(headers);
      }

      Logger.info('🚀 [$requestId] POST Request Started');
      Logger.info('📍 [$requestId] URL: $uri');
      Logger.info('📤 [$requestId] Headers: ${_sanitizeHeaders(finalHeaders)}');
      Logger.info('📦 [$requestId] Request Body: ${_sanitizeBody(body)}');

      final stopwatch = Stopwatch()..start();
      final response = await _client.post(
        uri,
        headers: finalHeaders,
        body: jsonBody,
      );
      stopwatch.stop();

      Logger.info(
        '⏱️ [$requestId] Duration: ${stopwatch.elapsedMilliseconds}ms',
      );
      return _handleResponse<T>(response, fromJson, requestId);
    } catch (e, stackTrace) {
      Logger.error(
        '❌ [$requestId] POST Request Failed',
        'ApiClient',
        e,
        stackTrace,
      );
      return ApiResponse.error('Network error: $e');
    }
  }

  // PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final String requestId = _generateRequestId();
    try {
      final uri = _buildUri(endpoint);
      final jsonBody = body != null ? jsonEncode(body) : null;

      Logger.info('🚀 [$requestId] PUT Request Started');
      Logger.info('📍 [$requestId] URL: $uri');
      Logger.info('📤 [$requestId] Headers: ${_sanitizeHeaders(_headers)}');
      Logger.info('📦 [$requestId] Request Body: ${_sanitizeBody(body)}');

      final stopwatch = Stopwatch()..start();
      final response = await _client.put(
        uri,
        headers: _headers,
        body: jsonBody,
      );
      stopwatch.stop();

      Logger.info(
        '⏱️ [$requestId] Duration: ${stopwatch.elapsedMilliseconds}ms',
      );
      return _handleResponse<T>(response, fromJson, requestId);
    } catch (e, stackTrace) {
      Logger.error(
        '❌ [$requestId] PUT Request Failed',
        'ApiClient',
        e,
        stackTrace,
      );
      return ApiResponse.error('Network error: $e');
    }
  }

  // DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final String requestId = _generateRequestId();
    try {
      final uri = _buildUri(endpoint);

      Logger.info('🚀 [$requestId] DELETE Request Started');
      Logger.info('📍 [$requestId] URL: $uri');
      Logger.info('📤 [$requestId] Headers: ${_sanitizeHeaders(_headers)}');

      final stopwatch = Stopwatch()..start();
      final response = await _client.delete(uri, headers: _headers);
      stopwatch.stop();

      Logger.info(
        '⏱️ [$requestId] Duration: ${stopwatch.elapsedMilliseconds}ms',
      );
      return _handleResponse<T>(response, fromJson, requestId);
    } catch (e, stackTrace) {
      Logger.error(
        '❌ [$requestId] DELETE Request Failed',
        'ApiClient',
        e,
        stackTrace,
      );
      return ApiResponse.error('Network error: $e');
    }
  }

  // Multipart POST (file upload)
  Future<ApiResponse<T>> uploadMultipart<T>(
    String endpoint, {
    required Map<String, String> fields,
    required Map<String, http.MultipartFile> files,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final String requestId = _generateRequestId();
    try {
      final uri = _buildUri(endpoint);
      final request = http.MultipartRequest('POST', uri);

      // Headers (exclude json content type)
      final finalHeaders = {..._headers};
      finalHeaders.remove('Content-Type'); // Let multipart set boundary
      if (headers != null) finalHeaders.addAll(headers);
      request.headers.addAll(finalHeaders);

      // Fields
      fields.forEach((k, v) => request.fields[k] = v);
      // Files
      files.forEach((k, file) => request.files.add(file));

      Logger.info('🚀 [$requestId] MULTIPART POST Started');
      Logger.info('📍 [$requestId] URL: $uri');
      Logger.info('📤 [$requestId] Headers: ${_sanitizeHeaders(finalHeaders)}');
      Logger.info('📦 [$requestId] Fields: $fields');
      Logger.info('🖼️ [$requestId] Files: ${files.keys.toList()}');

      final stopwatch = Stopwatch()..start();
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      stopwatch.stop();
      Logger.info(
        '⏱️ [$requestId] Duration: ${stopwatch.elapsedMilliseconds}ms',
      );

      return _handleResponse<T>(response, fromJson, requestId);
    } catch (e, stackTrace) {
      Logger.error(
        '❌ [$requestId] MULTIPART POST Failed',
        'ApiClient',
        e,
        stackTrace,
      );
      return ApiResponse.error('Upload error: $e');
    }
  }

  // Build URI with base URL and query parameters
  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    return Uri.parse(
      '${ApiConstants.baseUrl}$endpoint',
    ).replace(queryParameters: queryParams);
  }

  // Generate unique request ID for tracking
  String _generateRequestId() {
    return 'REQ_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  // Sanitize headers for logging (hide sensitive data)
  Map<String, String> _sanitizeHeaders(Map<String, String> headers) {
    final sanitized = Map<String, String>.from(headers);
    if (sanitized.containsKey('Authorization')) {
      final auth = sanitized['Authorization']!;
      if (auth.length > 20) {
        sanitized['Authorization'] = '${auth.substring(0, 20)}...';
      }
    }
    return sanitized;
  }

  // Sanitize request body for logging (hide sensitive data)
  String _sanitizeBody(Map<String, dynamic>? body) {
    if (body == null) return 'null';

    final sanitized = Map<String, dynamic>.from(body);

    // Hide sensitive fields
    const sensitiveFields = ['password', 'token', 'secret', 'key'];
    for (final field in sensitiveFields) {
      if (sanitized.containsKey(field)) {
        final value = sanitized[field].toString();
        sanitized[field] = value.length > 4
            ? '${value.substring(0, 4)}***'
            : '***';
      }
    }

    return _truncateLog(jsonEncode(sanitized), 500);
  }

  // Truncate log messages to prevent overflow
  String _truncateLog(String message, int maxLength) {
    if (message.length <= maxLength) return message;
    return '${message.substring(0, maxLength)}... [TRUNCATED]';
  }

  // Handle HTTP response
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>)? fromJson,
    String requestId,
  ) {
    Logger.info('📥 [$requestId] Response Status: ${response.statusCode}');
    Logger.info('📥 [$requestId] Response Headers: ${response.headers}');

    // Log response body (truncated if too long)
    final responseBodyLog = _truncateLog(response.body, 1000);
    Logger.info('📥 [$requestId] Response Body: $responseBodyLog');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      Logger.info('✅ [$requestId] Request Successful');
      try {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);

        if (fromJson != null) {
          final data = fromJson(jsonData);
          Logger.info('🎯 [$requestId] Data Parsed Successfully');
          return ApiResponse.success(data);
        } else {
          Logger.info('🎯 [$requestId] Raw JSON Returned');
          return ApiResponse.success(jsonData as T);
        }
      } catch (e, stackTrace) {
        Logger.error(
          '❌ [$requestId] JSON Parse Error',
          'ApiClient',
          e,
          stackTrace,
        );
        return ApiResponse.error('Failed to parse response');
      }
    } else {
      Logger.warning(
        '⚠️ [$requestId] Request Failed with Status: ${response.statusCode}',
      );
      try {
        final Map<String, dynamic> errorData = jsonDecode(response.body);

        // Handle both old and new message formats
        String message;
        if (errorData['message'] != null) {
          final multilingualMessage = MultilingualMessage.fromJson(
            errorData['message'],
          );
          message = multilingualMessage.getMessage();
        } else {
          message = 'Unknown error occurred';
        }

        Logger.error('❌ [$requestId] Error Message: $message');
        return ApiResponse.error(message);
      } catch (e) {
        final errorMessage =
            'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        Logger.error('❌ [$requestId] Error: $errorMessage');
        return ApiResponse.error(errorMessage);
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
