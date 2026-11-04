import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/models/safety_item.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

import 'detail_sheet.dart';

class RuleTile extends StatelessWidget {
  final SafetyItem item;
  const RuleTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showSafetyDetailSheet(context, item),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: SafetyColors.paperLine, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(item.icon, color: item.accentColor, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: SafetyTextStyles.tileTitleLight),
                  const SizedBox(height: 2),
                  Text(item.shortDescription, style: SafetyTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
