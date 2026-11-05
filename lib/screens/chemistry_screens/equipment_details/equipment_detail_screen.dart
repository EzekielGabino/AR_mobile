import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/components/lab_equipment_image.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';
import '../../../models/lab_equipment.dart';

// Design-system palette (file-private so it cannot clash with AppColors in app_theme.dart)
const Color _navy = Color(0xFF091540);
const Color _royalBlue = Color(0xFF1B2CC1);
const Color _periwinkle = Color(0xFF7692FF);
const Color _lightBlue = Color(0xFFABD2FA);
const Color _amber = Color(0xFFF2A413);
const Color _amberDark = Color(0xFF8A5A00); // readable amber text on light backgrounds

class EquipmentDetailScreen extends StatelessWidget {
  final LabEquipment equipment;

  const EquipmentDetailScreen({super.key, required this.equipment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 56,
                bottom: 14,
                end: 16,
              ),
              title: Text(
                equipment.name,
                style: const TextStyle(
                  // Explicit white so the name never inherits a dark theme color
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  // Double shadow = crisp edge + soft dark halo over any photo
                  shadows: [
                    Shadow(blurRadius: 4, color: Colors.black87),
                    Shadow(blurRadius: 12, color: Colors.black87),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  LabEquipmentImage(
                    equipment: equipment,
                    height: 280,
                    borderRadius: BorderRadius.zero,
                  ),
                  // Gradient scrim so the title stays readable over any photo.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Color(0xE6091540), // stronger navy scrim (was 0xCC091540)
                        ],
                        stops: [0.0, 0.35, 1.0], // starts higher (was 0.55)
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -18),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CategoryBadge(category: equipment.category),
                    const SizedBox(height: 16),
                    _Section(
                      icon: Icons.description_outlined,
                      title: 'Description',
                      body: equipment.description,
                    ),
                    _Section(
                      icon: Icons.flag_outlined,
                      title: 'Purpose',
                      body: equipment.purpose,
                    ),
                    _Section(
                      icon: Icons.help_outline,
                      title: 'When to Use',
                      body: equipment.whenToUse,
                    ),
                    _SafetyTipCard(tip: equipment.safetyTip),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _lightBlue.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _periwinkle.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CategoryStyle.iconFor(category),
            size: 16,
            color: _royalBlue,
          ),
          const SizedBox(width: 8),
          Text(
            category,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Section({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    // Light entrance animation (visual only, wraps the original card)
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _lightBlue.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: _periwinkle.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Gradient icon chip (royal blue -> periwinkle)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_royalBlue, _periwinkle],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyTipCard extends StatelessWidget {
  final String tip;
  const _SafetyTipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    // Safety warning uses AMBER per the design system (red is kept for hazards/errors)
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _amber.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: _amber.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _amber.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: _amberDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Safety Tip',
                  style: TextStyle(
                    color: _amberDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}