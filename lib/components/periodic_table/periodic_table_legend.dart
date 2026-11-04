import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

class PeriodicTableLegend extends StatefulWidget {
  const PeriodicTableLegend({super.key});

  @override
  State<PeriodicTableLegend> createState() => _PeriodicTableLegendState();
}

class _PeriodicTableLegendState extends State<PeriodicTableLegend> {
  // Toggle state: defaults to collapsed (false) or expanded (true)
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Exact category names and color mappings preserved
    final List<_LegendCategory> categories = [
      _LegendCategory("Alkali Metal", Colors.red.shade300, Colors.red.shade900),
      _LegendCategory(
        "Alkaline Earth Metal",
        Colors.orange.shade300,
        Colors.orange.shade900,
      ),
      _LegendCategory(
        "Transition Metal",
        Colors.amber.shade500,
        Colors.amber.shade900,
      ),
      _LegendCategory(
        "Post-transition Metal",
        Colors.lightBlue.shade300,
        Colors.lightBlue.shade900,
      ),
      _LegendCategory(
        "Metalloid",
        Colors.green.shade400,
        Colors.green.shade900,
      ),
      _LegendCategory(
        "Reactive Non-metal",
        Colors.teal.shade400,
        Colors.teal.shade900,
      ),
      _LegendCategory(
        "Halogen",
        Colors.purple.shade300,
        Colors.purple.shade900,
      ),
      _LegendCategory("Noble Gas", Colors.pink.shade300, Colors.pink.shade900),
      _LegendCategory("Lanthanide", Colors.cyan.shade400, Colors.cyan.shade900),
      _LegendCategory(
        "Actinide",
        Colors.deepPurple.shade300,
        Colors.deepPurple.shade900,
      ),
      _LegendCategory(
        "Unknown",
        Colors.blueGrey.shade300,
        Colors.blueGrey.shade900,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.background),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Card(
        color: AppColors.background,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFF1E88E5).withOpacity(0.18),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blue Gradient Card Header (Clickable to Expand/Collapse)
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.category_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Element Categories",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    // Indicator Icon showing current expansion state
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            // Smooth height transition for showing/hiding legend tags
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: categories.map((cat) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cat.color.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cat.color, width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: cat.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cat.textColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendCategory {
  final String label;
  final Color color;
  final Color textColor;

  const _LegendCategory(this.label, this.color, this.textColor);
}
