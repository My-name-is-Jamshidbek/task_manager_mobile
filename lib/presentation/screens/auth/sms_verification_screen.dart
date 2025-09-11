import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/logger.dart';
import '../../widgets/auth_app_bar.dart';
import '../../widgets/login_submit_button.dart';
import '../../widgets/pin_code_field.dart';
import '../../providers/auth_provider.dart';

class SmsVerificationScreen extends StatefulWidget {
  final String phone; // formatted phone passed from previous screen
  final VoidCallback? onAuthSuccess;

  const SmsVerificationScreen({
    super.key,
    required this.phone,
    this.onAuthSuccess,
  });

  @override
  State<SmsVerificationScreen> createState() => _SmsVerificationScreenState();
}

class _SmsVerificationScreenState extends State<SmsVerificationScreen> {
  String _code = '';
  bool _submitting = false;
  bool _autoValidate = false;
  static const int _codeLength = 6;
  DateTime _resendAvailableAt = DateTime.now().add(const Duration(seconds: 45));
  Timer? _timer;

  bool get _isValid => _code.length == _codeLength;
  Duration get _resendRemaining =>
      _resendAvailableAt.difference(DateTime.now());
  bool get _canResend => _resendRemaining <= Duration.zero;

  void _onCodeChanged(String value) {
    setState(() => _code = value);
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_canResend) {
        timer.cancel();
      }
      if (mounted) setState(() {});
    });
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!_isValid) {
      setState(() => _autoValidate = true);
      return;
    }

    setState(() => _submitting = true);

    try {
      // Call verify API (currently bypassed)
      final success = await authProvider.verifyCode(widget.phone, _code);

      if (!mounted) return;

      if (success) {
        // Brief delay before navigation
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        // Always use callback for consistent navigation
        if (widget.onAuthSuccess != null) {
          widget.onAuthSuccess!();
        } else {
          // Log warning if no callback provided (this shouldn't happen)
          Logger.warning(
            '⚠️ SmsVerificationScreen: No onAuthSuccess callback provided',
          );
        }
      } else {
        // Show error message with icon - prioritize API message over translation
        String errorMessage;
        if (authProvider.error != null && authProvider.error!.isNotEmpty) {
          // Use API message directly if available
          errorMessage = authProvider.error!;
        } else {
          // Fallback to translation
          errorMessage = loc.translate('auth.invalidCode');
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

  void _resend() async {
    if (!_canResend) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final loc = AppLocalizations.of(context);

    setState(() {
      _resendAvailableAt = DateTime.now().add(const Duration(seconds: 45));
      _code = '';
    });
    _startTimer();

    try {
      // Actually call the resend SMS API
      final success = await authProvider.resendSms(widget.phone);

      if (!mounted) return;

      if (success) {
        // Show success feedback to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.sms,
                  color: Theme.of(context).colorScheme.onSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${loc.translate('auth.codeSentTo')} ${widget.phone}',
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else {
        // Show error message
        String errorMessage;
        if (authProvider.error != null && authProvider.error!.isNotEmpty) {
          errorMessage = authProvider.error!;
        } else {
          errorMessage = loc.translate('messages.networkError');
        }

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AuthAppBar(
        titleKey: 'auth.verifyCode',
        showBackButton: true,
      ),
      body: LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 460,
              minHeight: c.maxHeight - 56,
            ),
            child: Center(
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
                          SizedBox(
                            height: 82,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Icon(
                                Icons.sms,
                                size: 82,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            loc.translate('auth.verifyCode'),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${loc.translate('auth.codeSentTo')}\n${widget.phone}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    loc.translate(
                                      'auth.smsVerificationRequired',
                                    ),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          PinCodeField(
                            length: _codeLength,
                            onChanged: _onCodeChanged,
                            onCompleted: _onCodeChanged,
                          ),
                          const SizedBox(height: 20),
                          if (_autoValidate && !_isValid)
                            Text(
                              loc.translate('auth.invalidCode'),
                              style: TextStyle(color: theme.colorScheme.error),
                              textAlign: TextAlign.center,
                            ),
                          // Debug mode: Show bypass button for testing
                          if (widget.phone.contains('test') ||
                              widget.phone == '+998901234567')
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: TextButton.icon(
                                onPressed: () async {
                                  setState(() => _submitting = true);
                                  // Simulate successful verification with test code
                                  _code = '123456';
                                  await _submit();
                                },
                                icon: const Icon(Icons.bug_report, size: 16),
                                label: Text(
                                  'Debug: Auto-verify (Test Mode)',
                                  style: theme.textTheme.bodySmall,
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: theme.colorScheme.secondary,
                                ),
                              ),
                            ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: _canResend ? _resend : null,
                            child: _canResend
                                ? Text(loc.translate('auth.resendCode'))
                                : Text(
                                    '${loc.translate('auth.resendCode')} (${_resendRemaining.inSeconds}s)',
                                  ),
                          ),
                          const SizedBox(height: 8),
                          LoginSubmitButton(
                            enabled: _isValid && !_submitting,
                            loading: _submitting,
                            label: loc.translate('auth.verify'),
                            onPressed: _submitting
                                ? null
                                : () async {
                                    await _submit();
                                    HapticFeedback.lightImpact();
                                  },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
