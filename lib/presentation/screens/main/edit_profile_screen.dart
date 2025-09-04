import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/success_toast.dart';
import '../../widgets/uzbekistan_phone_field.dart';
import '../../widgets/login_submit_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _autoValidate = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill form with current user data
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      _nameController.text = authProvider.currentUser!.name ?? '';
      String phone = authProvider.currentUser!.phone ?? '';
      if (phone.isNotEmpty && !phone.startsWith('+998')) {
        if (phone.length == 9) {
          phone = '+998 $phone';
        } else if (phone.startsWith('998')) {
          phone = '+$phone';
        } else {
          phone = '+998 $phone';
        }
      } else if (phone.isEmpty) {
        phone = '+998 ';
      }
      _phoneController.text = phone;
    } else {
      _phoneController.text = '+998 ';
    }

    _nameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  bool get _isFormValid {
    final loc = AppLocalizations.of(context);
    return (_nameController.text.trim().isNotEmpty) &&
        validateUzbekistanPhone(_phoneController.text, loc) == null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('profile.editProfile')),
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
                minHeight: c.maxHeight - 56, // keep layout similar to login
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
                                  // Avatar + title
                                  Center(
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 96,
                                          height: 96,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: theme.colorScheme.primary,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.1,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              _getInitials(
                                                authProvider
                                                        .currentUser
                                                        ?.name ??
                                                    '',
                                              ),
                                              style: theme
                                                  .textTheme
                                                  .headlineMedium
                                                  ?.copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color:
                                                  theme.colorScheme.secondary,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color:
                                                    theme.colorScheme.surface,
                                                width: 2,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.camera_alt,
                                              size: 16,
                                              color:
                                                  theme.colorScheme.onSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    loc.translate('profile.editProfile'),
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  // Name field
                                  TextFormField(
                                    controller: _nameController,
                                    enabled: !_submitting,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: loc.translate('profile.name'),
                                      prefixIcon: const Icon(
                                        Icons.person_outline,
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return loc.translate(
                                          'validation.required',
                                        );
                                      }
                                      if (v.trim().length < 2) {
                                        return loc.translate(
                                          'validation.minLength',
                                        );
                                      }
                                      return null;
                                    },
                                    onFieldSubmitted: (_) =>
                                        FocusScope.of(context).nextFocus(),
                                  ),
                                  const SizedBox(height: 16),
                                  UzbekistanPhoneField(
                                    controller: _phoneController,
                                    loc: loc,
                                    validator: (v) =>
                                        validateUzbekistanPhone(v, loc),
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
                                    label: loc.translate('common.save'),
                                    onPressed: _submitting
                                        ? null
                                        : () async {
                                            await _saveProfile();
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

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0].substring(0, 1)}${parts[parts.length - 1].substring(0, 1)}'
        .toUpperCase();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = true);
      return;
    }

    setState(() => _submitting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Clean phone: remove spaces except plus
    final cleanPhone = _phoneController.text.replaceAll(RegExp(r'[^\d+]'), '');
    final result = await authProvider.updateProfile(
      name: _nameController.text.trim(),
      phone: cleanPhone,
    );

    if (!mounted) return;

    if (result.success) {
      AppToast.showSuccess(
        context,
        message:
            result.message ??
            AppLocalizations.of(context).translate('profile.updateSuccess'),
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
