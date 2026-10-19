import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:scilense_ar_mobile/components/auth_gate.dart';
import 'package:scilense_ar_mobile/services/classroom_service.dart';

class JoinClassroomScreen extends StatefulWidget {
  const JoinClassroomScreen({super.key});

  @override
  State<JoinClassroomScreen> createState() => _JoinClassroomScreenState();
}

class _JoinClassroomScreenState extends State<JoinClassroomScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scan Class Code")),
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: SizedBox(height: 15)),
            Expanded(
              flex: 3,
              child: MobileScanner(
                controller: cameraController,
                onDetect: _foundCode,
              ),
            ),
            Expanded(child: SizedBox(height: 15)),
          ],
        ),
      ),
    );
  }

  Future<void> _foundCode(BarcodeCapture capture) async {
    if (!_isScanning) return;

    String? code = '';

    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      code = barcode.rawValue;
    }

    _isScanning = false;
    await cameraController.stop();
    Center(child: CircularProgressIndicator());

    try {
      await ClassroomService().joinByAccessCode(code!);

      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => AuthGate()),
        (value) => false,
      );
    } on FirebaseException catch (ex) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Joining Class Failed(Firebase): ${ex}")),
      );
      _isScanning = true;
    } catch (ex) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Joining Class Failed(normal): ${ex}")),
      );
      _isScanning = true;
    }
  }
}
