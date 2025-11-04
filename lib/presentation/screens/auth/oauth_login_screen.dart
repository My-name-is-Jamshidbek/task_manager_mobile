import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/oauth_constants.dart';
import '../../../core/utils/logger.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_app_bar.dart';

/// OAuth 2.0 Login Screen - Login with RANCH ID
class OAuthLoginScreen extends StatefulWidget {
  final VoidCallback? onAuthSuccess;
  final VoidCallback? onBackToTraditional;

  const OAuthLoginScreen({
    super.key,
    this.onAuthSuccess,
    this.onBackToTraditional,
  });

  @override
  State<OAuthLoginScreen> createState() => _OAuthLoginScreenState();
}

class _OAuthLoginScreenState extends State<OAuthLoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Logger.info('🚀 OAuthLoginScreen: Initialized OAuth login screen');
  }

  Future<void> _loginWithRanchID() async {
    Logger.info('🚀 OAuthLoginScreen: Starting RANCH ID OAuth flow');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Initiate OAuth login
      final success = await authProvider.loginWithOAuth(
        redirectUrl: OAuthConstants.redirectUrl,
        scopes: OAuthConstants.defaultScopes,
      );

      if (!mounted) return;

      if (success) {
        Logger.info('✅ OAuthLoginScreen: OAuth login successful');

        // Navigate to home or call success callback
        if (widget.onAuthSuccess != null) {
          widget.onAuthSuccess!();
        }
      } else {
        Logger.warning('⚠️ OAuthLoginScreen: OAuth login failed');
        setState(() {
          _errorMessage = 'OAuth authorization was cancelled or failed';
        });
      }
    } catch (e, stackTrace) {
      Logger.error(
        '❌ OAuthLoginScreen: OAuth login exception',
        'OAuthLoginScreen',
        e,
        stackTrace,
      );

      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred during OAuth login: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AuthAppBar(
        titleKey: 'login',
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo or Header
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      // RANCH ID Icon/Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).primaryColor.withOpacity(0.8),
                              Theme.of(context).primaryColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.security,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        OAuthConstants.ranchIdName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        OAuthConstants.ranchIdDescription,
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // Information Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.grey[900]
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Secure Authentication',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Login securely using RANCH ID with OAuth 2.0 authentication. Your credentials are protected with industry-standard encryption.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Error Message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Main OAuth Login Button
                FilledButton.icon(
                  onPressed: _isLoading ? null : _loginWithRanchID,
                  icon: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        )
                      : const Icon(Icons.fingerprint),
                  label: Text(
                    _isLoading ? 'Signing in...' : 'Login with RANCH ID',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ).paddingSymmetric(horizontal: 0),

                const SizedBox(height: 20),

                // Divider with text
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Colors.grey.withOpacity(0.3)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Colors.grey.withOpacity(0.3)),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Back to Traditional Login Button
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : widget.onBackToTraditional,
                  icon: const Icon(Icons.phone),
                  label: const Text(
                    'Use Phone & Password',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 40),

                // Benefits Section
                Text(
                  'Benefits of OAuth 2.0:',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildBenefitItem(
                  context,
                  Icons.shield_rounded,
                  'Enhanced Security',
                  'PKCE protected, no password sharing',
                ),
                const SizedBox(height: 8),
                _buildBenefitItem(
                  context,
                  Icons.person_rounded,
                  'Easy Authentication',
                  'Single sign-on with RANCH ID',
                ),
                const SizedBox(height: 8),
                _buildBenefitItem(
                  context,
                  Icons.lock_rounded,
                  'Privacy Focused',
                  'Your credentials never shared',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Extension to add padding to widgets
extension WidgetPadding on Widget {
  Widget paddingSymmetric({double horizontal = 0, double vertical = 0}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      child: this,
    );
  }
}
