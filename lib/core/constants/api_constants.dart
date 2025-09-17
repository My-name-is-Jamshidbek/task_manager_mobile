class ApiConstants {
  // Base URL for the API
  static const String baseUrl = 'https://tms.amusoft.uz/api';

  // API Endpoints
  static const String login = '/auth/login';
  static const String verify = '/auth/verify';
  static const String resendSms = '/auth/resend-sms';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';

  // Task endpoints
  static const String tasks = '/tasks';
  static const String createTask = '/tasks';
  static const String updateTask = '/tasks'; // + /{id}
  static const String deleteTask = '/tasks'; // + /{id}
  static const String taskById = '/tasks'; // + /{id}

  // Projects endpoints
  static const String projects = '/projects';

  // User endpoints
  static const String profile = '/profile';
  static const String updateProfile = '/profile/update-details';
  static const String changePassword = '/profile/update-password';
  static const String updateAvatar = '/profile/update-avatar';

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
