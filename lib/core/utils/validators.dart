import '../localization/app_localizations.dart';

/// Total digits for Uzbekistan phone including country code 998 + 9 subscriber digits
const int kUzbekistanTotalDigits = 12;

/// Regex for Uzbekistan phone digits without plus sign (e.g. 998901234567)
final RegExp kUzbekistanPhoneDigitsRegex = RegExp(r'^998\d{9}$');

/// Validate Uzbekistan phone number. Expects formatted string possibly containing spaces and +.
/// Returns localized error message or null if valid.
String? validateUzbekistanPhone(String? value, AppLocalizations loc) {
  if (value == null || value.trim().isEmpty) {
    return loc.translate('validation.phoneInvalid');
  }
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (!kUzbekistanPhoneDigitsRegex.hasMatch(digits)) {
    if (!digits.startsWith('998')) return '+998';
    final remaining = kUzbekistanTotalDigits - digits.length;
    if (remaining > 0) {
      return '${loc.translate('validation.phoneInvalid')}  (−$remaining)';
    }
    return loc.translate('validation.phoneInvalid');
  }
  return null;
}

/// Basic password validation: non-empty & length >= 6.
String? validatePassword(String? value, AppLocalizations loc) {
  if (value == null || value.isEmpty) return '${loc.translate('auth.password')} *';
  if (value.length < 6) return '${loc.translate('auth.password')} 6+';
  return null;
}
