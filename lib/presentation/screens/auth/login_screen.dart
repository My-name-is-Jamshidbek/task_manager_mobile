import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/language_selector.dart';
import '../../widgets/theme_settings_sheet.dart';
import '../../widgets/uzbekistan_phone_field.dart';
import '../../widgets/password_field.dart';
import '../../widgets/login_submit_button.dart';
import 'sms_verification_screen.dart';

import '../../widgets/auth_app_bar.dart';

/// Login Screen (Phone based for Uzbekistan) – Rewritten clean structure
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
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
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = true);
      return;
    }
    setState(() => _submitting = true);
    // Simulate server auth & wait total 5 seconds before navigating to SMS verification
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SmsVerificationScreen(phone: _phoneCtrl.text.trim()),
      ),
    );
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
                                enabled: _isFormValid,
                                loading: _submitting,
                                label: loc.translate('auth.loginButton'),
                                onPressed: () async {
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