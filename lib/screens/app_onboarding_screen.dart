import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/services/app_onboarding_store.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

class _Slide {
  const _Slide({
    required this.title,
    required this.body,
    required this.imageAsset,
  });

  final String title;
  final String body;
  final String imageAsset;
}

class AppOnboardingScreen extends StatefulWidget {
  const AppOnboardingScreen({super.key});

  @override
  State<AppOnboardingScreen> createState() => _AppOnboardingScreenState();
}

class _AppOnboardingScreenState extends State<AppOnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = <_Slide>[
    _Slide(
      title: 'Welcome to ScilenseAR',
      body:
          'Sign in with Google on Profile to join your class, submit labs, and track activities.',
      imageAsset: 'assets/app_onboarding/welcome.jpg',
    ),
    _Slide(
      title: 'Join your class',
      body:
          'Scan your teacher\'s QR code or enter the class access code. Your teacher must approve before the classroom opens.',
      imageAsset: 'assets/app_onboarding/join-classroom.jpg',
    ),
    _Slide(
      title: 'Chemistry Hub',
      body:
          'Explore practice labs, the periodic table, equipment info, and safety tips from the Chemistry Hub (available after you sign in).',
      imageAsset: 'assets/app_onboarding/chemistry_hub.jpg',
    ),
    _Slide(
      title: 'Class activities',
      body:
          'After you are approved, use Home for the class stream and Activities for assigned labs and deadlines. Alerts notify you about new posts and returns.',
      imageAsset: 'assets/app_onboarding/class_activities.jpg',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await AppOnboardingStore.setCompleted(true);
    if (!mounted) return;
    Navigator.of(context).pop();
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
        title: const Text('Getting started'),
        centerTitle: true,
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _finish,
            child: const Text('Skip', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) {
                final s = _slides[i];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Material(
                          color: AppColors.cardBackground,
                          elevation: 2,
                          shadowColor: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            s.imageAsset,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 64,
                                color: AppColors.primaryLight.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        s.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        s.body,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
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
                        ? AppColors.primary
                        : AppColors.primaryLight.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(last ? 'Get started' : 'Next'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
