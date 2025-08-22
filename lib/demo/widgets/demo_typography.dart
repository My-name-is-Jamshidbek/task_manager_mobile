import 'package:flutter/material.dart';

/// CoreUI Demo Typography Section Widget
class DemoTypography extends StatelessWidget {
  const DemoTypography({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DemoTypographyTitle(),
        SizedBox(height: 24),
        DemoHeadingsSection(),
        SizedBox(height: 24),
        DemoBodyTextSection(),
        SizedBox(height: 24),
        DemoLabelTextSection(),
      ],
    );
  }
}

/// CoreUI Typography Title Widget
class DemoTypographyTitle extends StatelessWidget {
  const DemoTypographyTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'CoreUI Typography',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }
}

/// CoreUI Headings Section Widget
class DemoHeadingsSection extends StatelessWidget {
  const DemoHeadingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DemoSectionTitle(title: 'Headings'),
        SizedBox(height: 16),
        DemoHeadingExample(level: 1, text: 'Heading 1 - Display Large'),
        SizedBox(height: 12),
        DemoHeadingExample(level: 2, text: 'Heading 2 - Display Medium'),
        SizedBox(height: 12),
        DemoHeadingExample(level: 3, text: 'Heading 3 - Display Small'),
        SizedBox(height: 12),
        DemoHeadingExample(level: 4, text: 'Heading 4 - Headline Large'),
        SizedBox(height: 12),
        DemoHeadingExample(level: 5, text: 'Heading 5 - Headline Medium'),
        SizedBox(height: 12),
        DemoHeadingExample(level: 6, text: 'Heading 6 - Headline Small'),
      ],
    );
  }
}

/// CoreUI Body Text Section Widget
class DemoBodyTextSection extends StatelessWidget {
  const DemoBodyTextSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DemoSectionTitle(title: 'Body Text'),
        const SizedBox(height: 16),
        Text(
          'Body Large - This is large body text that provides excellent readability for important content.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'Body Medium - This is the standard body text used for most content in the application.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Text(
          'Body Small - This is small body text used for secondary information and captions.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// CoreUI Label Text Section Widget
class DemoLabelTextSection extends StatelessWidget {
  const DemoLabelTextSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DemoSectionTitle(title: 'Labels'),
        const SizedBox(height: 16),
        Text(
          'Label Large - Used for button text and important labels',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'Label Medium - Used for form labels and secondary buttons',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 12),
        Text(
          'Label Small - Used for captions and small UI elements',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

/// CoreUI Section Title Widget
class DemoSectionTitle extends StatelessWidget {
  final String title;

  const DemoSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }
}

/// CoreUI Heading Example Widget
class DemoHeadingExample extends StatelessWidget {
  final int level;
  final String text;

  const DemoHeadingExample({
    super.key,
    required this.level,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    late TextStyle style;

    switch (level) {
      case 1:
        style = Theme.of(context).textTheme.displayLarge!;
        break;
      case 2:
        style = Theme.of(context).textTheme.displayMedium!;
        break;
      case 3:
        style = Theme.of(context).textTheme.displaySmall!;
        break;
      case 4:
        style = Theme.of(context).textTheme.headlineLarge!;
        break;
      case 5:
        style = Theme.of(context).textTheme.headlineMedium!;
        break;
      case 6:
        style = Theme.of(context).textTheme.headlineSmall!;
        break;
      default:
        style = Theme.of(context).textTheme.bodyMedium!;
    }

    return Text(text, style: style);
  }
}

/// CoreUI Title Example Widget
class DemoTitleExample extends StatelessWidget {
  final String text;
  final String variant; // 'large', 'medium', 'small'

  const DemoTitleExample({
    super.key,
    required this.text,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    late TextStyle style;

    switch (variant) {
      case 'large':
        style = Theme.of(context).textTheme.titleLarge!;
        break;
      case 'medium':
        style = Theme.of(context).textTheme.titleMedium!;
        break;
      case 'small':
        style = Theme.of(context).textTheme.titleSmall!;
        break;
      default:
        style = Theme.of(context).textTheme.titleMedium!;
    }

    return Text(text, style: style);
  }
}
