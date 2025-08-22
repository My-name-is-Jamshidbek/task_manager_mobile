import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/localization_service.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/theme_service.dart';
import '../../core/constants/theme_constants.dart';

/// CoreUI Demo Language Selector Widget
class DemoLanguageSelector extends StatelessWidget {
  const DemoLanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final localizationService = Provider.of<LocalizationService>(context);
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current Language Display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: themeService.primaryColor.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(12),
            color: themeService.primaryColor.withOpacity(0.05),
          ),
          child: Row(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.translate('demo.languages.currentLanguage'),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppThemeConstants.gray600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getLanguageDisplayName(
                        localizationService.currentLocale.languageCode,
                        localizations,
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Text(
          localizations.translate('demo.availableLanguages'),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppThemeConstants.gray700,
          ),
        ),

        const SizedBox(height: 12),

        // Language Options
        Column(
          children: [
            _buildLanguageTile(
              context,
              'en',
              localizations.translate('demo.languages.english'),
              'English',
              Icons.public,
              localizationService,
              themeService,
            ),

            const SizedBox(height: 8),

            _buildLanguageTile(
              context,
              'uz',
              localizations.translate('demo.languages.uzbek'),
              'O\'zbekcha',
              Icons.location_on,
              localizationService,
              themeService,
            ),

            const SizedBox(height: 8),

            _buildLanguageTile(
              context,
              'ru',
              localizations.translate('demo.languages.russian'),
              'Русский',
              Icons.language,
              localizationService,
              themeService,
            ),
          ],
        ),
      ],
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
    final isSelected =
        localizationService.currentLocale.languageCode == languageCode;

    return InkWell(
      onTap: () async {
        if (!isSelected) {
          await localizationService.changeLanguage(languageCode);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Language changed to $localizedName'),
                duration: const Duration(seconds: 2),
                backgroundColor: AppThemeConstants.success,
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

            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppThemeConstants.success,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  String _getLanguageDisplayName(
    String languageCode,
    AppLocalizations localizations,
  ) {
    switch (languageCode) {
      case 'en':
        return localizations.translate('demo.languages.english');
      case 'uz':
        return localizations.translate('demo.languages.uzbek');
      case 'ru':
        return localizations.translate('demo.languages.russian');
      default:
        return languageCode.toUpperCase();
    }
  }
}
