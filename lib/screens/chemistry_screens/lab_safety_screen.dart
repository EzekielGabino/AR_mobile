import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/components/lab_safety_hazards/category_chip_bar.dart';
import 'package:scilense_ar_mobile/components/lab_safety_hazards/icon_tile.dart';
import 'package:scilense_ar_mobile/components/lab_safety_hazards/rule_tile.dart';
import 'package:scilense_ar_mobile/components/lab_safety_hazards/section_header.dart';
import 'package:scilense_ar_mobile/data/dos_donts_data.dart';
import 'package:scilense_ar_mobile/data/hazard_data.dart';
import 'package:scilense_ar_mobile/data/signs_data.dart';
import 'package:scilense_ar_mobile/models/safety_item.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

/// Entry point widget for Feature 02 — Laboratory Safety & Hazard.
///
/// The header used to be a bespoke ink-colored Container plus a
/// hand-built SliverPersistentHeader tab bar, which made this screen
/// look like a different app from the rest of SciLense AR. It's now a
/// SliverAppBar using AppColors.primaryDark/headerGradient — the same
/// hero pattern EquipmentGalleryScreen already uses — with its `bottom`
/// slot doing the tab bar instead of a hand-rolled delegate. Only the
/// tab indicator stays a hazard-signal color (yellow) on purpose; the
/// chrome itself now comes from the shared theme.
class LabSafetyScreen extends StatelessWidget {
  const LabSafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: true,
                // Needs to comfortably clear toolbar (~56) + the bottom
                // TabBar (~46) plus the title's own height/padding above
                // that pinned strip — 128 wasn't enough once `bottom` was
                // added, which is what caused the title/tab overlap.
                expandedHeight: 170,
                backgroundColor: AppColors.primaryDark,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsetsDirectional.only(
                    start: 20,
                    bottom: 50,
                  ),
                  centerTitle: false,
                  title: const Text(
                    'Laboratory Safety & Hazard',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.headerGradient,
                    ),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 8),
                        child: Icon(
                          Icons.health_and_safety_outlined,
                          size: 72,
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                  ),
                ),
                bottom: const TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: SafetyColors
                      .yellow, // kept distinct — hazard-signal color
                  indicatorWeight: 3,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                  ),
                  tabs: [
                    Tab(text: "DO'S & DON'TS"),
                    Tab(text: 'HAZARD SYMBOLS'),
                    Tab(text: 'SAFETY SIGNS'),
                  ],
                ),
              ),
            ];
          },

          // ---------------- Tab Content ----------------
          body: const TabBarView(
            children: [
              _DosDontsView(),
              _HazardSymbolsView(),
              _SafetySignsView(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DosDontsView extends StatelessWidget {
  const _DosDontsView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      primary: true,
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeader(
          title: "Lab Do's & Don'ts",
          subtitle:
              "The habits that keep every experiment safe — "
              "and the shortcuts that don't.",
        ),

        const SizedBox(height: 6),

        _RuleGroup(label: 'Always Do', color: SafetyColors.green, items: kDos),

        const SizedBox(height: 20),

        _RuleGroup(label: 'Never Do', color: SafetyColors.red, items: kDonts),

        const SizedBox(height: 20),
      ],
    );
  }
}

class _RuleGroup extends StatelessWidget {
  final String label;
  final Color color;
  final List<SafetyItem> items;

  const _RuleGroup({
    required this.label,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SafetyColors.paperLine),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 0,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: SafetyTextStyles.sectionTitleLight.copyWith(
              color: color,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 8),

          ...items.map((item) => RuleTile(item: item)),
        ],
      ),
    );
  }
}

class _HazardSymbolsView extends StatelessWidget {
  const _HazardSymbolsView();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      primary: true,
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: kHazardSymbols.length,
      itemBuilder: (context, index) {
        return IconTile(item: kHazardSymbols[index]);
      },
    );
  }
}

class _SafetySignsView extends StatefulWidget {
  const _SafetySignsView();

  @override
  State<_SafetySignsView> createState() => _SafetySignsViewState();
}

class _SafetySignsViewState extends State<_SafetySignsView> {
  String _selected = 'All';

  @override
  Widget build(BuildContext context) {
    final items = _selected == 'All'
        ? kSafetySigns
        : kSafetySigns.where((sign) => sign.subCategory == _selected).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: CategoryChipBar(
            categories: kSignCategories,
            selected: _selected,
            onSelected: (category) {
              setState(() {
                _selected = category;
              });
            },
          ),
        ),
        Expanded(
          child: GridView.builder(
            primary: true,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.85,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return IconTile(item: items[index]);
            },
          ),
        ),
      ],
    );
  }
}
