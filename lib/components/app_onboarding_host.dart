import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/screens/app_onboarding_screen.dart';
import 'package:scilense_ar_mobile/services/app_onboarding_store.dart';

/// Shows [AppOnboardingScreen] once on first app open.
class AppOnboardingHost extends StatefulWidget {
  const AppOnboardingHost({super.key, required this.child});

  final Widget child;

  @override
  State<AppOnboardingHost> createState() => _AppOnboardingHostState();
}

class _AppOnboardingHostState extends State<AppOnboardingHost> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  Future<void> _maybeShow() async {
    if (_checked || !mounted) return;
    _checked = true;
    final show = await AppOnboardingStore.shouldShow();
    if (!show || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const AppOnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
