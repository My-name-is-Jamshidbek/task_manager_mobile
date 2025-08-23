import 'package:flutter/material.dart';

/// Reusable animated submit button for login forms.
class LoginSubmitButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback? onPressed;
  final String label;
  final double height;

  const LoginSubmitButton({
    super.key,
    required this.enabled,
    required this.loading,
    required this.onPressed,
    required this.label,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: FilledButton(
        onPressed: enabled && !loading ? onPressed : null,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: loading
              ? SizedBox(
                  key: const ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation(
                      theme.colorScheme.onPrimary,
                    ),
                  ),
                )
              : Text(
                  key: const ValueKey('label'),
                  label,
                ),
        ),
      ),
    );
  }
}
