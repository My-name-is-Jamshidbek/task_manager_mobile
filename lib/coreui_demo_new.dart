/// CoreUI Demo - Widget-Based Architecture
/// This file provides a simplified entry point that uses the new widget-based demo structure.
///
/// For the complete widget-based implementation, see:
/// - lib/demo/coreui_demo_app.dart (Main app)
/// - lib/demo/widgets/ (Individual component widgets)
/// - lib/demo/pages/ (Page widgets)
library;

import 'package:flutter/material.dart';
import 'demo/demo_widgets.dart';
import 'core/theme/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeService = ThemeService();
  await themeService.initialize();

  runApp(CoreUIDemo(themeService: themeService));
}
