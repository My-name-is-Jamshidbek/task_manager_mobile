/// Maps API error messages to translation keys
class ApiErrorMapper {
  static const Map<String, String> _errorKeyMap = {
    // Uzbek API errors to translation keys (multiple variations)
    'telefon raqami yoki parol xato': 'messages.invalidCredentials',
    'telefon raqami yoki parol noto\'g\'ri': 'messages.invalidCredentials',
    'telefon raqami va parol xato': 'messages.invalidCredentials',
    'telefon raqami topilmadi': 'messages.phoneNotFound',
    'parol noto\'g\'ri': 'messages.incorrectPassword',
    'parol xato': 'messages.incorrectPassword',
    'foydalanuvchi topilmadi': 'messages.userNotFound',
    'server xatosi': 'messages.serverError',
    'tarmoq xatosi': 'messages.networkError',
    
    // English API errors
    'invalid phone or password': 'messages.invalidCredentials',
    'invalid phone number or password': 'messages.invalidCredentials',
    'phone number not found': 'messages.phoneNotFound',
    'incorrect password': 'messages.incorrectPassword',
    'user not found': 'messages.userNotFound',
    'server error': 'messages.serverError',
    'network error': 'messages.networkError',
    
    // Russian API errors
    'неверный телефон или пароль': 'messages.invalidCredentials',
    'номер телефона не найден': 'messages.phoneNotFound',
    'неверный пароль': 'messages.incorrectPassword',
    'пользователь не найден': 'messages.userNotFound',
    'ошибка сервера': 'messages.serverError',
    'ошибка сети': 'messages.networkError',
  };

  /// Maps API error message to a translation key
  /// Returns the translation key if found, otherwise returns null
  static String? getTranslationKey(String? apiErrorMessage) {
    if (apiErrorMessage == null || apiErrorMessage.isEmpty) {
      return null;
    }
    
    // Try exact match first (case insensitive)
    final lowerMessage = apiErrorMessage.toLowerCase().trim();
    final key = _errorKeyMap[lowerMessage];
    if (key != null) {
      return key;
    }
    
    // Try partial matches for common patterns
    if ((lowerMessage.contains('телефон') && lowerMessage.contains('парол')) ||
        (lowerMessage.contains('phone') && lowerMessage.contains('password')) ||
        (lowerMessage.contains('telefon') && lowerMessage.contains('parol'))) {
      return 'messages.invalidCredentials';
    }
    
    if (lowerMessage.contains('server') || lowerMessage.contains('сервер') || lowerMessage.contains('xato')) {
      return 'messages.serverError';
    }
    
    if (lowerMessage.contains('network') || lowerMessage.contains('tarmoq') || 
        lowerMessage.contains('сеть')) {
      return 'messages.networkError';
    }
    
    return null;
  }
  
  /// Gets a user-friendly error message from API response
  /// Falls back to a generic error message if no mapping is found
  static String getFallbackKey(String? apiErrorMessage) {
    return getTranslationKey(apiErrorMessage) ?? 'messages.loginFailed';
  }
}
