import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/localization_service.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/theme_service.dart';
import '../../core/constants/theme_constants.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/firebase_provider.dart';

class LanguageSettingsWidget extends StatelessWidget {
  const LanguageSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final localizationService = Provider.of<LocalizationService>(context);
    final localizations = AppLocalizations.of(context);

    return SingleChildScrollView(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.translate('demo.languageSettings'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: themeService.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Current Language Display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: themeService.primaryColor.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: themeService.primaryColor.withOpacity(0.05),
                ),
                child: Row(
                  children: [
                    Icon(Icons.language, color: themeService.primaryColor),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.translate(
                            'demo.languages.currentLanguage',
                          ),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: AppThemeConstants.gray600),
                        ),
                        Text(
                          _getLanguageDisplayName(
                            localizationService.currentLocale.languageCode,
                            localizations,
                          ),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Language Selection Tiles
              Text(
                localizations.translate('demo.language'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),

              _buildLanguageTile(
                context,
                'en',
                localizations.translate('demo.languages.english'),
                Icons.public,
                localizationService,
                themeService,
              ),

              _buildLanguageTile(
                context,
                'uz',
                localizations.translate('demo.languages.uzbek'),
                Icons.location_on,
                localizationService,
                themeService,
              ),

              _buildLanguageTile(
                context,
                'ru',
                localizations.translate('demo.languages.russian'),
                Icons.language,
                localizationService,
                themeService,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    String languageCode,
    String languageName,
    IconData icon,
    LocalizationService localizationService,
    ThemeService themeService,
  ) {
    final isSelected =
        localizationService.currentLocale.languageCode == languageCode;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () async {
          if (!isSelected) {
            await localizationService.changeLanguage(languageCode);

            // After language change, update FCM token locale on backend if logged in
            try {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final firebaseProvider = Provider.of<FirebaseProvider>(
                context,
                listen: false,
              );
              final token = authProvider.authToken;
              if (authProvider.isLoggedIn &&
                  token != null &&
                  token.isNotEmpty) {
                await firebaseProvider.updateTokenLocale(
                  authToken: token,
                  locale: languageCode,
                );
              }
            } catch (_) {}

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Language changed to $languageName'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppThemeConstants.success,
                ),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? themeService.primaryColor
                  : AppThemeConstants.gray300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? themeService.primaryColor.withOpacity(0.1)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? themeService.primaryColor
                    : AppThemeConstants.gray600,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  languageName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? themeService.primaryColor : null,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppThemeConstants.success,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLanguageDisplayName(
    String languageCode,
    AppLocalizations? localizations,
  ) {
    switch (languageCode) {
      case 'en':
        return localizations?.translate('demo.languages.english') ?? 'English';
      case 'uz':
        return localizations?.translate('demo.languages.uzbek') ?? 'Uzbek';
      case 'ru':
        return localizations?.translate('demo.languages.russian') ?? 'Russian';
      default:
        return languageCode.toUpperCase();
    }
  }
}
