import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:scilense_ar_mobile/models/experiment_models.dart';
import 'package:scilense_ar_mobile/screens/main_screen.dart';
import 'package:scilense_ar_mobile/screens/people%20screens/profile_screen.dart';
import 'package:scilense_ar_mobile/screens/sample lab act screens/sample_labAct_screen.dart';
import 'package:scilense_ar_mobile/components/class_screens/experiment_quiz_screen.dart';
import 'package:scilense_ar_mobile/services/auth_service.dart';

class SampleExperiments extends StatelessWidget {
  SampleExperiments({super.key});
  final FirebaseAuth auth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sample Experiments"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('experiments')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load experiments: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No experiments yet.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              Experiment experiment;
              try {
                experiment = Experiment.fromJson(doc.id, doc.data());
              } catch (e) {
                // Skip a malformed document rather than crashing the
                // whole list — worth logging which doc.id failed.
                debugPrint('Skipping malformed experiment ${doc.id}: $e');
                return const SizedBox.shrink();
              }

              return Card(
                child: ListTile(
                  title: Text(experiment.title),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            SampleLabactScreen(experiment: experiment),
                        // ExperimentQuizScreen(experiment: experiment), // for quiz debug
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
