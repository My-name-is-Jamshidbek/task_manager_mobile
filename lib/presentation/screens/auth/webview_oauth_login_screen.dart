import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/constants/oauth_constants.dart';
import '../../../core/utils/logger.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_app_bar.dart';

/// WebView-based OAuth Login Screen - Login with RANCH ID via SSO
class WebViewOAuthLoginScreen extends StatefulWidget {
  final VoidCallback? onAuthSuccess;
  final VoidCallback? onBackToTraditional;

  const WebViewOAuthLoginScreen({
    super.key,
    this.onAuthSuccess,
    this.onBackToTraditional,
  });

  @override
  State<WebViewOAuthLoginScreen> createState() =>
      _WebViewOAuthLoginScreenState();
}

class _WebViewOAuthLoginScreenState extends State<WebViewOAuthLoginScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Logger.info('🚀 WebViewOAuthLoginScreen: Initialized');
    _initializeWebView();
  }

  void _initializeWebView() {
    Logger.info('🌐 WebViewOAuthLoginScreen: Initializing WebView');

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            Logger.info('🌐 WebViewOAuthLoginScreen: Page started: $url');
            setState(() => _isLoading = true);
            _handleUrlRedirect(url);
          },
          onPageFinished: (String url) {
            Logger.info('🌐 WebViewOAuthLoginScreen: Page finished: $url');
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            Logger.error(
              '❌ WebViewOAuthLoginScreen: WebView error: ${error.description}',
              'WebViewOAuthLoginScreen',
              Exception(error.description),
            );
            setState(() {
              _isLoading = false;
              _errorMessage =
                  'Failed to load authentication page: ${error.description}';
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            Logger.info(
              '🔗 WebViewOAuthLoginScreen: Navigation request: ${request.url}',
            );

            // Handle custom URL scheme callbacks
            if (request.url.startsWith(
              '${OAuthConstants.customUrlScheme}://',
            )) {
              Logger.info('✅ WebViewOAuthLoginScreen: Custom scheme detected');
              _handleCustomSchemeCallback(request.url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(OAuthConstants.ssoAuthUrl));
  }

  void _handleCustomSchemeCallback(String url) {
    Logger.info('🔗 WebViewOAuthLoginScreen: Handling callback: $url');

    try {
      final uri = Uri.parse(url);
      Logger.info(
        '🔍 WebViewOAuthLoginScreen: Parsed URI - scheme=${uri.scheme}, host=${uri.host}, path=${uri.path}, params=${uri.queryParameters}',
      );

      // For custom URL schemes like tmsapp://login-success?token=X or tmsapp://login-failed?error=X
      // The structure is: scheme://host or scheme://host?params
      // So we need to check the host (which contains the action) and the queryParameters

      // Try to extract token if present
      final token = uri.queryParameters[OAuthConstants.tokenParamName];
      final error = uri.queryParameters[OAuthConstants.errorParamName];

      Logger.info(
        '🔑 WebViewOAuthLoginScreen: Token: ${token != null ? '${token.substring(0, 10)}...' : 'NULL'}, Error: ${error ?? 'NONE'}',
      );

      // Check if login was successful (token parameter present)
      if (token != null && token.isNotEmpty) {
        Logger.info(
          '✅ WebViewOAuthLoginScreen: Token received, calling _handleLoginSuccess',
        );
        _handleLoginSuccess(token);
        return;
      }

      // Check if login failed (error parameter present)
      if (error != null && error.isNotEmpty) {
        Logger.warning(
          '⚠️ WebViewOAuthLoginScreen: Login failed with error: $error',
        );
        _showError(error);
        return;
      }

      Logger.warning(
        '⚠️ WebViewOAuthLoginScreen: Callback URL has no token or error parameter',
      );
      _showError(
        'Invalid authentication callback - no token or error information',
      );
    } catch (e, stackTrace) {
      Logger.error(
        '❌ WebViewOAuthLoginScreen: Error handling callback',
        'WebViewOAuthLoginScreen',
        e,
        stackTrace,
      );
      _showError('An error occurred during authentication');
    }
  }

  void _handleLoginSuccess(String token) {
    Logger.info(
      '✅ WebViewOAuthLoginScreen: _handleLoginSuccess called with token: ${token.substring(0, 20)}...',
    );
    Logger.info(
      '🔄 WebViewOAuthLoginScreen: About to call Provider.of<AuthProvider>',
    );

    try {
      Logger.info(
        '🔄 WebViewOAuthLoginScreen: Getting AuthProvider from context',
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      Logger.info(
        '🔄 WebViewOAuthLoginScreen: AuthProvider obtained, calling loginWithToken...',
      );

      // Call loginWithToken and handle the future directly
      authProvider
          .loginWithToken(token)
          .then((success) {
            Logger.info(
              '📊 WebViewOAuthLoginScreen: loginWithToken returned: $success',
            );

            if (!mounted) {
              Logger.warning(
                '⚠️ WebViewOAuthLoginScreen: Widget unmounted after login, cannot proceed',
              );
              return;
            }

            if (success) {
              Logger.info(
                '✅ WebViewOAuthLoginScreen: User authenticated successfully',
              );

              // Small delay to ensure state updates propagate
              Future.delayed(const Duration(milliseconds: 500)).then((_) {
                if (!mounted) {
                  Logger.warning(
                    '⚠️ WebViewOAuthLoginScreen: Widget unmounted after delay',
                  );
                  return;
                }

                Logger.info(
                  '✅ WebViewOAuthLoginScreen: Calling success callback or popping',
                );

                // Navigate to home or call success callback
                try {
                  if (widget.onAuthSuccess != null) {
                    Logger.info(
                      '🔔 WebViewOAuthLoginScreen: Calling onAuthSuccess callback',
                    );
                    widget.onAuthSuccess!();
                  } else {
                    Logger.info(
                      '🔙 WebViewOAuthLoginScreen: Popping with true result',
                    );
                    Navigator.of(context).pop(true);
                  }
                } catch (e) {
                  Logger.error(
                    '❌ WebViewOAuthLoginScreen: Error in navigation callback',
                    'WebViewOAuthLoginScreen',
                    e,
                  );
                }
              });
            } else {
              Logger.error(
                '❌ WebViewOAuthLoginScreen: Authentication failed',
                'WebViewOAuthLoginScreen',
                Exception('loginWithToken returned false'),
              );
              _showError('Authentication failed. Please try again.');
            }
          })
          .catchError((e, stackTrace) {
            Logger.error(
              '❌ WebViewOAuthLoginScreen: Token processing error in future',
              'WebViewOAuthLoginScreen',
              e,
              stackTrace,
            );
            if (mounted) {
              _showError('Failed to process authentication token: $e');
            }
          });
    } catch (e, stackTrace) {
      Logger.error(
        '❌ WebViewOAuthLoginScreen: Exception in _handleLoginSuccess',
        'WebViewOAuthLoginScreen',
        e,
        stackTrace,
      );
      _showError('Failed to start authentication: $e');
    }
  }

  void _showError(String message) {
    Logger.warning('⚠️ WebViewOAuthLoginScreen: Showing error: $message');

    if (!mounted) return;

    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });

    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _handleUrlRedirect(String url) {
    Logger.info('🔗 WebViewOAuthLoginScreen: Checking URL: $url');

    // Handle the custom scheme in onNavigationRequest instead
    // This is just for logging purposes
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Logger.info('🔙 WebViewOAuthLoginScreen: Back button pressed');

        // Close the WebView and go back to login
        if (widget.onBackToTraditional != null) {
          widget.onBackToTraditional!();
        } else {
          Navigator.of(context).pop();
        }
        return false;
      },
      child: Scaffold(
        appBar: AuthAppBar(
          titleKey: 'auth.login',
          showBackButton: true,
          onBackPressed: () {
            if (widget.onBackToTraditional != null) {
              widget.onBackToTraditional!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // WebView
              WebViewWidget(controller: _webViewController),

              // Loading indicator
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),

              // Error message overlay
              if (_errorMessage != null)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Authentication Failed',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() => _errorMessage = null);
                                    _initializeWebView();
                                  },
                                  child: const Text('Retry'),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton(
                                  onPressed: () {
                                    if (widget.onBackToTraditional != null) {
                                      widget.onBackToTraditional!();
                                    } else {
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  child: const Text('Back'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
