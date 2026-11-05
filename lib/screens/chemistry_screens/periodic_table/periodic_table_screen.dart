import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/components/periodic_table/element_tile.dart';
import 'package:scilense_ar_mobile/components/periodic_table/periodic_table_legend.dart';
import 'package:scilense_ar_mobile/models/element.dart';
import 'package:scilense_ar_mobile/services/periodic_table_service.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

class PeriodicTableScreen extends StatefulWidget {
  const PeriodicTableScreen({super.key});

  @override
  State<PeriodicTableScreen> createState() => _PeriodicTableScreenState();
}

class _PeriodicTableScreenState extends State<PeriodicTableScreen>
    with SingleTickerProviderStateMixin {
  final service = PeriodicTableService();
  late Future<List<ElementData>> futureElements;

  final TransformationController _transformationController =
      TransformationController();

  late AnimationController _animationController;
  Animation<Matrix4>? _zoomAnimation;
  bool _isControlsActive = false;

  @override
  void initState() {
    super.initState();
    futureElements = service.loadElements();
    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 250),
        )..addListener(() {
          if (_zoomAnimation != null) {
            _transformationController.value = _zoomAnimation!.value;
          }
        });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _animateZoom(double factor) {
    final Matrix4 currentMatrix = _transformationController.value;
    final double currentScale = currentMatrix.getMaxScaleOnAxis();

    final double targetScale = (currentScale * factor).clamp(0.3, 8.0);
    final double actualFactor = targetScale / currentScale;

    final Matrix4 targetMatrix = currentMatrix.clone()..scale(actualFactor);

    _zoomAnimation = Matrix4Tween(begin: currentMatrix, end: targetMatrix)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward(from: 0);
  }

  void _resetZoom() {
    _zoomAnimation =
        Matrix4Tween(
          begin: _transformationController.value,
          end: Matrix4.identity(),
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward(from: 0);
  }

  Widget _buildMiniButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildPointerAnnotation({
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: SafetyColors.paperLine,
            shape: BoxShape.circle,
          ),
        ),
        Container(width: 12, height: 1.5, color: SafetyColors.paperLine),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
              children: [
                TextSpan(
                  text: "$label: ",
                  style: SafetyTextStyles.tileTitleLight.copyWith(
                    fontSize: 14,
                    fontWeight: .bold,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: SafetyTextStyles.tileTitleLight.copyWith(
                    fontSize: 14,
                    color: SafetyColors.gray,
                    fontWeight: .w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const double baseTileSize = 54.0;
    const double labelWidth = 32.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Periodic Table",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        ),
      ),

      body: FutureBuilder<List<ElementData>>(
        future: futureElements,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final elements = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(5.0),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  // ELEMENT GUIDE CARD
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryLight.withValues(alpha: 0.25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D47A1).withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Card(
                      color: AppColors.primary,
                      elevation: 0,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: const Color(0xFF1E88E5).withOpacity(0.18),
                          width: 1.2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Element Guide",
                              style: SafetyTextStyles.sectionTitleLight,
                            ),
                            const SizedBox(height: 16),
                            // Diagram Container
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade400,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.teal.shade200.withOpacity(
                                          0.5,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Top Row: Atomic Number
                                      const Text(
                                        '1',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      // Center: Symbol
                                      const Center(
                                        child: Text(
                                          'H',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                                      // Bottom Row: Name & Atomic Mass
                                      Column(
                                        children: const [
                                          Center(
                                            child: Text(
                                              'Hydrogen',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          SizedBox(height: 1),
                                          Center(
                                            child: Text(
                                              '1.008',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    children: [
                                      _buildPointerAnnotation(
                                        label: "Atomic Number",
                                        value: "1",
                                      ),
                                      const SizedBox(height: 6),
                                      _buildPointerAnnotation(
                                        label: "Symbol",
                                        value: "H",
                                      ),
                                      const SizedBox(height: 7),
                                      _buildPointerAnnotation(
                                        label: "Name",
                                        value: "Hydrogen",
                                      ),
                                      const SizedBox(height: 4),
                                      _buildPointerAnnotation(
                                        label: "Atomic Mass",
                                        value: "1.008",
                                      ),
                                      const SizedBox(height: 2),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  // LEGEND CARD
                  PeriodicTableLegend(),

                  const SizedBox(height: 16),
                  // PERIODIC TABLE CARD
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryLight.withValues(alpha: 0.25),
                      ),
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
                        children: [
                          Container(
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
                                const Text(
                                  "Periodic Table",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(
                                        Icons.touch_app_outlined,
                                        size: 15,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        "Pinch/tap to zoom",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: const Color(0xFF1E88E5).withOpacity(0.12),
                          ),
                          SizedBox(
                            height: 520,
                            child: Stack(
                              children: [
                                InteractiveViewer(
                                  transformationController:
                                      _transformationController,
                                  minScale: 0.3,
                                  maxScale: 8.0,
                                  panEnabled: true,
                                  scaleEnabled: true,
                                  trackpadScrollCausesScale: true,
                                  interactionEndFrictionCoefficient: 0.00001,
                                  clipBehavior: Clip.hardEdge,
                                  constrained: false,
                                  boundaryMargin: const EdgeInsets.all(80),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const SizedBox(width: labelWidth),
                                            ...List.generate(18, (group) {
                                              return SizedBox(
                                                width: baseTileSize,
                                                height: 24,
                                                child: Center(
                                                  child: Text(
                                                    '${group + 1}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                      color: Color(0xFF1E88E5),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          ],
                                        ),

                                        const SizedBox(height: 4),

                                        ...List.generate(7, (period) {
                                          return Row(
                                            children: [
                                              SizedBox(
                                                width: labelWidth,
                                                height: baseTileSize,
                                                child: Center(
                                                  child: Text(
                                                    '${period + 1}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                      color: Color(0xFF1E88E5),
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              ...List.generate(18, (group) {
                                                final matches = elements.where(
                                                  (e) =>
                                                      e.period == period + 1 &&
                                                      e.group == group + 1,
                                                );

                                                if (matches.isEmpty) {
                                                  return const SizedBox(
                                                    width: baseTileSize,
                                                    height: baseTileSize,
                                                  );
                                                }

                                                return ElementTile(
                                                  element: matches.first,
                                                  tileSize: baseTileSize,
                                                );
                                              }),
                                            ],
                                          );
                                        }),

                                        const SizedBox(height: 24),

                                        // LANTHANIDES
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(
                                              width: 100,
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  top: 16,
                                                ),
                                                child: Text(
                                                  "Lanthanides",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: AppColors.accentSoft,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            ...elements
                                                .where((e) => e.period == 9)
                                                .map(
                                                  (e) => ElementTile(
                                                    element: e,
                                                    tileSize: baseTileSize,
                                                  ),
                                                ),
                                          ],
                                        ),

                                        const SizedBox(height: 12),

                                        // ACTINIDES
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(
                                              width: 100,
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  top: 16,
                                                ),
                                                child: Text(
                                                  "Actinides",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    color: AppColors.accentSoft,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            ...elements
                                                .where((e) => e.period == 10)
                                                .map(
                                                  (e) => ElementTile(
                                                    element: e,
                                                    tileSize: baseTileSize,
                                                  ),
                                                ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: MouseRegion(
                                    onEnter: (_) => setState(
                                      () => _isControlsActive = true,
                                    ),
                                    onExit: (_) => setState(
                                      () => _isControlsActive = false,
                                    ),
                                    child: GestureDetector(
                                      onTapDown: (_) => setState(
                                        () => _isControlsActive = true,
                                      ),
                                      onTapCancel: () => setState(
                                        () => _isControlsActive = false,
                                      ),
                                      child: AnimatedOpacity(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        opacity: _isControlsActive ? 1.0 : 0.4,
                                        child: Material(
                                          color: const Color(0xFF0D47A1),
                                          elevation: 4,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _buildMiniButton(
                                                icon: Icons.add_rounded,
                                                tooltip: "Zoom In",
                                                onPressed: () =>
                                                    _animateZoom(1.3),
                                              ),
                                              Container(
                                                height: 1,
                                                width: 18,
                                                color: Colors.white24,
                                              ),
                                              _buildMiniButton(
                                                icon: Icons.remove_rounded,
                                                tooltip: "Zoom Out",
                                                onPressed: () =>
                                                    _animateZoom(0.7),
                                              ),
                                              Container(
                                                height: 1,
                                                width: 18,
                                                color: Colors.white24,
                                              ),
                                              _buildMiniButton(
                                                icon: Icons
                                                    .center_focus_strong_outlined,
                                                tooltip: "Reset Zoom",
                                                onPressed: _resetZoom,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiagramAnnotation({
    required String label,
    required String value,
  }) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          "$label: ",
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0D47A1),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1E88E5),
          ),
        ),
      ],
    );
  }
}
