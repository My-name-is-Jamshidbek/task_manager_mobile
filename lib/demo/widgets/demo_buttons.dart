import 'package:flutter/material.dart';

/// CoreUI Demo Buttons Widget
class DemoButtons extends StatelessWidget {
  final String pageId;
  final bool isEnabled;

  const DemoButtons({super.key, required this.pageId, this.isEnabled = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Buttons',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            DemoPrimaryButton(pageId: pageId, isEnabled: isEnabled),
            DemoOutlinedButton(pageId: pageId, isEnabled: isEnabled),
            DemoTextButton(pageId: pageId, isEnabled: isEnabled),
            DemoIconButton(pageId: pageId, isEnabled: isEnabled),
          ],
        ),
      ],
    );
  }
}

/// CoreUI Primary Button Widget
class DemoPrimaryButton extends StatelessWidget {
  final String pageId;
  final bool isEnabled;

  const DemoPrimaryButton({
    super.key,
    required this.pageId,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isEnabled ? () {} : null,
      child: const Text('Primary'),
    );
  }
}

/// CoreUI Outlined Button Widget
class DemoOutlinedButton extends StatelessWidget {
  final String pageId;
  final bool isEnabled;

  const DemoOutlinedButton({
    super.key,
    required this.pageId,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isEnabled ? () {} : null,
      child: const Text('Outlined'),
    );
  }
}

/// CoreUI Text Button Widget
class DemoTextButton extends StatelessWidget {
  final String pageId;
  final bool isEnabled;

  const DemoTextButton({
    super.key,
    required this.pageId,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: isEnabled ? () {} : null,
      child: const Text('Text'),
    );
  }
}

/// CoreUI Icon Button Widget
class DemoIconButton extends StatelessWidget {
  final String pageId;
  final bool isEnabled;

  const DemoIconButton({
    super.key,
    required this.pageId,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isEnabled ? () {} : null,
      icon: const Icon(Icons.check),
      label: const Text('With Icon'),
    );
  }
}
