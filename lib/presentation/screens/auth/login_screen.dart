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
  bool _obscure = true;
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

  String? _validatePhone(String? value, AppLocalizations loc) => validateUzbekistanPhone(value, loc);

  String? _validatePassword(String? v, AppLocalizations loc) => validatePassword(v, loc);

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
            Logger.warning('⚠️ LoginScreen: No onAuthSuccess callback provided');
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
        // Show more specific error message with icon
        final errorKey = ApiErrorMapper.getFallbackKey(authProvider.error);
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
                Expanded(child: Text(loc.translate(errorKey))),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
    final media = MediaQuery.of(context);

    return Scaffold(
      appBar: const AuthAppBar(
        titleKey: 'auth.login',
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 460,
                // Fill at least the viewport height minus padding so we can center
                minHeight: c.maxHeight - 56, // 28 * 2 vertical padding
              ),
              child: Center(
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autoValidate
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
                              // Logo
                              SizedBox(
                                height: 96,
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: Icon(
                                    Icons.task_alt,
                                    size: 96,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                loc.translate('app.title'),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              UzbekistanPhoneField(
                                controller: _phoneCtrl,
                                loc: loc,
                                validator: (v) => _validatePhone(v, loc),
                              ),
                              const SizedBox(height: 16),
                              PasswordField(
                                controller: _passwordCtrl,
                                loc: loc,
                                validator: (v) => _validatePassword(v, loc),
                                onSubmitted: _submit,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {/* TODO: forgot */},
                                  child: Text(loc.translate('auth.forgotPassword')),
                                ),
                              ),
                              const SizedBox(height: 8),
                              LoginSubmitButton(
                                enabled: _isFormValid && !_submitting,
                                loading: _submitting,
                                label: loc.translate('auth.loginButton'),
                                onPressed: _submitting ? null : () async {
                                  await _submit();
                                  HapticFeedback.lightImpact();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrDivider(AppLocalizations loc, ThemeData theme) => const SizedBox.shrink();
  Widget _buildAltMethods() => const SizedBox.shrink();
  Widget _buildRegisterRow(AppLocalizations loc) => const SizedBox.shrink();
}