import '../localization/localization_service.dart';

/// Utility class to handle multilingual API messages
class MultilingualMessage {
  final String? uzbek;
  final String? russian;
  final String? english;

  const MultilingualMessage({this.uzbek, this.russian, this.english});

  /// Creates from API response JSON
  factory MultilingualMessage.fromJson(dynamic json) {
    if (json == null) {
      return const MultilingualMessage();
    }

    // Handle both string and object message formats
    if (json is String) {
      // Fallback for old API format - use the string for all languages
      return MultilingualMessage(uzbek: json, russian: json, english: json);
    }

    if (json is Map<String, dynamic>) {
      return MultilingualMessage(
        uzbek: json['uz'] as String?,
        russian: json['ru'] as String?,
        english: json['en'] as String?,
      );
    }

    return const MultilingualMessage();
  }

  /// Gets the message in the current app language
  String getMessage({String? fallbackLanguage}) {
    final localizationService = LocalizationService();
    final currentLanguage = localizationService.currentLocale.languageCode;

    // Try to get message in current language
    String? message = _getMessageByLanguageCode(currentLanguage);

    // If not found, try fallback language
    if (message == null && fallbackLanguage != null) {
      message = _getMessageByLanguageCode(fallbackLanguage);
    }

    // If still not found, try English as default
    message ??= english;

    // If still not found, try any available language
    message ??= uzbek ?? russian ?? 'Unknown message';

    return message;
  }

  /// Gets message by specific language code
  String? _getMessageByLanguageCode(String languageCode) {
    switch (languageCode) {
      case 'uz':
        return uzbek;
      case 'ru':
        return russian;
      case 'en':
        return english;
      default:
        return null;
    }
  }

  /// Gets message in a specific language
  String getMessageInLanguage(String languageCode) {
    return _getMessageByLanguageCode(languageCode) ?? getMessage();
  }

  /// Checks if any message is available
  bool get hasMessage {
    return uzbek != null || russian != null || english != null;
  }

  /// Returns all available languages for this message
  List<String> get availableLanguages {
    final languages = <String>[];
    if (uzbek != null) languages.add('uz');
    if (russian != null) languages.add('ru');
    if (english != null) languages.add('en');
    return languages;
  }

  /// Converts to JSON format
  Map<String, dynamic> toJson() {
    return {'uz': uzbek, 'ru': russian, 'en': english};
  }

  @override
  String toString() {
    return getMessage();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MultilingualMessage &&
        other.uzbek == uzbek &&
        other.russian == russian &&
        other.english == english;
  }

  @override
  int get hashCode {
    return uzbek.hashCode ^ russian.hashCode ^ english.hashCode;
  }
}
