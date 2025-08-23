import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/localization/app_localizations.dart';
import '../../widgets/auth_app_bar.dart';
import '../../widgets/login_submit_button.dart';
import '../../widgets/pin_code_field.dart';

class SmsVerificationScreen extends StatefulWidget {
  final String phone; // formatted phone passed from previous screen
  const SmsVerificationScreen({super.key, required this.phone});

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
  Duration get _resendRemaining => _resendAvailableAt.difference(DateTime.now());
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
    if (!_isValid) {
      setState(() => _autoValidate = true);
      return;
    }
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${loc.translate('auth.verify')} ${loc.translate('common.ok')}')),
    );
  }

  void _resend() {
    if (!_canResend) return;
    setState(() {
      _resendAvailableAt = DateTime.now().add(const Duration(seconds: 45));
      _code = '';
    });
    _startTimer();
    
    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).translate('auth.codeSentTo') + ' ${widget.phone}'),
        duration: const Duration(seconds: 2),
      ),
    );
    // TODO: Actually trigger SMS resend API call
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
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${loc.translate('auth.codeSentTo')}\n${widget.phone}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
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
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: _canResend ? _resend : null,
                            child: _canResend
                                ? Text(loc.translate('auth.resendCode'))
                                : Text('${loc.translate('auth.resendCode')} (${_resendRemaining.inSeconds}s)'),
                          ),
                          const SizedBox(height: 8),
                          LoginSubmitButton(
                            enabled: _isValid,
                            loading: _submitting,
                            label: loc.translate('auth.verify'),
                            onPressed: () async {
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
