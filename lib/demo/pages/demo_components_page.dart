import 'package:flutter/material.dart';
import '../widgets/demo_buttons.dart';
// import '../widgets/demo_cards.dart'; // Removed due to definition issues
import '../widgets/demo_form_elements.dart';
import '../widgets/demo_list_items.dart';

/// CoreUI Demo Components Page Widget
class DemoComponentsPage extends StatefulWidget {
  const DemoComponentsPage({super.key});

  @override
  State<DemoComponentsPage> createState() => _DemoComponentsPageState();
}

class _DemoComponentsPageState extends State<DemoComponentsPage> {
  late String _pageId;

  @override
  void initState() {
    super.initState();
    // Use a more unique ID to prevent conflicts
    _pageId = '${widget.hashCode}_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const DemoComponentsTitle(),
        const SizedBox(height: 16),

        // Buttons Section
        DemoButtons(pageId: _pageId, isEnabled: mounted),
        const SizedBox(height: 24),

        // Cards Section
        const Text(
          'Cards',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sample Card',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'This is a sample card using CoreUI design system with proper spacing and typography.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: mounted ? () {} : null,
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: mounted ? () {} : null,
                      child: const Text('Action'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Form Elements Section
        DemoFormElements(pageId: _pageId, isEnabled: mounted),
        const SizedBox(height: 24),

        // List Items Section
        DemoListItems(pageId: _pageId, isEnabled: mounted),
        const SizedBox(height: 24),

        // Additional Components Section
        const DemoAdditionalComponents(),
      ],
    );
  }
}

/// CoreUI Components Page Title Widget
class DemoComponentsTitle extends StatelessWidget {
  const DemoComponentsTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'CoreUI Components',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }
}

/// CoreUI Additional Components Section Widget
class DemoAdditionalComponents extends StatelessWidget {
  const DemoAdditionalComponents({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Components',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const DemoProgressIndicators(),
        const SizedBox(height: 16),
        const DemoChips(),
        const SizedBox(height: 16),
        DemoBadges(),
        const SizedBox(height: 16),
        const DemoSwitchesAndCheckboxes(),
      ],
    );
  }
}

/// CoreUI Progress Indicators Widget
class DemoProgressIndicators extends StatelessWidget {
  const DemoProgressIndicators({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Progress Indicators'),
        const SizedBox(height: 8),
        const LinearProgressIndicator(value: 0.7),
        const SizedBox(height: 8),
        Row(
          children: [
            const CircularProgressIndicator(value: 0.7),
            const SizedBox(width: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ],
    );
  }
}

/// CoreUI Chips Widget
class DemoChips extends StatelessWidget {
  const DemoChips({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chips'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            const Chip(label: Text('Default')),
            Chip(label: const Text('Deletable'), onDeleted: () {}),
            const ChoiceChip(label: Text('Choice'), selected: true),
            ActionChip(label: const Text('Action'), onPressed: () {}),
          ],
        ),
      ],
    );
  }
}

/// CoreUI Badges Widget
class DemoBadges extends StatelessWidget {
  const DemoBadges({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Badges'),
        const SizedBox(height: 8),
        Row(
          children: [
            Badge(label: const Text('3'), child: Icon(Icons.notifications)),
            const SizedBox(width: 16),
            Badge(label: const Text('99+'), child: Icon(Icons.message)),
            const SizedBox(width: 16),
            Badge(child: Icon(Icons.shopping_cart)),
          ],
        ),
      ],
    );
  }
}

/// CoreUI Switches and Checkboxes Widget
class DemoSwitchesAndCheckboxes extends StatefulWidget {
  const DemoSwitchesAndCheckboxes({super.key});

  @override
  State<DemoSwitchesAndCheckboxes> createState() =>
      _DemoSwitchesAndCheckboxesState();
}

class _DemoSwitchesAndCheckboxesState extends State<DemoSwitchesAndCheckboxes> {
  bool _switchValue = true;
  bool _checkboxValue = true;
  int _radioValue = 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Controls'),
        const SizedBox(height: 8),
        Row(
          children: [
            Switch(
              value: _switchValue,
              onChanged: (value) {
                setState(() {
                  _switchValue = value;
                });
              },
            ),
            const SizedBox(width: 16),
            Checkbox(
              value: _checkboxValue,
              onChanged: (value) {
                setState(() {
                  _checkboxValue = value ?? false;
                });
              },
            ),
            const SizedBox(width: 16),
            Radio<int>(
              value: 1,
              groupValue: _radioValue,
              onChanged: (value) {
                setState(() {
                  _radioValue = value ?? 1;
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}
