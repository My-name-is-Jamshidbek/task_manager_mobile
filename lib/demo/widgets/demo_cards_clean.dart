import 'package:flutter/material.dart';

/// CoreUI Demo Cards Widget (Clean Implementation)
class DemoCards extends StatelessWidget {
  final bool isEnabled;

  const DemoCards({super.key, this.isEnabled = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cards',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DemoCardTitle(),
                const SizedBox(height: 8),
                const DemoCardDescription(),
                const SizedBox(height: 16),
                DemoCardActions(isEnabled: isEnabled),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// CoreUI Demo Card Title Widget
class DemoCardTitle extends StatelessWidget {
  const DemoCardTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Sample Card',
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        inherit: true,
      ),
    );
  }
}

/// CoreUI Demo Card Description Widget
class DemoCardDescription extends StatelessWidget {
  const DemoCardDescription({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'This is a sample card using CoreUI design system with proper spacing and typography.',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(inherit: true),
    );
  }
}

/// CoreUI Demo Card Actions Widget
class DemoCardActions extends StatelessWidget {
  final bool isEnabled;

  const DemoCardActions({super.key, this.isEnabled = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: isEnabled ? () {} : null,
          child: Text(
            'Cancel',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(inherit: true),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: isEnabled ? () {} : null,
          child: Text(
            'Action',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(inherit: true),
          ),
        ),
      ],
    );
  }
}
