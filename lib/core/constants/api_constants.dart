class ApiConstants {
  // Base URL for the API
  static const String baseUrl = 'http://tms.amusoft.uz/api';

  // API Endpoints
  static const String login = '/auth/login';
  static const String verify = '/auth/verify';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';

  // Task endpoints
  static const String tasks = '/tasks';
  static const String createTask = '/tasks';
  static const String updateTask = '/tasks'; // + /{id}
  static const String deleteTask = '/tasks'; // + /{id}
  static const String taskById = '/tasks'; // + /{id}

  // User endpoints
  static const String profile = '/user/profile';
  static const String updateProfile = '/user/profile';

  // Categories endpoints
  static const String categories = '/categories';

  // API Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // API Headers
  static const String contentType = 'application/json';
  static const String accept = 'application/json';
  static const String authorization = 'Authorization';
  static const String bearerPrefix = 'Bearer ';
}
