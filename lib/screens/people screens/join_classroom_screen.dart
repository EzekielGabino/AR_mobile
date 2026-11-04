import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:scilense_ar_mobile/components/auth_gate.dart';
import 'package:scilense_ar_mobile/services/classroom_service.dart';
import 'package:scilense_ar_mobile/screens/people%20screens/pending_approval_screen.dart';

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
      appBar: AppBar(title: const Text('Join classroom')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MobileScanner(
                  controller: cameraController,
                  onDetect: _foundCode,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Or enter the class code',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'e.g. ABC123',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _joining
                    ? null
                    : () => _join(_codeController.text),
                child: Text(_joining ? 'Joining…' : 'Join with code'),
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
    await _join(code);
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
