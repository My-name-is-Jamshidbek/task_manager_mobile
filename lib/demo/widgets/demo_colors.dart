import 'package:flutter/material.dart';
import '../../core/constants/theme_constants.dart';

/// CoreUI Demo Color Section Widget
class DemoColors extends StatelessWidget {
  const DemoColors({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DemoColorSectionTitle(title: 'CoreUI Brand Colors'),
        const SizedBox(height: 16),
        const DemoBrandColorsGrid(),
        const SizedBox(height: 24),
        const DemoColorSectionTitle(title: 'Gray Scale Colors'),
        const SizedBox(height: 16),
        const DemoGrayScaleColorsGrid(),
        const SizedBox(height: 24),
        const DemoColorSectionTitle(title: 'Priority Colors'),
        const SizedBox(height: 16),
        const DemoPriorityColorsGrid(),
      ],
    );
  }
}

/// CoreUI Color Section Title Widget
class DemoColorSectionTitle extends StatelessWidget {
  final String title;

  const DemoColorSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }
}

/// CoreUI Brand Colors Grid Widget
class DemoBrandColorsGrid extends StatelessWidget {
  const DemoBrandColorsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        DemoColorCard(
          color: AppThemeConstants.primary,
          name: 'Primary',
          hex: '#5856D6',
        ),
        DemoColorCard(
          color: AppThemeConstants.secondary,
          name: 'Secondary',
          hex: '#6B7785',
        ),
        DemoColorCard(
          color: AppThemeConstants.success,
          name: 'Success',
          hex: '#1B9E3E',
        ),
        DemoColorCard(
          color: AppThemeConstants.danger,
          name: 'Danger',
          hex: '#E55353',
        ),
        DemoColorCard(
          color: AppThemeConstants.warning,
          name: 'Warning',
          hex: '#F9B115',
        ),
        DemoColorCard(
          color: AppThemeConstants.info,
          name: 'Info',
          hex: '#3399FF',
        ),
      ],
    );
  }
}

/// CoreUI Gray Scale Colors Grid Widget
class DemoGrayScaleColorsGrid extends StatelessWidget {
  const DemoGrayScaleColorsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        DemoColorCard(
          color: AppThemeConstants.gray100,
          name: 'Gray 100',
          hex: '#F8F9FA',
        ),
        DemoColorCard(
          color: AppThemeConstants.gray200,
          name: 'Gray 200',
          hex: '#E9ECEF',
        ),
        DemoColorCard(
          color: AppThemeConstants.gray300,
          name: 'Gray 300',
          hex: '#DEE2E6',
        ),
        DemoColorCard(
          color: AppThemeConstants.gray400,
          name: 'Gray 400',
          hex: '#CED4DA',
        ),
        DemoColorCard(
          color: AppThemeConstants.gray500,
          name: 'Gray 500',
          hex: '#ADB5BD',
        ),
        DemoColorCard(
          color: AppThemeConstants.gray600,
          name: 'Gray 600',
          hex: '#6C757D',
        ),
        DemoColorCard(
          color: AppThemeConstants.gray700,
          name: 'Gray 700',
          hex: '#495057',
        ),
        DemoColorCard(
          color: AppThemeConstants.gray800,
          name: 'Gray 800',
          hex: '#343A40',
        ),
        DemoColorCard(
          color: AppThemeConstants.gray900,
          name: 'Gray 900',
          hex: '#212529',
        ),
      ],
    );
  }
}

/// CoreUI Priority Colors Grid Widget
class DemoPriorityColorsGrid extends StatelessWidget {
  const DemoPriorityColorsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        DemoColorCard(
          color: AppThemeConstants.priorityHigh,
          name: 'High Priority',
          hex: '#E55353',
        ),
        DemoColorCard(
          color: AppThemeConstants.priorityMedium,
          name: 'Medium Priority',
          hex: '#F9B115',
        ),
        DemoColorCard(
          color: AppThemeConstants.priorityLow,
          name: 'Low Priority',
          hex: '#1B9E3E',
        ),
      ],
    );
  }
}

/// CoreUI Individual Color Card Widget
class DemoColorCard extends StatelessWidget {
  final Color color;
  final String name;
  final String hex;

  const DemoColorCard({
    super.key,
    required this.color,
    required this.name,
    required this.hex,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = color.computeLuminance() > 0.5;
    final textColor = isLight
        ? AppThemeConstants.black
        : AppThemeConstants.white;

    return Container(
      width: 120,
      height: 100,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemeConstants.gray300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              hex,
              style: TextStyle(
                color: textColor,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
