import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/screens/chemistry_screens/lab_safety_screen.dart';
import 'package:scilense_ar_mobile/screens/chemistry_screens/object_detection_screen.dart';
import 'package:scilense_ar_mobile/screens/chemistry_screens/equipment_details/equipment_gallery_screen.dart';
import 'package:scilense_ar_mobile/screens/chemistry_screens/periodic_table/periodic_table_screen.dart';
import 'package:scilense_ar_mobile/screens/people%20screens/profile_screen.dart';
import 'package:scilense_ar_mobile/screens/sample%20lab%20act%20screens/ar_lab_acts_screen.dart';

class ChemistryHubScreen extends StatefulWidget {
  const ChemistryHubScreen({super.key});

  @override
  State<ChemistryHubScreen> createState() => _ChemistryHubScreenState();
}

class _ChemistryHubScreenState extends State<ChemistryHubScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  Map<String, WidgetBuilder> get hubs {
    final isSignedIn = auth.currentUser != null;
    return {
      if (isSignedIn) "Practice AR Lab Activities": (_) => ArLabActsScreen(),
      "Object Detection": (_) => const ObjectDetectionScreen(),
      "Laboratory Equipment Info": (_) => const EquipmentGalleryScreen(),
      "Laboratory Safety Hazards": (_) => LabSafetyScreen(),
      "Periodic Table": (_) => PeriodicTableScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final hubNames = hubs.keys.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chemistry Hub"),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          if (auth.currentUser == null || auth.currentUser != null)
            IconButton(
              onPressed: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => ProfileScreen())),
              icon: const Icon(Icons.person),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ),
          itemCount: hubNames.length,
          itemBuilder: (_, index) {
            final name = hubNames[index];
            return GestureDetector(
              onTap: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: hubs[name]!)),
              child: Card(
                child: Center(child: Text(name, textAlign: TextAlign.center)),
              ),
            );
          },
        ),
      ),
    );
  }
}
