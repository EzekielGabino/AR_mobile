import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/models/safety_item.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

import 'detail_sheet.dart';

class IconTile extends StatelessWidget {
  final SafetyItem item;
  const IconTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => showSafetyDetailSheet(context, item),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SafetyColors.paperLine),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14101518),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 5,
              decoration: BoxDecoration(color: item.accentColor),
            ),
            const SizedBox(height: 14),
            Icon(item.icon, color: item.accentColor, size: 34),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                item.title,
                textAlign: TextAlign.center,
                style: SafetyTextStyles.tileTitleDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(item.code, style: SafetyTextStyles.code),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}
