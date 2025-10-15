import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../utils/logger.dart';
import '../utils/multilingual_message.dart';
import '../utils/navigation_service.dart';
import '../../presentation/widgets/error_modal.dart';
import '../localization/app_localizations.dart';

// Callback type for handling authentication failures
typedef AuthFailureCallback = void Function();

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();
  String? _authToken;
  bool _isShowingErrorDialog = false;

  // Callback to handle authentication failures (401 responses)
  AuthFailureCallback? _onAuthFailure;

  // Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }

  // Clear authentication token
  void clearAuthToken() {
    _authToken = null;
  }

  // Current auth token (primarily for testing and diagnostics)
  String? get authToken => _authToken;

  // Set callback for authentication failures
  void setAuthFailureCallback(AuthFailureCallback? callback) {
    _onAuthFailure = callback;
  }

  // Handle authentication failure (401 response)
  void _handleAuthFailure() {
    Logger.warning('🚨 ApiClient: Authentication failure detected (401)');
    clearAuthToken();
    if (_onAuthFailure != null) {
      Logger.info('🔄 ApiClient: Triggering auth failure callback');
      _onAuthFailure!();
    } else {
      Logger.warning('⚠️ ApiClient: No auth failure callback set');
    }
  }

  Map<String, String> _buildHeaders({
    Map<String, String>? headers,
    bool includeAuth = true,
    bool includeJsonContentType = true,
  }) {
    final result = <String, String>{
      if (includeJsonContentType) 'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth && _authToken != null) {
      result['Authorization'] = 'Bearer $_authToken';
    }

    if (headers != null) {
      result.addAll(headers);
    }

    return result;
  }

  // GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    bool includeAuth = true,
    bool showGlobalError = true,
    T Function(Map<String, dynamic>)? fromJson,
    T Function(List<dynamic>)? fromJsonList,
  }) async {
    final String requestId = _generateRequestId();
    try {
      final uri = _buildUri(endpoint, queryParams);

      // Merge custom headers with default headers
      final finalHeaders = _buildHeaders(
        headers: headers,
        includeAuth: includeAuth,
      );

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
      return _handleResponse<T>(
        response,
        fromJson,
        requestId,
        showGlobalError: showGlobalError,
        fromJsonList: fromJsonList,
      );
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

  Future<ApiResponse<BinaryDownloadResult>> downloadBinary(
    String endpoint, {
    Map<String, String>? headers,
    bool includeAuth = true,
  }) async {
    final String requestId = _generateRequestId();
    try {
      final uri = _buildUri(endpoint);
      final finalHeaders = _buildHeaders(
        headers: headers,
        includeAuth: includeAuth,
      );

      Logger.info('🚀 [$requestId] BINARY DOWNLOAD Started');
      Logger.info('📍 [$requestId] URL: $uri');
      Logger.info('📤 [$requestId] Headers: ${_sanitizeHeaders(finalHeaders)}');

      final stopwatch = Stopwatch()..start();
      final response = await _client.get(uri, headers: finalHeaders);
      stopwatch.stop();

      Logger.info(
        '⏱️ [$requestId] Duration: ${stopwatch.elapsedMilliseconds}ms',
      );
      Logger.info('📥 [$requestId] Response Status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final contentType = response.headers['content-type'];
        final fileName = _extractFileName(
          response.headers['content-disposition'],
        );
        Logger.info('✅ [$requestId] Binary download successful');
        return ApiResponse.success(
          data: BinaryDownloadResult(
            bytes: response.bodyBytes,
            contentType: contentType,
            fileName: fileName,
          ),
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode == 401) {
        _handleAuthFailure();
      }

      final errorMessage =
          'Download failed with status ${response.statusCode}: ${response.reasonPhrase}';
      Logger.warning('⚠️ [$requestId] $errorMessage');
      return ApiResponse.error(errorMessage, statusCode: response.statusCode);
    } catch (e, stackTrace) {
      Logger.error(
        '❌ [$requestId] BINARY DOWNLOAD Failed',
        'ApiClient',
        e,
        stackTrace,
      );
      return ApiResponse.error('Binary download error: $e');
    }
  }

  // POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool includeAuth = true,
    bool showGlobalError = true,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final String requestId = _generateRequestId();
    try {
      final uri = _buildUri(endpoint);
      final jsonBody = body != null ? jsonEncode(body) : null;

      final finalHeaders = _buildHeaders(
        headers: headers,
        includeAuth: includeAuth,
      );

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
      return _handleResponse<T>(
        response,
        fromJson,
        requestId,
        showGlobalError: showGlobalError,
      );
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
    Map<String, String>? headers,
    bool includeAuth = true,
    bool showGlobalError = true,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final String requestId = _generateRequestId();
    try {
      final uri = _buildUri(endpoint);
      final jsonBody = body != null ? jsonEncode(body) : null;

      final finalHeaders = _buildHeaders(
        headers: headers,
        includeAuth: includeAuth,
      );

      Logger.info('🚀 [$requestId] PUT Request Started');
      Logger.info('📍 [$requestId] URL: $uri');
      Logger.info('📤 [$requestId] Headers: ${_sanitizeHeaders(finalHeaders)}');
      Logger.info('📦 [$requestId] Request Body: ${_sanitizeBody(body)}');

      final stopwatch = Stopwatch()..start();
      final response = await _client.put(
        uri,
        headers: finalHeaders,
        body: jsonBody,
      );
      stopwatch.stop();

      Logger.info(
        '⏱️ [$requestId] Duration: ${stopwatch.elapsedMilliseconds}ms',
      );
      return _handleResponse<T>(
        response,
        fromJson,
        requestId,
        showGlobalError: showGlobalError,
      );
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

  // PATCH request
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool includeAuth = true,
    bool showGlobalError = true,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final String requestId = _generateRequestId();
    try {
      final uri = _buildUri(endpoint);
      final jsonBody = body != null ? jsonEncode(body) : null;

      final finalHeaders = _buildHeaders(
        headers: headers,
        includeAuth: includeAuth,
      );

      Logger.info('🚀 [$requestId] PATCH Request Started');
      Logger.info('📍 [$requestId] URL: $uri');
      Logger.info('📤 [$requestId] Headers: ${_sanitizeHeaders(finalHeaders)}');
      Logger.info('📦 [$requestId] Request Body: ${_sanitizeBody(body)}');

      final stopwatch = Stopwatch()..start();
      final response = await _client.patch(
        uri,
        headers: finalHeaders,
        body: jsonBody,
      );
      stopwatch.stop();

      Logger.info(
        '⏱️ [$requestId] Duration: ${stopwatch.elapsedMilliseconds}ms',
      );
      return _handleResponse<T>(
        response,
        fromJson,
        requestId,
        showGlobalError: showGlobalError,
      );
    } catch (e, stackTrace) {
      Logger.error(
        '❌ [$requestId] PATCH Request Failed',
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
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool includeAuth = true,
    bool showGlobalError = true,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final String requestId = _generateRequestId();
    try {
      final uri = _buildUri(endpoint);
      final jsonBody = body != null ? jsonEncode(body) : null;
      final finalHeaders = _buildHeaders(
        headers: headers,
        includeAuth: includeAuth,
      );

      Logger.info('🚀 [$requestId] DELETE Request Started');
      Logger.info('📍 [$requestId] URL: $uri');
      Logger.info('📤 [$requestId] Headers: ${_sanitizeHeaders(finalHeaders)}');
      if (body != null && body.isNotEmpty) {
        Logger.info('📦 [$requestId] Request Body: ${_sanitizeBody(body)}');
      }

      final stopwatch = Stopwatch()..start();
      final response = await _client.delete(
        uri,
        headers: finalHeaders,
        body: jsonBody,
      );
      stopwatch.stop();

      Logger.info(
        '⏱️ [$requestId] Duration: ${stopwatch.elapsedMilliseconds}ms',
      );
      return _handleResponse<T>(
        response,
        fromJson,
        requestId,
        showGlobalError: showGlobalError,
      );
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
    bool includeAuth = true,
    bool showGlobalError = true,
    T Function(Map<String, dynamic>)? fromJson,
    String httpMethod = 'POST',
  }) async {
    final String requestId = _generateRequestId();
    try {
      final uri = _buildUri(endpoint);
      final request = http.MultipartRequest(httpMethod.toUpperCase(), uri);

      // Headers (exclude json content type)
      final finalHeaders = _buildHeaders(
        headers: headers,
        includeAuth: includeAuth,
        includeJsonContentType: false,
      );
      request.headers.addAll(finalHeaders);

      // Fields
      fields.forEach((k, v) => request.fields[k] = v);
      // Files
      files.forEach((k, file) => request.files.add(file));

      Logger.info(
        '🚀 [$requestId] MULTIPART ${httpMethod.toUpperCase()} Started',
      );
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

      return _handleResponse<T>(
        response,
        fromJson,
        requestId,
        showGlobalError: showGlobalError,
      );
    } catch (e, stackTrace) {
      Logger.error(
        '❌ [$requestId] MULTIPART ${httpMethod.toUpperCase()} Failed',
        'ApiClient',
        e,
        stackTrace,
      );
      return ApiResponse.error('Upload error: $e');
    }
  }

  // Build URI with base URL and query parameters
  Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    final bool isAbsolute =
        endpoint.startsWith('http://') || endpoint.startsWith('https://');
    final base = isAbsolute ? endpoint : '${ApiConstants.baseUrl}$endpoint';
    final uri = Uri.parse(base);
    if (queryParams == null || queryParams.isEmpty) {
      return uri;
    }
    final combined = {...uri.queryParameters, ...queryParams};
    return uri.replace(queryParameters: combined);
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
    String requestId, {
    T Function(List<dynamic>)? fromJsonList,
    bool showGlobalError = true,
  }) {
    Logger.info('📥 [$requestId] Response Status: ${response.statusCode}');
    Logger.info('📥 [$requestId] Response Headers: ${response.headers}');

    // Log response body (truncated if too long)
    final rawBody = response.body;
    final trimmedBody = rawBody.trim();
    final responseBodyLog = _truncateLog(rawBody, 1000);
    Logger.info('📥 [$requestId] Response Body: $responseBodyLog');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      Logger.info('✅ [$requestId] Request Successful');
      try {
        if (trimmedBody.isEmpty) {
          Logger.info('🎯 [$requestId] Empty response body');
          return ApiResponse.success(statusCode: response.statusCode);
        }

        final dynamic decoded = jsonDecode(trimmedBody);

        if (decoded is List) {
          if (fromJsonList != null) {
            final data = fromJsonList(decoded);
            Logger.info('🎯 [$requestId] List Parsed Successfully');
            return ApiResponse.success(
              data: data,
              statusCode: response.statusCode,
            );
          }
          Logger.info('🎯 [$requestId] Raw JSON List Returned');
          return ApiResponse.success(
            data: decoded as T,
            statusCode: response.statusCode,
          );
        } else if (decoded is Map<String, dynamic>) {
          // If caller expects a list (provided fromJsonList) but server
          // returned an envelope like { data: [...], meta: {...} }
          if (fromJsonList != null) {
            final dynamic maybeList = decoded['data'];
            if (maybeList is List) {
              final data = fromJsonList(maybeList);
              Logger.info('🎯 [$requestId] Envelope List Parsed Successfully');
              return ApiResponse.success(
                data: data,
                statusCode: response.statusCode,
              );
            }
          }
          if (fromJson != null) {
            final data = fromJson(decoded);
            Logger.info('🎯 [$requestId] Object Parsed Successfully');
            return ApiResponse.success(
              data: data,
              statusCode: response.statusCode,
            );
          }
          Logger.info('🎯 [$requestId] Raw JSON Object Returned');
          return ApiResponse.success(
            data: decoded as T,
            statusCode: response.statusCode,
          );
        } else {
          Logger.warning(
            '⚠️ [$requestId] Unexpected JSON type: ${decoded.runtimeType}',
          );
          return ApiResponse.error(
            'Unexpected response type',
            statusCode: response.statusCode,
          );
        }
      } catch (e, stackTrace) {
        Logger.error(
          '❌ [$requestId] JSON Parse Error',
          'ApiClient',
          e,
          stackTrace,
        );
        final ctx = navigatorKey.currentContext;
        final loc = ctx != null ? AppLocalizations.of(ctx) : null;
        if (showGlobalError) {
          _showGlobalError(
            title: loc?.translate('common.error') ?? 'Error',
            message:
                loc?.translate('messages.unexpectedError') ??
                'Unexpected error',
            details: 'Request: $requestId\n$trimmedBody',
          );
        }
        return ApiResponse.error(
          'Failed to parse response',
          statusCode: response.statusCode,
        );
      }
    } else {
      Logger.warning(
        '⚠️ [$requestId] Request Failed with Status: ${response.statusCode}',
      );

      // Handle 401 Unauthorized responses - trigger automatic logout
      if (response.statusCode == 401) {
        Logger.warning('🚨 [$requestId] Unauthorized response detected');
        _handleAuthFailure();
      }

      try {
        if (trimmedBody.isEmpty) {
          final errorMessage =
              'HTTP ${response.statusCode}: ${response.reasonPhrase}';
          Logger.error('❌ [$requestId] Error: $errorMessage');
          if (response.statusCode != 401) {
            if (showGlobalError) {
              final ctx = navigatorKey.currentContext;
              final loc = ctx != null ? AppLocalizations.of(ctx) : null;
              _showGlobalError(
                title: loc?.translate('common.error') ?? 'Error',
                message: errorMessage,
                details: 'HTTP ${response.statusCode}: <empty body>',
              );
            }
          }
          return ApiResponse.error(
            errorMessage,
            statusCode: response.statusCode,
          );
        }

        final Map<String, dynamic> errorData = jsonDecode(trimmedBody);

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
        if (response.statusCode != 401) {
          if (showGlobalError) {
            final ctx = navigatorKey.currentContext;
            final loc = ctx != null ? AppLocalizations.of(ctx) : null;
            _showGlobalError(
              title: loc?.translate('common.error') ?? 'Error',
              message: message,
              details:
                  'HTTP ${response.statusCode}: ${_truncateLog(trimmedBody, 1000)}',
            );
          }
        }
        return ApiResponse.error(message, statusCode: response.statusCode);
      } catch (e) {
        final errorMessage =
            'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        Logger.error('❌ [$requestId] Error: $errorMessage');
        if (response.statusCode != 401) {
          if (showGlobalError) {
            final ctx = navigatorKey.currentContext;
            final loc = ctx != null ? AppLocalizations.of(ctx) : null;
            _showGlobalError(
              title: loc?.translate('common.error') ?? 'Error',
              message: errorMessage,
              details:
                  'HTTP ${response.statusCode}: ${_truncateLog(trimmedBody, 1000)}',
            );
          }
        }
        return ApiResponse.error(errorMessage, statusCode: response.statusCode);
      }
    }
  }

  void _showGlobalError({
    required String title,
    required String message,
    String? details,
  }) async {
    if (_isShowingErrorDialog) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    _isShowingErrorDialog = true;
    try {
      await showErrorModal(
        ctx,
        title: title,
        message: message,
        details: details,
        onMore: null,
        onClose: () {},
      );
    } catch (e) {
      Logger.error('❌ ApiClient: Failed to show error dialog', 'ApiClient', e);
    } finally {
      _isShowingErrorDialog = false;
    }
  }

  // Dispose client
  void dispose() {
    _client.close();
  }

  String? _extractFileName(String? contentDisposition) {
    if (contentDisposition == null) return null;
    final segments = contentDisposition.split(';').map((s) => s.trim());
    for (final segment in segments) {
      if (segment.toLowerCase().startsWith('filename=')) {
        return segment.substring(9).replaceAll('"', '');
      }
    }
    return null;
  }
}

// API Response wrapper class
class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;
  final int? statusCode;

  ApiResponse._({
    this.data,
    this.error,
    required this.isSuccess,
    this.statusCode,
  });

  factory ApiResponse.success({T? data, int? statusCode}) {
    return ApiResponse._(data: data, isSuccess: true, statusCode: statusCode);
  }

  factory ApiResponse.error(String error, {int? statusCode}) {
    return ApiResponse._(
      error: error,
      isSuccess: false,
      statusCode: statusCode,
    );
  }
}

class BinaryDownloadResult {
  final Uint8List bytes;
  final String? contentType;
  final String? fileName;

  const BinaryDownloadResult({
    required this.bytes,
    this.contentType,
    this.fileName,
  });
}
