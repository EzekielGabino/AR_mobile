import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:lottie/lottie.dart';
import 'package:scilense_ar_mobile/screens/sample%20lab%20act%20screens/lab_onboarding_screen.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

class UnityLabScreen extends StatefulWidget {
  final Map<String, dynamic>? activityJson;

  const UnityLabScreen({super.key, this.activityJson});

  @override
  State<UnityLabScreen> createState() => _UnityLabScreenState();
}

class _UnityLabScreenState extends State<UnityLabScreen> {
  bool _sent = false;
  bool _leaving = false;
  bool _showDistanceGuide = false;

  void _sendActivity({bool force = false}) {
    if (_sent && !force) return;

    final data = widget.activityJson;
    if (data == null) {
      debugPrint('No lab activity provided to UnityLabScreen.');
      return;
    }

    final json = jsonEncode(data);
    sendToUnity('FlutterLabBridge', 'SendLabActivityJson', json);
    _sent = true;

    debugPrint(
      'sendToUnity FlutterLabBridge.SendLabActivityJson '
      '(${json.length} chars)',
    );
  }

  void _resetLab() {
    // Hide placement Lottie if reset mid-placement
    if (_showDistanceGuide) {
      setState(() => _showDistanceGuide = false);
    }
    try {
      sendToUnity('FlutterLabBridge', 'ResetLab', '');
    } catch (_) {}
    _sent = false;
    _sendActivity(force: true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lab reset to the first step.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _leaveLab({bool completed = false}) async {
    if (_leaving) return;
    _leaving = true;
    // Always drop the loaded activity so the next lab must re-send JSON
    // (prevents practice lab A sticking when opening practice lab B).
    try {
      sendToUnity('FlutterLabBridge', 'ClearLabActivity', '');
    } catch (_) {}
    _sent = false;
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(completed);
    }
  }

  void _openInfo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const LabOnboardingScreen(asGuide: true),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Unity often stays alive after pop — scene_loaded will NOT fire again.
      // Always push this screen's activity after a short delay so lab B replaces lab A.
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        try {
          sendToUnity('FlutterLabBridge', 'SetPracticeMode', 'true');
        } catch (_) {}
        _sendActivity(force: true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _leaveLab(completed: false);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            EmbedUnity(
              onMessageFromUnity: (message) {
                debugPrint('Unity → Flutter: $message');
                final msg = message.trim();
                final lower = msg.toLowerCase();

                if (msg == 'PlacementStarted') {
                  setState(() => _showDistanceGuide = true);
                } else if (msg == 'PlacementEnded') {
                  setState(() => _showDistanceGuide = false);
                }

                if (lower == 'scene_loaded') {
                  sendToUnity('FlutterLabBridge', 'SetPracticeMode', 'true');
                  _sendActivity(force: true);
                }
                if (lower.contains('experiment complete') ||
                    lower.contains('experiment_complete')) {
                  _leaveLab(completed: true);
                }
              },
            ),

            // Distance guidance while placing an apparatus
            if (_showDistanceGuide) const _DistanceGuideOverlay(),

            Positioned(
              top: top + 8,
              left: 8,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Leave lab',
                  onPressed: () => _leaveLab(completed: false),
                ),
              ),
            ),

            Positioned(
              top: top + 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.restart_alt, color: Colors.white),
                  tooltip: 'Reset lab',
                  onPressed: _resetLab,
                ),
              ),
            ),

            Positioned(
              top: top + 8,
              right: 60,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: _openInfo,
                  icon: const Icon(Icons.info),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Distance / surface guide shown while placing an apparatus.
class _DistanceGuideOverlay extends StatelessWidget {
  const _DistanceGuideOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.5),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 36, vertical: 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24.withValues(alpha: 0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/animations/surface_scanning.json',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                repeat: true,
              ),
              const SizedBox(height: 8),
              const Text(
                'Hold phone about 6-12 inches above the table',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Keep it steady until the indicator appears, then tap the screen to place',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
