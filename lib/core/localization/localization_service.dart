import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';

class LocalizationService extends ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  static const String _languageKey = 'selected_language';

  Locale _currentLocale = const Locale('en', 'US');

  Locale get currentLocale => _currentLocale;

  // Get supported locales
  List<Locale> get supportedLocales => AppLocalizations.supportedLocales;

  // Initialize localization service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);

    if (languageCode != null) {
      _currentLocale = _getLocaleFromLanguageCode(languageCode);
    } else {
      // Use system locale if supported, otherwise default to English
      final systemLocale = WidgetsBinding.instance.window.locale;
      if (_isLocaleSupported(systemLocale)) {
        _currentLocale = systemLocale;
      }
    }

    notifyListeners();
  }

  // Change language
  Future<void> changeLanguage(String languageCode) async {
    final newLocale = _getLocaleFromLanguageCode(languageCode);
    if (newLocale != _currentLocale) {
      _currentLocale = newLocale;

      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);

      notifyListeners();
    }
  }

  // Get locale from language code
  Locale _getLocaleFromLanguageCode(String languageCode) {
    switch (languageCode) {
      case 'en':
        return const Locale('en', 'US');
      case 'uz':
        return const Locale('uz', 'UZ');
      case 'ru':
        return const Locale('ru', 'RU');
      default:
        return const Locale('en', 'US');
    }
  }

  // Check if locale is supported
  bool _isLocaleSupported(Locale locale) {
    return supportedLocales.any(
      (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
    );
  }

  // Get language name for display
  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'uz':
        return 'O\'zbekcha';
      case 'ru':
        return 'Русский';
      default:
        return 'English';
    }
  }

  // Get all available languages
  List<Map<String, String>> get availableLanguages {
    return [
      {'code': 'en', 'name': 'English', 'nativeName': 'English'},
      {'code': 'uz', 'name': 'Uzbek', 'nativeName': 'O\'zbekcha'},
      {'code': 'ru', 'name': 'Russian', 'nativeName': 'Русский'},
    ];
  }
}

// Extension for easy access to translations
extension BuildContextLocalizations on BuildContext {
  AppLocalizations get localizations => AppLocalizations.of(this);
  String tr(String key) => AppLocalizations.of(this).translate(key);
}
