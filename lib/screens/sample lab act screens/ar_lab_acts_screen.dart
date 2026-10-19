import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/models/lab_activity_remote.dart';
import 'package:scilense_ar_mobile/services/lab_activity_service.dart';
import 'package:scilense_ar_mobile/screens/sample%20lab%20act%20screens/lab_act_detail_screen.dart';

/// Lists all documents in Firestore [labActivities].
class ArLabActsScreen extends StatelessWidget {
  const ArLabActsScreen({super.key, LabActivityService? service})
      : _service = service;

  final LabActivityService? _service;

  LabActivityService get service => _service ?? LabActivityService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Lab Activities'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<LabActivityRemote>>(
        stream: service.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load activities.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(
              child: Text('No lab activities yet.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final activity = list[index];
              return Card(
                child: ListTile(
                  title: Text(
                    activity.title.isEmpty ? activity.id : activity.title,
                  ),
                  subtitle: Text(
                    activity.labCategory.isEmpty
                        ? activity.description
                        : activity.labCategory,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LabActDetailScreen(
                          activityId: activity.id,
                          initialActivity: activity,
                        ),
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
