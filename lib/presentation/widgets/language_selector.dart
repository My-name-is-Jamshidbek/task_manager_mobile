import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/localization_service.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/theme_service.dart';
import '../../core/constants/theme_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/firebase_provider.dart';

/// Language Selector Widget - Optimized for bottom sheet
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final localizationService = Provider.of<LocalizationService>(context);
    final localizations = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeService.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.language,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  localizations.translate('settings.language'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Language Options
          Column(
            children: [
              _buildLanguageTile(
                context,
                'en',
                localizations.translate('settings.languageOptions.english'),
                'English',
                Icons.public,
                localizationService,
                themeService,
              ),

              const SizedBox(height: 12),

              _buildLanguageTile(
                context,
                'uz',
                localizations.translate('settings.languageOptions.uzbek'),
                'O\'zbekcha',
                Icons.location_on,
                localizationService,
                themeService,
              ),

              const SizedBox(height: 12),

              _buildLanguageTile(
                context,
                'ru',
                localizations.translate('settings.languageOptions.russian'),
                'Русский',
                Icons.language,
                localizationService,
                themeService,
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    String languageCode,
    String localizedName,
    String nativeName,
    IconData icon,
    LocalizationService localizationService,
    ThemeService themeService,
  ) {
    final localizations = AppLocalizations.of(context);
    final isSelected =
        localizationService.currentLocale.languageCode == languageCode;

    return InkWell(
      onTap: () async {
        if (!isSelected) {
          await localizationService.changeLanguage(languageCode);

          // After language change, update FCM token locale on backend if logged in
          try {
            // Access providers without rebuilding
            final authProvider =
                Provider.of<
                  // ignore: use_build_context_synchronously
                  AuthProvider
                >(context, listen: false);
            final firebaseProvider =
                Provider.of<
                  // ignore: use_build_context_synchronously
                  FirebaseProvider
                >(context, listen: false);

            final token = authProvider.authToken;
            if (authProvider.isLoggedIn && token != null && token.isNotEmpty) {
              // Best-effort, don't block UI; wait but ignore result
              await firebaseProvider.updateTokenLocale(
                authToken: token,
                locale: languageCode,
              );
            }
          } catch (_) {
            // Silent catch; localization change should not fail due to this
          }

          if (context.mounted) {
            Navigator.of(context).pop(); // Close the modal

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  localizations.translateWithParams(
                    'settings.languageChanged',
                    {'language': localizedName},
                  ),
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? themeService.primaryColor
                : AppThemeConstants.gray300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? themeService.primaryColor.withOpacity(0.08)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? themeService.primaryColor
                    : AppThemeConstants.gray400,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizedName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected ? themeService.primaryColor : null,
                    ),
                  ),
                  Text(
                    nativeName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppThemeConstants.gray600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
