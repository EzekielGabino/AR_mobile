import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/components/lab_equipment_image.dart';
import 'package:scilense_ar_mobile/data/lab_equipment_data.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';
import '../../../models/lab_equipment.dart';
import 'equipment_detail_screen.dart';

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
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildCategoryChips()),
          const SliverToBoxAdapter(child: SizedBox(height: 4)),
          _filtered.isEmpty
              ? const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search equipment...',
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) => setState(() => _query = value),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 46,
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
          return ChoiceChip(
            avatar: Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : AppColors.primary,
            ),
            label: Text(category),
            selected: selected,
            onSelected: (_) => setState(() => _selectedCategory = category),
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: Colors.white,
            elevation: selected ? 2 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: selected ? AppColors.primary : AppColors.primaryLight,
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
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: AppColors.primaryLight,
            ),
            const SizedBox(height: 12),
            const Text(
              'No equipment found',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
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
      child: InkWell(
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
                  top: Radius.circular(18),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipment.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        CategoryStyle.iconFor(equipment.category),
                        size: 13,
                        color: AppColors.primary,
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
