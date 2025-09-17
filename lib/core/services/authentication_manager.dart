import 'package:flutter/material.dart';
import '../utils/logger.dart';
import '../utils/navigation_service.dart';
import '../api/api_client.dart';
import '../localization/app_localizations.dart';
import '../../presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../presentation/widgets/app_root.dart';

/// Service to handle automatic logout and navigation when authentication fails
class AuthenticationManager {
  static final AuthenticationManager _instance =
      AuthenticationManager._internal();
  factory AuthenticationManager() => _instance;
  AuthenticationManager._internal();

  bool _isLoggingOut = false;

  /// Initialize the authentication manager with the API client
  void initialize() {
    Logger.info('🔐 AuthenticationManager: Initializing...');

    // Set up the auth failure callback in ApiClient
    ApiClient().setAuthFailureCallback(_handleAuthenticationFailure);

    Logger.info(
      '✅ AuthenticationManager: Initialized with auth failure callback',
    );
  }

  /// Handle authentication failure by logging out and redirecting to login
  void _handleAuthenticationFailure() async {
    if (_isLoggingOut) {
      Logger.info('🔄 AuthenticationManager: Already logging out, skipping...');
      return;
    }

    _isLoggingOut = true;
    Logger.warning('🚨 AuthenticationManager: Handling authentication failure');

    try {
      // Get the current context from the navigator
      final context = navigatorKey.currentContext;
      if (context == null) {
        Logger.error(
          '❌ AuthenticationManager: No navigation context available',
        );
        _isLoggingOut = false;
        return;
      }

      // Get the AuthProvider and perform logout
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      Logger.info('🔓 AuthenticationManager: Performing logout...');
      await authProvider.logout();

      // Transition via AppRoot state machine for consistency
      Logger.info(
        '🔄 AuthenticationManager: Setting unauthenticated in AppRoot',
      );
      AppRootController.setUnauthenticated();

      // Show a snackbar to inform the user
      _showAuthFailureMessage(context);

      Logger.info(
        '✅ AuthenticationManager: Authentication failure handled successfully',
      );
    } catch (e, stackTrace) {
      Logger.error(
        '❌ AuthenticationManager: Error handling auth failure',
        'AuthenticationManager',
        e,
        stackTrace,
      );
    } finally {
      _isLoggingOut = false;
    }
  }

  /// Show a message to the user about the authentication failure
  void _showAuthFailureMessage(BuildContext context) {
    // Delay the snackbar to ensure the screen is built
    Future.delayed(const Duration(milliseconds: 500), () {
      final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
      if (scaffoldMessenger != null) {
        // Get localized message
        final loc = AppLocalizations.of(context);
        final message = loc.translate('messages.sessionExpired');

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.warning_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }
}
