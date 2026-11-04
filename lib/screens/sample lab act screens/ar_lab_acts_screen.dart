import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/models/lab_activity_remote.dart';
import 'package:scilense_ar_mobile/services/lab_activity_service.dart';
import 'package:scilense_ar_mobile/screens/sample%20lab%20act%20screens/lab_act_detail_screen.dart';

/// Lists practice labs from Supabase [practice_lab_activities].
class ArLabActsScreen extends StatefulWidget {
  const ArLabActsScreen({super.key, LabActivityService? service})
      : _service = service;

  final LabActivityService? _service;

  @override
  State<ArLabActsScreen> createState() => _ArLabActsScreenState();
}

class _ArLabActsScreenState extends State<ArLabActsScreen> {
  LabActivityService get service => widget._service ?? LabActivityService();

  late Future<List<LabActivityRemote>> _future;

  @override
  void initState() {
    super.initState();
    _future = service.fetchAll();
  }

  Future<void> _reload() async {
    setState(() {
      _future = service.fetchAll();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice AR Lab Activities'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<LabActivityRemote>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Failed to load activities.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Retry'),
                    ),
                  ],
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
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No lab activities yet.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
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
            ),
          );
        },
      ),
    );
  }
}
