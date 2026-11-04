import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/services/lab_onboarding_store.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

class _OnboardSlide {
  const _OnboardSlide({
    required this.title,
    required this.body,
    required this.icon,
    this.imageAsset,
  });

  final String title;
  final String body;
  final IconData icon;

  /// Optional screenshot path (e.g. assets/onboarding/apparatus.png).
  final String? imageAsset;
}

/// Pre-Unity walkthrough of AR lab controls.
/// Returns `true` via [Navigator.pop] when the user continues to the lab.
///
/// Set [asGuide] when opened from the Unity lab info button — button says
/// "Done" and the "don't show again" checkbox is hidden.
class LabOnboardingScreen extends StatefulWidget {
  const LabOnboardingScreen({super.key, this.asGuide = false});

  final bool asGuide;

  @override
  State<LabOnboardingScreen> createState() => _LabOnboardingScreenState();
}

class _LabOnboardingScreenState extends State<LabOnboardingScreen> {
  final _controller = PageController();
  int _index = 0;
  bool _dontShowAgain = false;

  /// Swap [imageAsset] values when your screenshots are ready under assets/onboarding/.
  static const _slides = <_OnboardSlide>[
    _OnboardSlide(
      title: 'Apparatus bar',
      body: 'Choose lab equipment from the apparatus bar at the bottom of the screen when a step asks you to place apparatus.',
      icon: Icons.science_outlined,
      imageAsset: 'assets/onboarding/apparatus.jpg',
    ),
    _OnboardSlide(
      title: 'Elements bar',
      body: 'Pick substances from the elements bar at the bottom when a step asks you to add an element to an apparatus.',
      icon: Icons.bubble_chart_outlined,
      imageAsset: 'assets/onboarding/elements.jpg',
    ),
    _OnboardSlide(
      title: 'Step instructions',
      body: 'Read the instruction panel for the current step. A short tip above it explains which controls to use.',
      icon: Icons.menu_book_outlined,
      imageAsset: 'assets/onboarding/instructions.jpg',
    ),

    _OnboardSlide(
      title: 'Placement indicator',
      body: 'When placing apparatus, hold the phone at a steady angle and distance from the table until the placement indicator appears.',
      icon: Icons.center_focus_strong_outlined,
      imageAsset: 'assets/onboarding/placement.jpg',
    ),
    _OnboardSlide(
      title: 'Apparatus Manager Panel',
      body: 'Tap a Placed Apparatus in the Table and See the Apparatus Info and Contained Elements. You can also minimize the Panel or remove the Apparatus',
      icon: Icons.menu_book_outlined,
      imageAsset: 'assets/onboarding/apparatusPanel.jpg',
    ),
    _OnboardSlide(
      title: 'Back & reset',
      body: 'Use Back to leave the lab (progress for this session is cleared in Unity). Use Reset to restart the current lab from the first step.',
      icon: Icons.restart_alt,
      imageAsset: 'assets/onboarding/controls.jpg',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_dontShowAgain) {
      await LabOnboardingStore.setDismissed(true);
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _next() {
    if (_index < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _index >= _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lab guide'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [TextButton(onPressed: _finish, child: const Text('Skip'))],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.accent
                        : AppColors.primaryLight.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
          ),
          if (last && !widget.asGuide)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: CheckboxListTile(
                value: _dontShowAgain,
                onChanged: (v) => setState(() => _dontShowAgain = v ?? false),
                title: const Text(
                  "Don't show this guide again",
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                activeColor: AppColors.primaryLight,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(
                    last
                        ? (widget.asGuide ? 'Done' : 'Start lab')
                        : 'Next',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _OnboardSlide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Material(
              color: AppColors.cardBackground,
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: slide.imageAsset != null
                  ? Image.asset(
                      slide.imageAsset!,
                      fit: BoxFit.fitWidth,
                      errorBuilder: (_, __, ___) =>
                          _IconFallback(icon: slide.icon),
                    )
                  : _IconFallback(icon: slide.icon),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _IconFallback extends StatelessWidget {
  const _IconFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryDark.withValues(alpha: 0.5),
      alignment: Alignment.center,
      child: Icon(icon, size: 88, color: AppColors.accent),
    );
  }
}
