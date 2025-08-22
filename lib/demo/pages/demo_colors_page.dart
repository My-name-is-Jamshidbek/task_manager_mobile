import 'package:flutter/material.dart';
import '../widgets/demo_colors.dart';

/// CoreUI Demo Colors Page Widget
class DemoColorsPage extends StatelessWidget {
  const DemoColorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: DemoColors(),
    );
  }
}
