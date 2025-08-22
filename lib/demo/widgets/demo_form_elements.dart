import 'package:flutter/material.dart';

/// CoreUI Demo Form Elements Section Widget
class DemoFormElements extends StatelessWidget {
  final String pageId;
  final bool isEnabled;

  const DemoFormElements({
    super.key,
    required this.pageId,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Form Elements',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (isEnabled) ...[
          DemoEmailField(pageId: pageId, isEnabled: isEnabled),
          const SizedBox(height: 16),
          DemoPasswordField(pageId: pageId, isEnabled: isEnabled),
        ],
      ],
    );
  }
}

/// CoreUI Email Input Field Widget
class DemoEmailField extends StatelessWidget {
  final String pageId;
  final bool isEnabled;

  const DemoEmailField({
    super.key,
    required this.pageId,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: ValueKey('email_field_$pageId'),
      enabled: isEnabled,
      decoration: const InputDecoration(
        labelText: 'Sample Input',
        hintText: 'Enter some text',
        prefixIcon: Icon(Icons.email),
      ),
    );
  }
}

/// CoreUI Password Input Field Widget
class DemoPasswordField extends StatelessWidget {
  final String pageId;
  final bool isEnabled;

  const DemoPasswordField({
    super.key,
    required this.pageId,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: ValueKey('password_field_$pageId'),
      enabled: isEnabled,
      obscureText: true,
      decoration: const InputDecoration(
        labelText: 'Password',
        hintText: 'Enter password',
        prefixIcon: Icon(Icons.lock),
        suffixIcon: Icon(Icons.visibility),
      ),
    );
  }
}

/// CoreUI Search Field Widget
class DemoSearchField extends StatelessWidget {
  final String pageId;
  final bool isEnabled;

  const DemoSearchField({
    super.key,
    required this.pageId,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: ValueKey('search_field_$pageId'),
      enabled: isEnabled,
      decoration: const InputDecoration(
        labelText: 'Search',
        hintText: 'Search something...',
        prefixIcon: Icon(Icons.search),
      ),
    );
  }
}

/// CoreUI Multi-line Text Field Widget
class DemoTextArea extends StatelessWidget {
  final String pageId;
  final bool isEnabled;

  const DemoTextArea({super.key, required this.pageId, this.isEnabled = true});

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: ValueKey('textarea_field_$pageId'),
      enabled: isEnabled,
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: 'Multi-line Text',
        hintText: 'Enter multiple lines of text...',
        alignLabelWithHint: true,
      ),
    );
  }
}
