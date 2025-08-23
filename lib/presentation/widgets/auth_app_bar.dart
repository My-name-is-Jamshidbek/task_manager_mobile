import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import 'language_selector.dart';
import 'theme_settings_sheet.dart';

/// Reusable auth app bar with language and theme settings
class AuthAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleKey;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const AuthAppBar({
    super.key,
    required this.titleKey,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return AppBar(
      title: Text(loc.translate(titleKey)),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      automaticallyImplyLeading: showBackButton,
      actions: [
        IconButton(
          icon: const Icon(Icons.language),
          tooltip: loc.translate('settings.language'),
          onPressed: () => showModalBottomSheet(
            context: context,
            builder: (_) => const LanguageSelector(),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.color_lens),
          tooltip: loc.translate('settings.theme'),
          onPressed: () => showModalBottomSheet(
            context: context,
            builder: (_) => const ThemeSettingsSheet(),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
