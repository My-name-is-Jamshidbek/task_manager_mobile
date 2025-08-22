import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, dynamic> _localizedStrings;

  AppLocalizations(this.locale);

  // Helper method to access AppLocalizations instance
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // Static method to get supported locales
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English
    Locale('uz', 'UZ'), // Uzbek
    Locale('ru', 'RU'), // Russian
  ];

  // Load the language JSON file from assets
  Future<bool> load() async {
    try {
      String jsonString = await rootBundle.loadString(
        'assets/translations/${locale.languageCode}.json',
      );
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap;
      return true;
    } catch (e) {
      // Fallback to English if the translation file is not found
      String jsonString = await rootBundle.loadString(
        'assets/translations/en.json',
      );
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap;
      return false;
    }
  }

  // Get translated string by key
  String translate(String key) {
    return _getTranslationByKey(key) ?? key;
  }

  // Get translation by nested key (e.g., "auth.login")
  String? _getTranslationByKey(String key) {
    List<String> keys = key.split('.');
    dynamic current = _localizedStrings;

    for (String k in keys) {
      if (current is Map<String, dynamic> && current.containsKey(k)) {
        current = current[k];
      } else {
        return null;
      }
    }

    return current is String ? current : null;
  }

  // Shortcut method for easier access
  String t(String key) => translate(key);

  // Get current language code
  String get languageCode => locale.languageCode;

  // Check if current language is RTL
  bool get isRTL {
    return locale.languageCode == 'ar' || locale.languageCode == 'fa';
  }
}

// Localization delegate
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
