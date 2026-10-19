import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';

class UnityLabScreen extends StatefulWidget {
  final Map<String, dynamic>? activityJson;

  const UnityLabScreen({super.key, this.activityJson});

  @override
  State<UnityLabScreen> createState() => _UnityLabScreenState();
}

class _UnityLabScreenState extends State<UnityLabScreen> {
  bool _sent = false;

  /// Match your Unity debug / Firebase shape (RemoteLabActivityData).
  static final Map<String, dynamic> _debugActivity = {
    "id": "debug-1",
    "title": "Debug Concentration",
    "labCategory": "Concentration",
    "apparatus": [
      {"key": "beaker", "maxVol": 250, "displayName": "Beaker"},
      {"key": "stirring_rod", "maxVol": 0, "displayName": "Stirring Rod"},
    ],
    "elements": [
      {
        "substanceName": "Water",
        "formula": "H2O",
        "type": "liquid",
        "minVol": 10,
        "maxVol": 100,
        "volume": 50,
        "molarity": 0,
        "temperature": 25,
        "role": "Neutral",
        "colorHex": "#80B0E0FF",
      },
      {
        "substanceName": "Salt",
        "formula": "NaCl",
        "type": "granule",
        "minVol": 1,
        "maxVol": 50,
        "volume": 10,
        "molarity": 0,
        "temperature": 25,
        "role": "Salt",
        "colorHex": "#FFFFFFFF",
      },
    ],
    "steps": [
      {
        "instruction": "Place Beaker in the Table",
        "action": "PlaceApparatus",
        "elementFormula": "",
        "targetApparatusName": "Beaker",
      },
      {
        "instruction": "Add 50 mL water to Beaker",
        "action": "AddElement",
        "elementFormula": "H2O",
        "targetApparatusName": "Beaker",
        "targetVolume": 50,
        "waitSeconds": 0,
      },
    ],
  };

  void _sendActivity({bool force = false}) {
    if (_sent && !force) return;

    final data = widget.activityJson ?? _debugActivity;
    final json = jsonEncode(data);

    sendToUnity("FlutterLabBridge", "SendLabActivityJson", json);

    setState(() => _sent = true);
    debugPrint(
      "sendToUnity FlutterLabBridge.SendLabActivityJson (${json.length} chars)",
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Unity must be the base — receives almost all touches
          EmbedUnity(
            onMessageFromUnity: (message) {
              debugPrint("Unity → Flutter: $message");
              if (message == "scene_loaded") {
                _sendActivity(force: true);
              }
              if (message.contains("experimentComplete")) {
                Navigator.of(context).pop(true);
              }
            },
          ),

          // ONLY a small button — top-right, away from Beaker panel X
          Positioned(
            top: top + 8,
            right: 8,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: "Leave lab",
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),

          // Optional debug — also small, not full width
          // if (kDebugMode)
          //   Positioned(
          //     top: top + 8,
          //     right: 56,
          //     child: Material(
          //       color: Colors.black54,
          //       shape: const CircleBorder(),
          //       child: IconButton(
          //         icon: const Icon(Icons.send, color: Colors.white),
          //         onPressed: () => _sendActivity(force: true),
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }
}
