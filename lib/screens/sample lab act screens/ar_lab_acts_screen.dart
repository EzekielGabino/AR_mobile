import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/models/lab_activity_remote.dart';
import 'package:scilense_ar_mobile/services/lab_activity_service.dart';
import 'package:scilense_ar_mobile/screens/sample%20lab%20act%20screens/lab_act_detail_screen.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

/// Lists practice labs from Supabase [practice_lab_activities].
class ArLabActsScreen extends StatefulWidget {
  const ArLabActsScreen({super.key, LabActivityService? service})
    : _service = service;

  final LabActivityService? _service;

  @override
  State<ArLabActsScreen> createState() => _ArLabActsScreenState();
}

class _ArLabActsScreenState extends State<ArLabActsScreen> {
  LabActivityService get service => widget._service ?? LabActivityService();

  late Future<List<LabActivityRemote>> _future;

  @override
  void initState() {
    super.initState();
    _future = service.fetchAll();
  }

  Future<void> _reload() async {
    setState(() {
      _future = service.fetchAll();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // DESIGN: light background to match the rest of the app
      backgroundColor: AppColors.background,
      // AppBar kept exactly as in the previous version (navy bar, light-blue text)
      appBar: AppBar(
        title: const Text('Practice AR Lab Activities'),
        centerTitle: true,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        ),
      ),
      body: FutureBuilder<List<LabActivityRemote>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // DESIGN: red icon above the error message
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppColors.safetyRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load activities.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _reload,
                      // DESIGN: rounded royal-blue button
                      style: FilledButton.styleFrom(
                        backgroundColor: _Palette.royalBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(120, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              // DESIGN: royal-blue loading spinner (visible on light background)
              child: CircularProgressIndicator(color: _Palette.royalBlue),
            );
          }

          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              // DESIGN: pull-to-refresh colors
              color: _Palette.royalBlue,
              backgroundColor: Colors.white,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Center(
                    // DESIGN: icon inside a soft light-blue circle above the empty message
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: _Palette.lightBlue.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.science_outlined,
                            size: 56,
                            color: _Palette.periwinkle,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No lab activities yet.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            // DESIGN: pull-to-refresh colors
            color: _Palette.royalBlue,
            backgroundColor: Colors.white,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              // DESIGN: more breathing room around the list
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final activity = list[index];
                return Card(
                  // DESIGN: white card, periwinkle glow, light-blue border, 16 px radius
                  margin: EdgeInsets.zero,
                  color: Colors.white,
                  elevation: 4,
                  shadowColor: _Palette.periwinkle.withValues(alpha: 0.30),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: _Palette.lightBlue.withValues(alpha: 0.7),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    // DESIGN: tile spacing and shape (ripple matches the card)
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    // DESIGN: decorative gradient icon badge (no logic attached)
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_Palette.royalBlue, _Palette.periwinkle],
                        ),
                      ),
                      child: const Icon(
                        Icons.science_outlined,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    title: Text(
                      activity.title.isEmpty ? activity.id : activity.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        activity.labCategory.isEmpty
                            ? activity.description
                            : activity.labCategory,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: _Palette.periwinkle,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LabActDetailScreen(
                            activityId: activity.id,
                            initialActivity: activity,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// DESIGN: color palette used by this screen only (from the teacher web app).
/// Kept private in this file so nothing else in the project is affected.
class _Palette {
  static const Color navy = Color(0xFF091540);
  static const Color royalBlue = Color(0xFF1B2CC1);
  static const Color periwinkle = Color(0xFF7692FF);
  static const Color lightBlue = Color(0xFFABD2FA);

  // Slightly lighter navy for cards, so they stand out from the background
  static const Color surface = Color(0xFF0F1D5C);
  // Periwinkle at about 30% opacity, for card borders
  static const Color border = Color(0x4D7692FF);
  // Light blue at about 80% opacity, for secondary text
  static const Color subtleText = Color(0xCCABD2FA);
}
