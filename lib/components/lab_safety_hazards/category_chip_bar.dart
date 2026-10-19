import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

class CategoryChipBar extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const CategoryChipBar({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isActive = cat == selected;
          return ChoiceChip(
            label: Text(
              cat.toUpperCase(),
              style: SafetyTextStyles.code.copyWith(
                color: isActive ? Colors.white : SafetyColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            selected: isActive,
            onSelected: (_) => onSelected(cat),
            selectedColor: SafetyColors.ink,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isActive ? SafetyColors.ink : SafetyColors.paperLine,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }
}
