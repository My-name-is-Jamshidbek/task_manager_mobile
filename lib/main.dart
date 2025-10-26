import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/theme_service.dart';
import 'core/localization/localization_service.dart';
import 'core/localization/app_localizations.dart';
import 'core/utils/logger.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/firebase_provider.dart';
import 'presentation/providers/projects_provider.dart';
import 'presentation/providers/tasks_api_provider.dart';
import 'presentation/providers/dashboard_provider.dart';
import 'presentation/providers/chat_provider.dart';
import 'presentation/providers/contacts_provider.dart';
import 'presentation/providers/conversations_provider.dart';
import 'presentation/providers/conversation_details_provider.dart';
import 'presentation/widgets/app_root.dart';
import 'core/utils/navigation_service.dart';
import 'core/managers/websocket_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging first
  Logger.enable();
  Logger.info('🚀 TaskManager App Starting...');

  // Lock orientation if needed
  // Allow auto-rotate in both portrait and landscape (exclude upside-down if undesired)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  Logger.info('📱 Orientation enabled: portrait + landscape');

  // Initialize theme and localization services
  final themeService = ThemeService();
  final localizationService = LocalizationService();
  final authProvider = AuthProvider();
  final firebaseProvider = FirebaseProvider();
  final projectsProvider = ProjectsProvider();
  final tasksApiProvider = TasksApiProvider();
  final dashboardProvider = DashboardProvider();
  final chatProvider = ChatProvider();
  final contactsProvider = ContactsProvider();
  final conversationsProvider = ConversationsProvider();
  final conversationDetailsProvider = ConversationDetailsProvider();
  Logger.info('⚙️ Initializing basic services...');
  await themeService.initialize();
  await localizationService.initialize();
  await firebaseProvider.initialize();
  // Note: AuthProvider initialization will be handled by AppManager
  Logger.info('✅ Basic services initialized successfully');

  // Initialize Crashlytics
  // Capture unhandled Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Send to Crashlytics in all modes; collection is toggled below
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  // Capture uncaught asynchronous errors from the platform dispatcher
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true; // error handled
  };

  // Enable Crashlytics collection in non-debug builds
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    !kDebugMode,
  );

  // Wrap in zone to capture all Dart errors
  await runZonedGuarded<Future<void>>(
    () async {
      // (navigatorKey imported from navigation_service)
      // Run Login Screen with theme and localization providers
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeService),
            ChangeNotifierProvider.value(value: localizationService),
            ChangeNotifierProvider.value(value: authProvider),
            ChangeNotifierProvider.value(value: firebaseProvider),
            ChangeNotifierProvider.value(value: projectsProvider),
            ChangeNotifierProvider.value(value: tasksApiProvider),
            ChangeNotifierProvider.value(value: dashboardProvider),
            ChangeNotifierProvider.value(value: chatProvider),
            ChangeNotifierProvider.value(value: contactsProvider),
            ChangeNotifierProvider.value(value: conversationsProvider),
            ChangeNotifierProvider.value(value: conversationDetailsProvider),
            ChangeNotifierProvider(
              create: (_) => WebSocketManager(),
              lazy: false,
            ),
          ],
          child:
              Consumer4<
                ThemeService,
                LocalizationService,
                AuthProvider,
                FirebaseProvider
              >(
                builder:
                    (
                      context,
                      themeService,
                      localizationService,
                      authProvider,
                      firebaseProvider,
                      child,
                    ) {
                      return MaterialApp(
                        navigatorKey: navigatorKey,
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
                        home: Builder(
                          builder: (context) =>
                              AppRoot(key: AppRootController.key),
                        ), // Use Builder to ensure proper context
                        debugShowCheckedModeBanner: false,
                      );
                    },
              ),
        ),
      );
    },
    (Object error, StackTrace stack) async {
      // Report all uncaught zones errors
      await FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}
