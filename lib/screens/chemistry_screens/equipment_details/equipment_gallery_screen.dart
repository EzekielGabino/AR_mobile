import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/components/lab_equipment_image.dart';
import 'package:scilense_ar_mobile/data/lab_equipment_data.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';
import '../../../models/lab_equipment.dart';
import 'equipment_detail_screen.dart';

// Design-system palette (file-private so it cannot clash with AppColors in app_theme.dart)
const Color _royalBlue = Color(0xFF1B2CC1);
const Color _periwinkle = Color(0xFF7692FF);
const Color _lightBlue = Color(0xFFABD2FA);

class EquipmentGalleryScreen extends StatefulWidget {
  const EquipmentGalleryScreen({super.key});

  @override
  State<EquipmentGalleryScreen> createState() => _EquipmentGalleryScreenState();
}

class _EquipmentGalleryScreenState extends State<EquipmentGalleryScreen> {
  String _query = '';
  String _selectedCategory = 'All';

  List<String> get _categories {
    final cats = sampleEquipmentList.map((e) => e.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  List<LabEquipment> get _filtered {
    return sampleEquipmentList.where((e) {
      final matchesQuery = e.name.toLowerCase().contains(_query.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'All' || e.category == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Explicit theme background (same as AppTheme.scaffoldBackgroundColor)
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 128,
            backgroundColor: AppColors.primaryDark,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 20,
                bottom: 16,
              ),
              centerTitle: false,
              title: const Text(
                'Equipment Gallery',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
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
                      Icons.biotech_outlined,
                      size: 72,
                      // Light-blue tint so the watermark matches the palette
                      color: _lightBlue.withValues(alpha: 0.22),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildCategoryChips()),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          _filtered.isEmpty
              ? const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.78,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _EquipmentTile(equipment: _filtered[index]),
                      childCount: _filtered.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      // Visual only: soft periwinkle glow around the field
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _periwinkle.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          cursorColor: AppColors.accent,
          decoration: InputDecoration(
            hintText: 'Search equipment...',
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.85),
            ),
            prefixIcon: const Icon(Icons.search, color: _periwinkle),
            filled: true,
            fillColor: AppColors.cardBackground,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _lightBlue.withValues(alpha: 0.8),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: _lightBlue.withValues(alpha: 0.8),
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: _royalBlue, width: 1.5),
            ),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = category == _selectedCategory;
          final icon = category == 'All'
              ? Icons.apps_rounded
              : CategoryStyle.iconFor(category);
          final labelColor =
              selected ? Colors.white : AppColors.textPrimary;
          final iconColor =
              selected ? Colors.white : _royalBlue;
          return ChoiceChip(
            showCheckmark: false,
            selected: selected,
            onSelected: (_) => setState(() => _selectedCategory = category),
            // M3: explicit state colors (old selectedColor/backgroundColor are ignored)
            color: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return _royalBlue;
              }
              return Colors.white;
            }),
            side: BorderSide(
              color: selected
                  ? _periwinkle
                  : _lightBlue.withValues(alpha: 0.9),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            avatar: Icon(icon, size: 18, color: iconColor),
            label: Text(
              category,
              style: TextStyle(
                color: labelColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon inside a soft light-blue circle (decorative)
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: _lightBlue.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 56,
                color: _periwinkle,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No equipment found',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try a different keyword or category.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipmentTile extends StatelessWidget {
  final LabEquipment equipment;

  const _EquipmentTile({required this.equipment});

  @override
  Widget build(BuildContext context) {
    return Card(
      // Visual only: white card, periwinkle glow, thin light-blue border, 16 px radius
      color: Colors.white,
      elevation: 4,
      shadowColor: _periwinkle.withValues(alpha: 0.30),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _lightBlue.withValues(alpha: 0.7)),
      ),
      child: InkWell(
        splashColor: _periwinkle.withValues(alpha: 0.18),
        highlightColor: _lightBlue.withValues(alpha: 0.12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EquipmentDetailScreen(equipment: equipment),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LabEquipmentImage(
                equipment: equipment,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
            ),
            // Thin divider between photo and text
            Container(height: 1, color: _lightBlue.withValues(alpha: 0.6)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipment.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        CategoryStyle.iconFor(equipment.category),
                        size: 14,
                        color: _royalBlue,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          equipment.category,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}