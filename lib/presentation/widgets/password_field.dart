import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/localization/app_localizations.dart';

/// Reusable password form field with visibility toggle.
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final AppLocalizations loc;
  final VoidCallback? onSubmitted;
  final String? hint;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final TextInputAction textInputAction;

  const PasswordField({
    super.key,
    required this.controller,
    required this.loc,
    this.validator,
    this.onSubmitted,
    this.hint,
    this.focusNode,
    this.nextFocus,
    this.textInputAction = TextInputAction.done,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _obscure,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: (_) {
        if (widget.onSubmitted != null) widget.onSubmitted!();
        if (widget.nextFocus != null) {
          widget.nextFocus!.requestFocus();
        } else {
          SystemChannels.textInput.invokeMethod('TextInput.hide');
        }
      },
      decoration: InputDecoration(
        labelText: widget.hint ?? widget.loc.translate('auth.password'),
        hintText: '••••••',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: widget.validator,
    );
  }
}
