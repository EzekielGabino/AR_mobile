import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/data/lab_equipment_data.dart';

class DetectionOverlay extends StatelessWidget {
  final String className;

  const DetectionOverlay({super.key, required this.className});

  @override
  Widget build(BuildContext context) {
    // No Positioned here — the caller (e.g. ObjectDetectionScreen) already
    // wraps this in its own Positioned as a direct Stack child. Returning
    // another Positioned from this build() would nest it inside that
    // Positioned's child slot instead of being a direct Stack child,
    // which Flutter doesn't allow (throws Incorrect use of
    // ParentDataWidget at runtime).
    return GestureDetector(
      onTap: () => _showInfoSheet(context, className),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.info_outline,
          color: Colors.blueAccent,
          size: 24,
        ),
      ),
    );
  }

  void _showInfoSheet(BuildContext context, String className) {
    final equipment = findEquipmentById(className);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              equipment?.name ?? className,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(equipment?.description ?? 'No description available.'),
            if (equipment != null) ...[
              const SizedBox(height: 12),
              Text('Purpose', style: Theme.of(context).textTheme.titleSmall),
              Text(equipment.purpose),
              const SizedBox(height: 12),
              Text(
                'When to use',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(equipment.whenToUse),
              const SizedBox(height: 12),
              Text(
                'Safety tip',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: Colors.redAccent),
              ),
              Text(
                equipment.safetyTip,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
