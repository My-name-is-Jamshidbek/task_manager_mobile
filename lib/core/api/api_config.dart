class ApiConfig {
  static const String baseUrl = 'http://mobile.tms.thejoma.uz/api';
  
  // Auth endpoints
  static const String loginEndpoint = '/auth/login';
  static const String verifyEndpoint = '/auth/verify';
  static const String logoutEndpoint = '/auth/logout';
  
  // Tasks endpoints
  static const String tasksEndpoint = '/tasks';
  
  // Projects endpoints
  static const String projectsEndpoint = '/projects';
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static Map<String, String> getAuthHeaders(String token) {
    return {
      ...defaultHeaders,
      'Authorization': 'Bearer $token',
    };
  }
}
