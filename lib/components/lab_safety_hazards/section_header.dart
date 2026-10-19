import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const SectionHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: SafetyTextStyles.sectionTitle),
          const SizedBox(height: 4),
          Text(subtitle, style: SafetyTextStyles.caption),
        ],
      ),
    );
  }
}
