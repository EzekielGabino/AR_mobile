import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/models/lab_equipment.dart';
import '../theme/app_theme.dart';

class LabEquipmentImage extends StatelessWidget {
  final LabEquipment equipment;
  final double? height;
  final BorderRadius? borderRadius;
  final bool useHero;

  const LabEquipmentImage({
    super.key,
    required this.equipment,
    this.height,
    this.borderRadius,
    this.useHero = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(16);

    Widget image;
    if (equipment.isNetworkImage) {
      image = Image.network(
        equipment.imagePath,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _fallback(loading: true);
        },
      );
    } else {
      image = Image.asset(
        equipment.imagePath,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }

    final clipped = ClipRRect(borderRadius: radius, child: image);

    if (!useHero) return clipped;

    return Hero(tag: 'equipment-image-${equipment.id}', child: clipped);
  }

  Widget _fallback({bool loading = false}) {
    return Container(
      height: height,
      width: double.infinity,
      color: AppColors.primaryLight.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: loading
          ? const CircularProgressIndicator(color: AppColors.primary)
          : Icon(Icons.science_outlined, size: 40, color: AppColors.primary),
    );
  }
}
