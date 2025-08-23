import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'demo/coreui_demo_app.dart';
import 'core/theme/theme_service.dart';
import 'core/localization/localization_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation if needed
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize theme and localization services
  final themeService = ThemeService();
  final localizationService = LocalizationService();
  await themeService.initialize();
  await localizationService.initialize();

  // Run CoreUI Demo App
  runApp(
    CoreUIDemo(
      themeService: themeService,
      localizationService: localizationService,
    ),
  );
}
