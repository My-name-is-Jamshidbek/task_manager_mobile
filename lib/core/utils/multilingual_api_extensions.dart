import '../utils/multilingual_message.dart';
import '../localization/localization_service.dart';

/// Extensions for working with multilingual API responses
extension MultilingualApiResponseExtensions on Map<String, dynamic> {
  /// Gets a localized message from the response
  String? getLocalizedMessage() {
    final messageData = this['message'];
    if (messageData == null) return null;

    final multilingualMessage = MultilingualMessage.fromJson(messageData);
    return multilingualMessage.getMessage();
  }

  /// Gets a message in a specific language
  String? getMessageInLanguage(String languageCode) {
    final messageData = this['message'];
    if (messageData == null) return null;

    final multilingualMessage = MultilingualMessage.fromJson(messageData);
    return multilingualMessage.getMessageInLanguage(languageCode);
  }

  /// Creates a MultilingualMessage from this response
  MultilingualMessage? get multilingualMessage {
    final messageData = this['message'];
    if (messageData == null) return null;

    return MultilingualMessage.fromJson(messageData);
  }
}

/// Extensions for API error handling with multilingual support
extension ApiErrorExtensions on String? {
  /// Gets a user-friendly error message, preferring API message over translation
  String getDisplayMessage({
    String? fallbackTranslationKey,
    required String Function(String) translate,
  }) {
    // If we have an API message, use it directly
    if (this != null && this!.isNotEmpty) {
      return this!;
    }

    // Otherwise, use the fallback translation
    if (fallbackTranslationKey != null) {
      return translate(fallbackTranslationKey);
    }

    // Final fallback
    return translate('messages.unknownError');
  }
}

/// Utilities for working with multilingual responses
class MultilingualApiUtils {
  /// Extract and localize message from any API response
  static String? extractLocalizedMessage(Map<String, dynamic>? response) {
    if (response == null) return null;
    return response.getLocalizedMessage();
  }

  /// Extract message in specific language from API response
  static String? extractMessageInLanguage(
    Map<String, dynamic>? response,
    String languageCode,
  ) {
    if (response == null) return null;
    return response.getMessageInLanguage(languageCode);
  }

  /// Get current language code for API requests
  static String getCurrentLanguageCode() {
    final localizationService = LocalizationService();
    return localizationService.currentLocale.languageCode;
  }

  /// Get language headers for API requests
  static Map<String, String> getLanguageHeaders() {
    final currentLanguage = getCurrentLanguageCode();
    return {'Accept-Language': currentLanguage, 'X-Locale': currentLanguage};
  }
}
