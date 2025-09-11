// Demo to test actual 401 response handling
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../lib/core/services/authentication_manager.dart';
import '../lib/core/api/api_client.dart';
import '../lib/presentation/providers/auth_provider.dart';
import '../lib/core/theme/theme_service.dart';
import '../lib/core/localization/localization_service.dart';
import '../lib/core/localization/app_localizations.dart';
import '../lib/core/utils/navigation_service.dart';
import '../lib/presentation/screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final themeService = ThemeService();
  final localizationService = LocalizationService();
  final authProvider = AuthProvider();

  await themeService.initialize();
  await localizationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider.value(value: localizationService),
        ChangeNotifierProvider.value(value: authProvider),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<ThemeService, LocalizationService, AuthProvider>(
      builder:
          (context, themeService, localizationService, authProvider, child) {
            return MaterialApp(
              navigatorKey: navigatorKey,
              title: 'Auto Logout Demo',
              theme: themeService.lightTheme,
              darkTheme: themeService.darkTheme,
              themeMode: themeService.flutterThemeMode,
              locale: localizationService.currentLocale,
              localizationsDelegates: [AppLocalizationsDelegate()],
              supportedLocales: AppLocalizations.supportedLocales,
              home: AutoLogoutDemoScreen(),
              debugShowCheckedModeBanner: false,
            );
          },
    );
  }
}

class AutoLogoutDemoScreen extends StatefulWidget {
  const AutoLogoutDemoScreen({super.key});

  @override
  _AutoLogoutDemoScreenState createState() => _AutoLogoutDemoScreenState();
}

class _AutoLogoutDemoScreenState extends State<AutoLogoutDemoScreen> {
  String _lastResponse = 'No API calls made yet';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize the authentication manager
    AuthenticationManager().initialize();
  }

  Future<void> _makeApiCall() async {
    setState(() {
      _isLoading = true;
      _lastResponse = 'Making API call...';
    });

    try {
      // Make a test API call that will likely return 401
      final apiClient = ApiClient();

      // Set a fake token to trigger 401
      apiClient.setAuthToken('fake_expired_token_12345');

      final response = await apiClient.get<Map<String, dynamic>>(
        '/profile', // This endpoint should return 401 with fake token
        fromJson: (json) => json,
      );

      if (response.isSuccess) {
        setState(() {
          _lastResponse = 'Success: ${response.data}';
        });
      } else {
        setState(() {
          _lastResponse = 'Error: ${response.error}';
        });
      }
    } catch (e) {
      setState(() {
        _lastResponse = 'Exception: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Auto Logout Demo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Automatic Logout Test',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This demo tests the automatic logout functionality when a 401 (Unauthorized) response is received from any API call.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _makeApiCall,
              icon: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.api),
              label: Text(
                _isLoading
                    ? 'Making API Call...'
                    : 'Test API Call (401 Expected)',
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 20),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last API Response:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    Text(
                      _lastResponse,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'What should happen:',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. API call returns 401 Unauthorized\n'
                      '2. ApiClient detects the 401 response\n'
                      '3. AuthenticationManager triggers automatic logout\n'
                      '4. User is redirected to login screen\n'
                      '5. Session expired message is shown',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            Spacer(),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      onAuthSuccess: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                );
              },
              icon: Icon(Icons.login),
              label: Text('Go to Login Screen'),
            ),
          ],
        ),
      ),
    );
  }
}
