import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/components/class_screens/class_lab_activity_screen.dart';
import 'package:scilense_ar_mobile/components/class_screens/regular_activities_screen.dart';
import 'package:scilense_ar_mobile/models/experiment_models.dart';
import 'package:scilense_ar_mobile/screens/sample%20lab%20act%20screens/sample_labAct_screen.dart';
import 'package:scilense_ar_mobile/services/activity_submission_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Two tabs: "To Do" and "Submitted", split using this student's
/// activitySubmissions records for the class. Tapping an activity routes
/// to a different screen depending on its 'type' field:
/// - 'lab' -> parsed as a full Experiment and pushed to SampleLabactScreen
///   (the AR guided flow), since the web lab-activity builder writes
///   classActivities docs in the same steps/quiz shape as `experiments`.
/// - anything else -> RegularActivityScreen, a lighter-weight screen for
///   read/quiz-only activities that don't have AR steps at all.
class ActivitiesSection extends StatefulWidget {
  final String classId;
  const ActivitiesSection({super.key, required this.classId});

  @override
  State<ActivitiesSection> createState() => _ActivitiesSectionState();
}

class _ActivitiesSectionState extends State<ActivitiesSection>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openActivity(
    BuildContext context,
    String activityId,
    Map<String, dynamic> data,
  ) {
    final type = (data['type'] as String? ?? '').toLowerCase();

    if (type == 'lab') {
      final labExperiment = data['labExperiment'] as Map<String, dynamic>?;
      if (labExperiment == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This lab activity has no steps configured yet.'),
          ),
        );
        return;
      }

      final merged = <String, dynamic>{
        'title': data['title'],
        'description': data['description'] ?? '',
        'maxScore': data['maxScore'] ?? 0,
        'materials': labExperiment['materials'] ?? [],
        'safetyPrecautions': labExperiment['safetyPrecautions'] ?? [],
        'steps': labExperiment['steps'] ?? [],
        'quiz': data['quiz'],
      };

      Experiment experiment;
      try {
        experiment = Experiment.fromJson(activityId, merged);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('This lab activity is missing required steps: $e'),
          ),
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ClassLabActivityScreen(
            experiment: experiment,
            classId: widget.classId,
            activityId: activityId,
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RegularActivityScreen(
            classId: widget.classId,
            activityId: activityId,
            data: data,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'To Do'),
            Tab(text: 'Submitted'),
          ],
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('classActivities')
                .where('classId', isEqualTo: widget.classId)
                .snapshots(),
            builder: (context, activitySnap) {
              if (activitySnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (activitySnap.hasError) {
                return Center(child: Text('Error: ${activitySnap.error}'));
              }

              final activityDocs = activitySnap.data?.docs ?? [];

              return StreamBuilder<
                Map<String, DocumentSnapshot<Map<String, dynamic>>>
              >(
                stream: ActivitySubmissionService().watchMySubmissions(
                  classId: widget.classId,
                  studentId: FirebaseAuth.instance.currentUser!.uid,
                ),
                builder: (context, subSnap) {
                  if (subSnap.hasError) {
                    // Was previously silently treated as {} (nothing submitted) —
                    // surfacing this so an index/rules/permission failure is visible
                    // instead of looking identical to "not submitted yet."
                    return Column(
                      children: [
                        Container(
                          width: double.infinity,
                          color: Colors.red.shade50,
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Could not load submission status: ${subSnap.error}',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _ActivityList(
                            docs: activityDocs,
                            emptyText: 'No activities yet.',
                            onTap: (id, data) =>
                                _openActivity(context, id, data),
                          ),
                        ),
                      ],
                    );
                  }

                  final submitted = subSnap.data ?? {};

                  final todo = activityDocs
                      .where((d) => !submitted.containsKey(d.id))
                      .toList();
                  final done = activityDocs
                      .where((d) => submitted.containsKey(d.id))
                      .toList();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _ActivityList(
                        docs: todo,
                        emptyText: 'Nothing to do — you\'re all caught up!',
                        onTap: (id, data) => _openActivity(context, id, data),
                      ),
                      _ActivityList(
                        docs: done,
                        emptyText: 'No submitted activities yet.',
                        onTap: (id, data) => _openActivity(context, id, data),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActivityList extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final String emptyText;
  final void Function(String id, Map<String, dynamic> data) onTap;

  const _ActivityList({
    required this.docs,
    required this.emptyText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) {
      return Center(child: Text(emptyText));
    }

    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (_, index) {
        final doc = docs[index];
        final data = doc.data();
        final type = (data['type'] as String? ?? 'activity');

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            child: InkWell(
              onTap: () => onTap(doc.id, data),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            data['title'] ?? 'Untitled',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(type),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['description'] ?? '',
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Align(
                      alignment: Alignment.bottomRight,
                      child: Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
