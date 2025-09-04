import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../widgets/success_toast.dart';

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

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            loc.translate('profile.changePasswordDescription'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Current password field
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrentPassword,
                    decoration: InputDecoration(
                      labelText: loc.translate('profile.currentPassword'),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrentPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureCurrentPassword = !_obscureCurrentPassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return loc.translate('validation.required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // New password field
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: loc.translate('profile.newPassword'),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return loc.translate('validation.required');
                      }
                      if (value.length < 6) {
                        return loc.translate('validation.passwordMinLength');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm password field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: loc.translate('profile.confirmPassword'),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return loc.translate('validation.required');
                      }
                      if (value != _newPasswordController.text) {
                        return loc.translate('validation.passwordsDoNotMatch');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Error message
                  if (authProvider.error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: theme.colorScheme.onErrorContainer,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authProvider.error!,
                              style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Change password button
                  FilledButton(
                    onPressed: authProvider.isLoading ? null : _changePassword,
                    child: authProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(loc.translate('profile.changePassword')),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final result = await authProvider.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (context.mounted) {
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
        // Error is handled by the provider and displayed in UI
      }
    }
  }
}
