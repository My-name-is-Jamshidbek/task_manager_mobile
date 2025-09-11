import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
 import '../../../core/localization/app_localizations.dart';
import '../../widgets/success_toast.dart';
import '../../widgets/password_field.dart';
import '../../widgets/login_submit_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _autoValidate = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _currentPasswordController.addListener(_onFieldChanged);
    _newPasswordController.addListener(_onFieldChanged);
    _confirmPasswordController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _currentPasswordController.removeListener(_onFieldChanged);
    _newPasswordController.removeListener(_onFieldChanged);
    _confirmPasswordController.removeListener(_onFieldChanged);
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  bool get _isFormValid {
    return _currentPasswordController.text.trim().isNotEmpty &&
        _newPasswordController.text.trim().isNotEmpty &&
        _confirmPasswordController.text.trim().isNotEmpty &&
        _newPasswordController.text.length >= 6 &&
        _newPasswordController.text == _confirmPasswordController.text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('profile.changePassword')),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 460,
                minHeight: c.maxHeight - 56,
              ),
              child: Center(
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return Form(
                      key: _formKey,
                      autovalidateMode: _autoValidate
                          ? AutovalidateMode.always
                          : AutovalidateMode.disabled,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                28,
                                24,
                                32,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Icon + title
                                  Center(
                                    child: Container(
                                      width: 96,
                                      height: 96,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.lock_outline,
                                        size: 48,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    loc.translate('profile.changePassword'),
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    loc.translate(
                                      'profile.changePasswordDescription',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  // Current password field
                                  PasswordField(
                                    controller: _currentPasswordController,
                                    loc: loc,
                                    textInputAction: TextInputAction.next,
                                    hint: loc.translate(
                                      'profile.currentPassword',
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return loc.translate(
                                          'validation.required',
                                        );
                                      }
                                      return null;
                                    },
                                    onSubmitted: () =>
                                        FocusScope.of(context).nextFocus(),
                                  ),
                                  const SizedBox(height: 16),
                                  // New password field
                                  PasswordField(
                                    controller: _newPasswordController,
                                    loc: loc,
                                    textInputAction: TextInputAction.next,
                                    hint: loc.translate('profile.newPassword'),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return loc.translate(
                                          'validation.required',
                                        );
                                      }
                                      if (v.length < 6) {
                                        return loc.translate(
                                          'validation.passwordMinLength',
                                        );
                                      }
                                      return null;
                                    },
                                    onSubmitted: () =>
                                        FocusScope.of(context).nextFocus(),
                                  ),
                                  const SizedBox(height: 16),
                                  // Confirm password field
                                  PasswordField(
                                    controller: _confirmPasswordController,
                                    loc: loc,
                                    hint: loc.translate(
                                      'profile.confirmPassword',
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return loc.translate(
                                          'validation.required',
                                        );
                                      }
                                      if (v != _newPasswordController.text) {
                                        return loc.translate(
                                          'validation.passwordsDoNotMatch',
                                        );
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  if (authProvider.error != null &&
                                      authProvider.error!.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.errorContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: theme
                                                .colorScheme
                                                .onErrorContainer,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              authProvider.error!,
                                              style: TextStyle(
                                                color: theme
                                                    .colorScheme
                                                    .onErrorContainer,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Dismiss',
                                            icon: const Icon(
                                              Icons.close,
                                              size: 18,
                                            ),
                                            color: theme
                                                .colorScheme
                                                .onErrorContainer
                                                .withOpacity(.8),
                                            onPressed: () =>
                                                authProvider.clearError(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (authProvider.error != null)
                                    const SizedBox(height: 16),
                                  LoginSubmitButton(
                                    enabled: _isFormValid && !_submitting,
                                    loading: _submitting,
                                    label: loc.translate(
                                      'profile.changePassword',
                                    ),
                                    onPressed: _submitting
                                        ? null
                                        : () async {
                                            await _changePassword();
                                            HapticFeedback.lightImpact();
                                          },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            height: MediaQuery.of(context).padding.bottom + 8,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = true);
      return;
    }

    setState(() => _submitting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final result = await authProvider.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (!mounted) return;

    if (result.success) {
      AppToast.showSuccess(
        context,
        message:
            result.message ??
            AppLocalizations.of(
              context,
            ).translate('profile.passwordChangeSuccess'),
      );
      Navigator.of(context).pop();
    } else {
      if (authProvider.error != null && authProvider.error!.isNotEmpty) {
        final errorMessage = authProvider.error!;
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
    }

    if (mounted) setState(() => _submitting = false);
  }
}
