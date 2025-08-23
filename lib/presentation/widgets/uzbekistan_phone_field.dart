import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/localization/app_localizations.dart';

/// Reusable Uzbekistan phone number form field: formats +998 91 123 45 67
class UzbekistanPhoneField extends StatelessWidget {
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final AppLocalizations loc;
  final int totalDigits; // includes country code 998 + 9 digits = 12
  final FocusNode? focusNode;
  final VoidCallback? onEditingComplete;

  const UzbekistanPhoneField({
    super.key,
    required this.controller,
    required this.validator,
    required this.loc,
    this.totalDigits = 12,
    this.focusNode,
    this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final digitsCount = value.text.replaceAll(RegExp(r'[^0-9]'), '').length;
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[+0-9 ]')),
            UzbekistanPhoneFormatter(),
          ],
          decoration: InputDecoration(
            labelText: loc.translate('profile.phoneNumber'),
            hintText: '+998 91 123 45 67',
            prefixIcon: const Icon(Icons.phone),
            suffixIcon: value.text.length > 5
                ? IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.text = '+998 ';
                      controller.selection = TextSelection.collapsed(
                        offset: controller.text.length,
                      );
                    },
                  )
                : null,
            helperText: '$digitsCount/$totalDigits',
          ),
          validator: validator,
          onEditingComplete: onEditingComplete,
        );
      },
    );
  }
}

/// Uzbekistan phone number formatter: +998 91 123 45 67
class UzbekistanPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final baseOffset = newValue.selection.baseOffset;
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9+]'), '');

    if (!digits.startsWith('+998')) {
      digits = '+998${digits.replaceAll('+', '')}';
    }
    digits = '+${digits.replaceAll('+', '')}';

    String raw = digits.replaceAll('+998', '').replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.length > 9) raw = raw.substring(0, 9);

    final b = StringBuffer('+998');
    if (raw.isNotEmpty) b.write(' ');
    if (raw.length >= 2) {
      b.write(raw.substring(0, 2));
      if (raw.length > 2) b.write(' ');
      if (raw.length >= 5) {
        b.write(raw.substring(2, 5));
        if (raw.length > 5) b.write(' ');
        if (raw.length >= 7) {
          b.write(raw.substring(5, 7));
          if (raw.length > 7) b.write(' ');
          if (raw.length >= 9) {
            b.write(raw.substring(7, 9));
          } else if (raw.length > 7) {
            b.write(raw.substring(7));
          }
        } else if (raw.length > 5) {
          b.write(raw.substring(5));
        }
      } else if (raw.length > 2) {
        b.write(raw.substring(2));
      }
    } else {
      b.write(raw);
    }
    final formatted = b.toString();

    final selectionIndex = baseOffset > formatted.length ? formatted.length : formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
