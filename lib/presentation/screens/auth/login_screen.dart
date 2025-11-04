import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/api_error_mapper.dart';
import '../../../core/utils/logger.dart';
import '../../widgets/uzbekistan_phone_field.dart';
import '../../widgets/password_field.dart';
import '../../widgets/login_submit_button.dart';
import '../../providers/auth_provider.dart';
import 'sms_verification_screen.dart';
import 'oauth_login_screen.dart';
import '../../widgets/auth_app_bar.dart';

/// Login Screen (Phone based for Uzbekistan) – Rewritten clean structure
class LoginScreen extends StatefulWidget {
  final VoidCallback? onAuthSuccess;

  const LoginScreen({super.key, this.onAuthSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController(text: '+998 ');
  final _passwordCtrl = TextEditingController();
  bool _autoValidate = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.addListener(_triggerRebuild);
    _passwordCtrl.addListener(_triggerRebuild);
  }

  @override
  void dispose() {
    _phoneCtrl.removeListener(_triggerRebuild);
    _passwordCtrl.removeListener(_triggerRebuild);
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _triggerRebuild() => setState(() {});

  String? _validatePhone(String? value, AppLocalizations loc) =>
      validateUzbekistanPhone(value, loc);

  String? _validatePassword(String? v, AppLocalizations loc) =>
      validatePassword(v, loc);

  bool get _isFormValid {
    final loc = AppLocalizations.of(context);
    return _validatePhone(_phoneCtrl.text, loc) == null &&
        _validatePassword(_passwordCtrl.text, loc) == null;
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = true);
      return;
    }

    setState(() => _submitting = true);

    try {
      // Extract phone number (remove spaces and formatting)
      final cleanPhone = _phoneCtrl.text.replaceAll(RegExp(r'[^\d+]'), '');
      final password = _passwordCtrl.text.trim();

      // Call login API with phone and password
      final success = await authProvider.login(cleanPhone, password);

      if (!mounted) return;

      if (success) {
        // Check if user is already logged in (direct login without SMS)
        if (authProvider.isLoggedIn) {
          // Always use callback for consistent navigation
          if (widget.onAuthSuccess != null) {
            widget.onAuthSuccess!();
          } else {
            // Log warning if no callback provided (this shouldn't happen)
            Logger.warning(
              '⚠️ LoginScreen: No onAuthSuccess callback provided',
            );
          }
        } else {
          // Navigate to SMS verification screen
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SmsVerificationScreen(
                phone: cleanPhone,
                onAuthSuccess: widget.onAuthSuccess,
              ),
            ),
          );
        }
      } else {
        // Show error message - prioritize API message over translation
        String errorMessage;
        if (authProvider.error != null && authProvider.error!.isNotEmpty) {
          // Use API message directly if available
          errorMessage = authProvider.error!;
        } else {
          // Fallback to translation
          final errorKey = ApiErrorMapper.getFallbackKey(authProvider.error);
          errorMessage = loc.translate(errorKey);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onError,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.warning_outlined,
                color: Theme.of(context).colorScheme.onError,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(loc.translate('messages.unexpectedError'))),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AuthAppBar(titleKey: 'auth.login'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth >= 900; // tablet landscape / desktop
            final isMedium =
                c.maxWidth >= 600 && c.maxWidth < 900; // tablet portrait

            if (isWide) {
              // Two-pane layout for large screens
              return Row(
                children: [
                  // Branding panel
                  Expanded(flex: 5, child: _BrandingPanel(loc: loc)),
                  // Divider between panels
                  SizedBox(
                    width: 1,
                    child: Container(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                    ),
                  ),
                  // Form panel
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 28,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: _LoginForm(loc: loc),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            // Medium screens: widen card, keep single column
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isMedium ? 560 : 460,
                    minHeight: c.maxHeight - 56, // 28 * 2 vertical padding
                  ),
                  child: _LoginForm(loc: loc),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Removed unused helper methods after responsive refactor
}

/// Left-side branding panel for large screens
class _BrandingPanel extends StatelessWidget {
  final AppLocalizations loc;
  const _BrandingPanel({required this.loc});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.primary.withOpacity(0.12),
            color.primaryContainer.withOpacity(0.20),
            color.surfaceContainerHighest.withOpacity(0.10),
          ],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.task_alt, size: 120, color: color.primary),
                const SizedBox(height: 24),
                Text(
                  loc.translate('app.title'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.brightness == Brightness.dark
                        ? color.onSurface
                        : color.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  loc.translate('home.welcomeBack'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Removed unused _Pill widget after refactor

/// Login form extracted so it can be reused in multiple layouts
class _LoginForm extends StatelessWidget {
  final AppLocalizations loc;
  const _LoginForm({required this.loc});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_LoginScreenState>()!;
    final theme = Theme.of(context);

    return Form(
      key: state._formKey,
      autovalidateMode: state._autoValidate
          ? AutovalidateMode.always
          : AutovalidateMode.disabled,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Text(
                    loc.translate('home.welcomeBack'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.translate('auth.login'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  UzbekistanPhoneField(
                    controller: state._phoneCtrl,
                    loc: loc,
                    validator: (v) => state._validatePhone(v, loc),
                  ),
                  const SizedBox(height: 16),
                  PasswordField(
                    controller: state._passwordCtrl,
                    loc: loc,
                    validator: (v) => state._validatePassword(v, loc),
                    onSubmitted: state._submit,
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        /* TODO: forgot */
                      },
                      child: Text(loc.translate('auth.forgotPassword')),
                    ),
                  ),
                  const SizedBox(height: 8),
                  LoginSubmitButton(
                    enabled: state._isFormValid && !state._submitting,
                    loading: state._submitting,
                    label: loc.translate('auth.loginButton'),
                    onPressed: state._submitting
                        ? null
                        : () async {
                            await state._submit();
                            HapticFeedback.lightImpact();
                          },
                  ),
                  const SizedBox(height: 20),
                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: theme.colorScheme.outlineVariant.withOpacity(
                            0.5,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          loc.translate('auth.or'),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: theme.colorScheme.outlineVariant.withOpacity(
                            0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // OAuth Login Button
                  FilledButton.icon(
                    onPressed: state._submitting
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => OAuthLoginScreen(
                                  onAuthSuccess: state.widget.onAuthSuccess,
                                  onBackToTraditional: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.security_rounded),
                    label: Text(
                      'Login with RANCH ID',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
