import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:scilense_ar_mobile/models/element.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

class ElementDetailScreen extends StatelessWidget {
  final ElementData element;

  const ElementDetailScreen({super.key, required this.element});

  Color getCategoryColor() {
    final cat = element.category.toLowerCase().trim();

    if (cat.contains("unknown")) {
      return Colors.blueGrey.shade400;
    }

    switch (cat) {
      case "alkali metal":
      case "alkali":
        return Colors.red.shade300;

      case "alkaline earth metal":
      case "alkaline":
        return Colors.orange.shade300;

      case "transition metal":
      case "transition":
        return Colors.amber.shade500;

      case "post-transition metal":
      case "post-transition":
        return Colors.lightBlue.shade300;

      case "metalloid":
        return Colors.green.shade400;

      case "reactive nonmetal":
      case "diatomic nonmetal":
      case "polyatomic nonmetal":
      case "nonmetal":
        return Colors.teal.shade400;

      case "halogen":
        return Colors.purple.shade300;

      case "noble gas":
        return Colors.pink.shade300;

      case "lanthanide":
        return Colors.cyan.shade400;

      case "actinide":
        return Colors.deepPurple.shade300;

      default:
        return Colors.blueGrey.shade300;
    }
  }

  String getPaddedAtomicNumber() {
    return element.atomicNumber.toString().padLeft(3, '0');
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = getCategoryColor();

    return Scaffold(
      backgroundColor: themeColor.withValues(alpha: 0.55),
      appBar: AppBar(
        title: Text('${element.name} (${element.symbol})'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      themeColor,
                      HSLColor.fromColor(themeColor)
                          .withLightness(
                            (HSLColor.fromColor(themeColor).lightness - 0.15)
                                .clamp(0.0, 1.0),
                          )
                          .toColor(),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${element.atomicNumber}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      element.symbol,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      element.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Element Preview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.background,
              ),
            ),
            const SizedBox(height: 8),

            Card(
              elevation: 2,
              color: Colors.white,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: _ApiElementImage(
                  themeColor: themeColor,
                  elementName: element.name,
                  elementSymbol: element.symbol,
                  atomicNumber: element.atomicNumber,
                  paddedNum: getPaddedAtomicNumber(),
                ),
              ),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.tune_rounded, color: themeColor, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Overview & Properties',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.background,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Card(
              elevation: 2,
              color: themeColor.withValues(
                alpha: 0.75,
                red: 1,
                blue: 0.8,
                green: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    _buildEnhancedDetailRow(
                      icon: Icons.tag,
                      title: 'Atomic Number',
                      value: '${element.atomicNumber}',
                      themeColor: themeColor,
                    ),
                    Divider(
                      height: 1,
                      color: themeColor.withValues(alpha: 0.50),
                      indent: 16,
                      endIndent: 16,
                    ),
                    _buildEnhancedDetailRow(
                      icon: Icons.scale_outlined,
                      title: 'Atomic Mass',
                      value: '${element.atomicMass} u',
                      themeColor: themeColor,
                    ),
                    Divider(
                      height: 1,
                      color: themeColor.withValues(alpha: 0.50),
                      indent: 16,
                      endIndent: 16,
                    ),
                    _buildEnhancedDetailRow(
                      icon: Icons.category_outlined,
                      title: 'Category',
                      value: element.category,
                      themeColor: themeColor,
                      isBadge: true,
                    ),
                    Divider(
                      height: 1,
                      color: themeColor.withValues(alpha: 0.50),
                      indent: 16,
                      endIndent: 16,
                    ),
                    _buildEnhancedDetailRow(
                      icon: Icons.view_week_outlined,
                      title: 'Period',
                      value: '${element.period}',
                      themeColor: themeColor,
                    ),
                    Divider(
                      height: 1,
                      color: themeColor.withValues(alpha: 0.50),
                      indent: 16,
                      endIndent: 16,
                    ),
                    _buildEnhancedDetailRow(
                      icon: Icons.view_column_outlined,
                      title: 'Group',
                      value: '${element.group}',
                      themeColor: themeColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedDetailRow({
    required IconData icon,
    required String title,
    required String value,
    required Color themeColor,
    bool isBadge = false,
  }) {
    if (isBadge) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: themeColor),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 52.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: themeColor.withValues(alpha: 1),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: themeColor),
          ),
          const SizedBox(width: 14),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApiElementImage extends StatefulWidget {
  final Color themeColor;
  final String elementName;
  final String elementSymbol;
  final int atomicNumber;
  final String paddedNum;

  const _ApiElementImage({
    required this.themeColor,
    required this.elementName,
    required this.elementSymbol,
    required this.atomicNumber,
    required this.paddedNum,
  });

  @override
  State<_ApiElementImage> createState() => _ApiElementImageState();
}

class _ApiElementImageState extends State<_ApiElementImage> {
  List<String> _imageUrls = [];
  int _currentUrlIndex = 0;
  bool _isLoading = true;
  bool get _isSyntheticOrRadioactive =>
      widget.atomicNumber == 43 ||
      widget.atomicNumber == 61 ||
      widget.atomicNumber >= 93;

  @override
  void initState() {
    super.initState();
    _fetchImageUrls();
  }

  Future<void> _fetchImageUrls() async {
    if (_isSyntheticOrRadioactive) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final cleanName = widget.elementName.toLowerCase().trim();
    final pubChemUrl =
        'https://pubchem.ncbi.nlm.nih.gov/rest/pug/element/atomicnumber/${widget.atomicNumber}/PNG';
    final periodicTableUrl =
        'https://periodictable.com/Elements/300/${widget.paddedNum}.1.jpg';
    final imagesOfElementsUrl = 'https://images-of-elements.com/$cleanName.jpg';
    String? wikiImage;
    try {
      final wikiUrl = Uri.parse(
        'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(widget.elementName)}',
      );
      final response = await http
          .get(wikiUrl)
          .timeout(const Duration(milliseconds: 1200));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        wikiImage = data['thumbnail']?['source'];
      }
    } catch (_) {}

    final List<String> urls = [
      pubChemUrl,
      if (wikiImage != null && wikiImage.isNotEmpty) wikiImage,
      periodicTableUrl,
      imagesOfElementsUrl,
    ];

    if (mounted) {
      setState(() {
        _imageUrls = urls;
        _isLoading = false;
      });
    }
  }

  void _nextUrl() {
    if (_currentUrlIndex < _imageUrls.length) {
      setState(() {
        _currentUrlIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: widget.themeColor));
    }

    if (_isSyntheticOrRadioactive || _currentUrlIndex >= _imageUrls.length) {
      return _buildAtomicModelVisual();
    }

    return Image.network(
      _imageUrls[_currentUrlIndex],
      fit: BoxFit.cover,
      key: ValueKey(_imageUrls[_currentUrlIndex]),
      cacheWidth: 600,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(color: widget.themeColor),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _nextUrl());
        return Center(
          child: CircularProgressIndicator(color: widget.themeColor),
        );
      },
    );
  }

