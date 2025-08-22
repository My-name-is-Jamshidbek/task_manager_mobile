import 'package:flutter/material.dart';
import '../widgets/demo_typography.dart';

/// CoreUI Demo Typography Page Widget
class DemoTypographyPage extends StatelessWidget {
  const DemoTypographyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: DemoTypography(),
    );
  }
}
