import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme_service.dart';
import '../core/localization/localization_service.dart';
import '../core/localization/app_localizations.dart';
import 'widgets/demo_navigation.dart';

/// CoreUI Demo Application Main Widget
class CoreUIDemo extends StatelessWidget {
  final ThemeService themeService;
  final LocalizationService localizationService;

  const CoreUIDemo({
    super.key,
    required this.themeService,
    required this.localizationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider.value(value: localizationService),
      ],
      child: Consumer2<ThemeService, LocalizationService>(
        builder: (context, themeService, localizationService, child) {
          return MaterialApp(
            title: 'CoreUI Theme Demo',
            theme: themeService.lightTheme,
            darkTheme: themeService.darkTheme,
            themeMode: themeService.flutterThemeMode,
            themeAnimationDuration: const Duration(milliseconds: 200),
            locale: localizationService.currentLocale,
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const DemoNavigation(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

/// CoreUI Demo Main Entry Point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeService = ThemeService();
  final localizationService = LocalizationService();

  await themeService.initialize();
  await localizationService.initialize();

  runApp(
    CoreUIDemo(
      themeService: themeService,
      localizationService: localizationService,
    ),
  );
}
