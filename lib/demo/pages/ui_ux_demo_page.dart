import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../widgets/demo_buttons.dart';
import '../widgets/demo_cards.dart';
import '../widgets/demo_form_elements.dart';
import '../widgets/demo_list_items.dart';

/// UI/UX Demo Page showcasing common UI components
class UiUxDemoPage extends StatelessWidget {
  const UiUxDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(localizations.translate('demo.uiUxDemo'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Buttons Section
          Text(
            localizations.translate('demo.buttons'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          DemoButtons(pageId: 'uiux', isEnabled: true),
          const SizedBox(height: 24),

          // Cards Section
          Text(
            localizations.translate('demo.cards'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          DemoCards(isEnabled: true),
          const SizedBox(height: 24),

          // Form Elements Section
          Text(
            localizations.translate('demo.formElements'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          DemoFormElements(pageId: 'uiux', isEnabled: true),
          const SizedBox(height: 24),

          // List Items Section
          Text(
            localizations.translate('demo.listItems'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          DemoListItems(pageId: 'uiux', isEnabled: true),
        ],
      ),
    );
  }
}
