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
import 'package:scilense_ar_mobile/services/supabase_service.dart';

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
        final items = _items(isSignedIn);

        return Scaffold(
          // Explicit theme background (same as AppTheme.scaffoldBackgroundColor)
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Chemistry Hub'),
            centerTitle: true,
            automaticallyImplyLeading: false,
            actions: const [ProfileAppBarButton(onlyWhenNoClassroom: true)],
          ),
          body: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = items[index];
              return _HubImageCard(
                title: item.title,
                imageAsset: item.imageAsset,
                onTap: () =>
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: item.builder)),
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

  static const double _cardHeight = 168;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      elevation: 2,
      shadowColor: AppColors.primaryDark.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: _cardHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ~80% image — same treatment on every card
              Expanded(
                flex: 80,
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
                  ],
                ),
              ),
              // ~20% title — identical band on every card
              Expanded(
                flex: 20,
                child: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.primaryLight.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
