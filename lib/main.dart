import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// import 'demo/coreui_demo_app.dart';
import 'core/theme/theme_service.dart';
import 'core/localization/localization_service.dart';
import 'core/localization/app_localizations.dart';
import 'core/utils/logger.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging first
  Logger.enable();
  Logger.info('🚀 TaskManager App Starting...');

  // Lock orientation if needed
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  Logger.info('📱 Orientation locked to portrait');

  // Initialize theme and localization services
  final themeService = ThemeService();
  final localizationService = LocalizationService();
  final authProvider = AuthProvider();
  
  Logger.info('⚙️ Initializing services...');
  await themeService.initialize();
  await localizationService.initialize();
  await authProvider.initialize();
  Logger.info('✅ All services initialized successfully');

  // Run Login Screen with theme and localization providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider.value(value: localizationService),
        ChangeNotifierProvider.value(value: authProvider),
      ],
      child: Consumer3<ThemeService, LocalizationService, AuthProvider>(
        builder: (context, themeService, localizationService, authProvider, child) {
          return MaterialApp(
            title: 'Task Manager',
            theme: themeService.lightTheme,
            darkTheme: themeService.darkTheme,
            themeMode: themeService.flutterThemeMode,
            locale: localizationService.currentLocale,
            localizationsDelegates: [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LoginScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    ),
  );
}