  Widget _buildAtomicModelVisual() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0F172A),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(double.infinity, 200),
            painter: _BohrAtomPainter(
              atomicNumber: widget.atomicNumber,
              color: widget.themeColor,
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: widget.themeColor.withOpacity(0.5)),
              ),
              child: Text(
                _isSyntheticOrRadioactive
                    ? 'Synthetic Structure'
                    : 'Atomic Model',
                style: TextStyle(
                  color: widget.themeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BohrAtomPainter extends CustomPainter {
  final int atomicNumber;
  final Color color;

  _BohrAtomPainter({required this.atomicNumber, required this.color});

  List<int> _calculateElectronShells(int z) {
    final capacities = [2, 8, 18, 32, 32, 18, 8];
    List<int> shells = [];
    int remaining = z;

    for (int cap in capacities) {
      if (remaining <= 0) break;
      int count = math.min(remaining, cap);
      shells.add(count);
      remaining -= count;
    }
    return shells;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.42;

    // Nucleus
    final nucleusPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final nucleusGlow = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(center, 14, nucleusGlow);
    canvas.drawCircle(center, 10, nucleusPaint);

    final List<int> shells = _calculateElectronShells(atomicNumber);
    final double step = (maxRadius - 20) / math.max(shells.length, 1);

    final shellPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final electronPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < shells.length; i++) {
      final radius = 22 + (i + 1) * step;
      canvas.drawCircle(center, radius, shellPaint);

      int electrons = shells[i];
      for (int e = 0; e < electrons; e++) {
        double angle = (2 * math.pi / electrons) * e;
        double ex = center.dx + radius * math.cos(angle);
        double ey = center.dy + radius * math.sin(angle);
        canvas.drawCircle(Offset(ex, ey), 3, electronPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BohrAtomPainter oldDelegate) {
    return oldDelegate.atomicNumber != atomicNumber ||
        oldDelegate.color != color;
  }
}
