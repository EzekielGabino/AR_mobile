import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:scilense_ar_mobile/components/auth_gate.dart';
import 'package:scilense_ar_mobile/services/classroom_service.dart';
import 'package:scilense_ar_mobile/screens/people%20screens/pending_approval_screen.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

// Design-system palette (file-private so it cannot clash with AppColors in app_theme.dart)
const Color _royalBlue = Color(0xFF1B2CC1);
const Color _periwinkle = Color(0xFF7692FF);
const Color _lightBlue = Color(0xFFABD2FA);

class JoinClassroomScreen extends StatefulWidget {
  const JoinClassroomScreen({super.key});

  @override
  State<JoinClassroomScreen> createState() => _JoinClassroomScreenState();
}

class _JoinClassroomScreenState extends State<JoinClassroomScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  final TextEditingController _codeController = TextEditingController();
  bool _isScanning = true;
  bool _joining = false;

  @override
  void dispose() {
    cameraController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // AppBar kept exactly as the ORIGINAL (uses the app theme's AppBar style)
      appBar: AppBar(title: const Text('Join classroom')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              // Visual only: glow + border frame around the camera view
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _periwinkle.withValues(alpha: 0.8),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _periwinkle.withValues(alpha: 0.30),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: cameraController,
                        onDetect: _foundCode,
                      ),
                      // Decorative viewfinder (ignores touches, camera stays visible)
                      IgnorePointer(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _lightBlue.withValues(alpha: 0.85),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Small semi-transparent navy chip with a scan icon
                      Positioned(
                        top: 16,
                        right: 16,
                        child: IgnorePointer(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark
                                  .withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _periwinkle.withValues(alpha: 0.7),
                              ),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 24,
                              color: _lightBlue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Or enter the class code',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              // Monospace for the class code
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. ABC123',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.85),
                ),
                prefixIcon: const Icon(
                  Icons.vpn_key_rounded,
                  color: _periwinkle,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _lightBlue.withValues(alpha: 0.9),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _lightBlue.withValues(alpha: 0.9),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _royalBlue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              // Gradient shows only while the button is enabled
              child: Container(
                decoration: _joining
                    ? null
                    : BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [_royalBlue, _periwinkle],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _royalBlue.withValues(alpha: 0.30),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                child: ElevatedButton(
                  onPressed: _joining
                      ? null
                      : () => _join(_codeController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: _lightBlue.withValues(alpha: 0.5),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: AppColors.textSecondary,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(_joining ? 'Joining…' : 'Join with code'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _foundCode(BarcodeCapture capture) async {
    if (!_isScanning || _joining) return;

    String? code;
    for (final barcode in capture.barcodes) {
      code = barcode.rawValue;
      if (code != null && code.isNotEmpty) break;
    }
    if (code == null || code.isEmpty) return;

    _isScanning = false;
    await cameraController.stop();
    final normalized = ClassroomService.normalizeAccessCode(code);
    await _join(normalized.isEmpty ? code : normalized);
  }

  Future<void> _join(String code) async {
    if (_joining) return;
    setState(() => _joining = true);

    try {
      final info = await ClassroomService().joinByAccessCode(code);

      if (!mounted) return;
      if (info.isApproved) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (_) => false,
        );
        return;
      }
      // Pending: Profile → Join → Waiting (back returns toward profile)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PendingApprovalScreen(
            classId: info.id,
            sectionName: info.sectionName,
            accessCode: info.accessCode,
          ),
        ),
      );
    } on ClassroomJoinException catch (ex) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ex.message)),
      );
      _isScanning = true;
      try {
        await cameraController.start();
      } catch (_) {}
    } catch (ex) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joining failed: $ex')),
      );
      _isScanning = true;
      try {
        await cameraController.start();
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }
}