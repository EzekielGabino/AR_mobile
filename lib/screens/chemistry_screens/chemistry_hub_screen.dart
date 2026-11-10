import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/screens/chemistry_screens/elements_memory/element_memory_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scilense_ar_mobile/components/profile_app_bar_button.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';
import 'package:scilense_ar_mobile/screens/chemistry_screens/lab_safety_screen.dart';
import 'package:scilense_ar_mobile/screens/chemistry_screens/object_detection_screen.dart';
import 'package:scilense_ar_mobile/screens/chemistry_screens/equipment_details/equipment_gallery_screen.dart';
import 'package:scilense_ar_mobile/screens/chemistry_screens/periodic_table/periodic_table_screen.dart';
import 'package:scilense_ar_mobile/screens/sample%20lab%20act%20screens/ar_lab_acts_screen.dart';
import 'package:scilense_ar_mobile/services/auth_service.dart';
import 'package:scilense_ar_mobile/screens/people%20screens/profile_screen.dart';
import 'package:scilense_ar_mobile/services/supabase_service.dart';

// Design-system palette (file-private so it cannot clash with AppColors in app_theme.dart)
const Color _navy = Color(0xFF091540);
const Color _royalBlue = Color(0xFF1B2CC1);
const Color _periwinkle = Color(0xFF7692FF);
const Color _lightBlue = Color(0xFFABD2FA);
const Color _amber = Color(0xFFF2A413);

class _HubItem {
  const _HubItem({
    required this.title,
    required this.imageAsset,
    required this.builder,
  });

  final String title;
  final String imageAsset;
  final WidgetBuilder builder;
}

class ChemistryHubScreen extends StatelessWidget {
  const ChemistryHubScreen({super.key});

  List<_HubItem> _items(bool isSignedIn) {
    return [
      if (isSignedIn)
        _HubItem(
          title: 'Practice AR Lab Activities',
          imageAsset: 'assets/for_cards/AR.png',
          builder: (_) => ArLabActsScreen(),
        ),
      _HubItem(
        title: 'Object Detection',
        imageAsset: 'assets/for_cards/object.png',
        builder: (_) => const ObjectDetectionScreen(),
      ),
      _HubItem(
        title: 'Laboratory Equipment Info',
        imageAsset: 'assets/for_cards/equipment.png',
        builder: (_) => const EquipmentGalleryScreen(),
      ),
      _HubItem(
        title: 'Laboratory Safety Hazards',
        imageAsset: 'assets/for_cards/hazards.jpg',
        builder: (_) => LabSafetyScreen(),
      ),
      _HubItem(
        title: 'Periodic Table',
        imageAsset: 'assets/for_cards/elements.jpg',
        builder: (_) => PeriodicTableScreen(),
      ),
      _HubItem(
        title: 'Element Memory',
        imageAsset: 'assets/for_cards/elem_activity.jpg',
        builder: (_) => const ElementMemoryScreen(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SupabaseService.client.auth.onAuthStateChange,
      builder: (context, authSnap) {
        final user = AuthService().currentUser;
        final isSignedIn =
            user != null || SupabaseService.client.auth.currentSession != null;
        if (!isSignedIn) {
          // Chemistry Hub is signed-in only; bounce to Profile.
          return const ProfileScreen();
        }
        final items = _items(isSignedIn);

        return Scaffold(
          // Explicit theme background (same as AppTheme.scaffoldBackgroundColor)
          backgroundColor: AppColors.background,
          // AppBar restored to the ORIGINAL (uses the app theme's AppBar style)
          appBar: AppBar(
            title: const Text('Chemistry Hub'),
            centerTitle: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            elevation: 2,
            surfaceTintColor: Colors.transparent,
            actions: const [ProfileAppBarButton(onlyWhenNoClassroom: true)],
          ),
          body: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final item = items[index];
              // Light entrance animation (visual only, does not touch the card or onTap)
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
                child: _HubImageCard(
                  title: item.title,
                  imageAsset: item.imageAsset,
                  onTap: () =>
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: item.builder)),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Unified hub card: shared frame, blue wash on photo, same title band.
class _HubImageCard extends StatelessWidget {
  const _HubImageCard({
    required this.title,
    required this.imageAsset,
    required this.onTap,
  });

  final String title;
  final String imageAsset;
  final VoidCallback onTap;

  static const double _cardHeight = 176;

  /// Friendly icon per hub card (visual only; falls back to a science icon).
  IconData _iconForTitle(String title) {
    switch (title) {
      case 'Practice AR Lab Activities':
        return Icons.view_in_ar_rounded;
      case 'Object Detection':
        return Icons.center_focus_strong_rounded;
      case 'Laboratory Equipment Info':
        return Icons.biotech_rounded;
      case 'Laboratory Safety Hazards':
        return Icons.warning_amber_rounded;
      case 'Periodic Table':
        return Icons.grid_view_rounded;
      case 'Element Memory':
        return Icons.psychology_rounded;
      default:
        return Icons.science_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isHazard = title == 'Laboratory Safety Hazards';

    return Material(
      color: AppColors.cardBackground,
      elevation: 4,
      shadowColor: _periwinkle.withValues(alpha: 0.30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _lightBlue.withValues(alpha: 0.7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: _periwinkle.withValues(alpha: 0.18),
        highlightColor: _lightBlue.withValues(alpha: 0.12),
        child: SizedBox(
          height: _cardHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ~72% image — same treatment on every card
              Expanded(
                flex: 72,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      imageAsset,
                      fit: BoxFit.cover,
                      // Unify photo cast toward navy palette
                      color: AppColors.primaryDark.withValues(alpha: 0.35),
                      colorBlendMode: BlendMode.srcATop,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primaryLight.withValues(alpha: 0.35),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.science_outlined,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    // Top-to-bottom wash so all cards share the same cast
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primaryDark.withValues(alpha: 0.2),
                            AppColors.primaryDark.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                    // Icon chip: semi-transparent navy so the photo still shows through
                    Positioned(
                      left: 16,
                      top: 16,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _navy.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _periwinkle.withValues(alpha: 0.7),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _periwinkle.withValues(alpha: 0.45),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Icon(
                          _iconForTitle(title),
                          size: 24,
                          color: isHazard ? _amber : _lightBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ~28% title — identical band on every card
              Expanded(
                flex: 28,
                child: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.primaryLight.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Gradient arrow button (decorative; the whole card is the tap target)
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_royalBlue, _periwinkle],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _royalBlue.withValues(alpha: 0.30),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}