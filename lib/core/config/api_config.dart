/// API configuration constants
class ApiConfig {
  /// Base URL for the API
  static const String baseUrl = 'https://your-api-domain.com/api';

  /// API version
  static const String version = 'v1';

  /// Full API URL with version
  static String get apiUrl => '$baseUrl/$version';

  /// Timeout duration for HTTP requests
  static const Duration timeout = Duration(seconds: 30);

  /// Request headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Pagination limits
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}
