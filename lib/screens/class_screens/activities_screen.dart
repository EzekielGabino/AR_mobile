import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scilense_ar_mobile/models/experiment_models.dart';
import 'package:scilense_ar_mobile/screens/class_screens/class_lab_activity_screen.dart';
import 'package:scilense_ar_mobile/screens/class_screens/regular_activities_screen.dart';
import 'package:scilense_ar_mobile/services/activity_submission_service.dart';
import 'package:scilense_ar_mobile/services/auth_service.dart';
import 'package:scilense_ar_mobile/services/supabase_service.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

/// Class activities from Supabase `class_activities` (published only for students).
class ActivitiesSection extends StatefulWidget {
  final String classId;
  const ActivitiesSection({super.key, required this.classId});

  @override
  State<ActivitiesSection> createState() => _ActivitiesSectionState();
}

class _ActivitiesSectionState extends State<ActivitiesSection>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Map<String, dynamic>> _activities = [];
  Map<String, Map<String, dynamic>> _submitted = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Map Postgres row → shape expected by open-activity screens.
  Map<String, dynamic> _mapActivity(Map<String, dynamic> row) {
    final quiz = _decodeJsonValue(row['quiz']);
    final labExp = _decodeJsonValue(row['lab_experiment']);

    return {
      'id': row['id'],
      'type': row['type'] ?? 'regular',
      'title': row['title'] ?? 'Untitled',
      'description': row['description'] ?? '',
      'published': row['published'] == true,
      'status': row['status'],
      'dueDate': row['due_date'],
      'dueTime': row['due_time'],
      'published_at': row['published_at'],
      'maxScore': row['max_score'] ?? 0,
      'quiz': quiz,
      'labCategory': row['lab_category'],
      'safetyTips': row['safety_tips'],
      'apparatus': _decodeJsonValue(row['apparatus']) ?? [],
      'elements': _decodeJsonValue(row['elements']) ?? [],
      'steps': _decodeJsonValue(row['steps']) ?? [],
      'labExperiment': labExp is Map
          ? Map<String, dynamic>.from(labExp)
          : labExp,
      'attachments': _decodeJsonValue(row['attachments']) ?? [],
    };
  }

  dynamic _decodeJsonValue(dynamic value) {
    if (value is String) {
      try {
        return jsonDecode(value);
      } catch (_) {
        return value;
      }
    }

    return value;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uid = AuthService().uid;
      if (uid == null) {
        throw Exception('Not signed in.');
      }

      final rows = await SupabaseService.client
          .from('class_activities')
          .select()
          .eq('class_id', widget.classId)
          .eq('published', true)
          .order('created_at', ascending: false);

      final activities = (rows as List)
          .map((e) => _mapActivity(Map<String, dynamic>.from(e as Map)))
          .toList();

      final subs = await ActivitySubmissionService().fetchMySubmissions(
        classId: widget.classId,
        studentId: uid,
      );

      if (!mounted) return;
      setState(() {
        _activities = activities;
        _submitted = subs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _openActivity(BuildContext context, Map<String, dynamic> data) {
    final activityId = data['id'] as String? ?? '';
    final type = (data['type'] as String? ?? '').toLowerCase();

    if (type == 'lab') {
      final rawLabExperiment = data['labExperiment'];

      if (rawLabExperiment is! Map) {
        debugPrint(
          'Invalid labExperiment type: ${rawLabExperiment.runtimeType}',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lab activity data has an invalid format.'),
          ),
        );
        return;
      }

      final labExperiment = Map<String, dynamic>.from(rawLabExperiment);

      final merged = <String, dynamic>{
        'title': data['title'],
        'description': data['description'] ?? '',
        'maxScore': data['maxScore'] ?? 0,
        'materials': labExperiment['materials'] ?? [],
        'safetyPrecautions': labExperiment['safetyPrecautions'] ?? [],
        'steps': labExperiment['steps'] ?? data['steps'] ?? [],
        'quiz': {
          'questions': (data['quiz'] as List? ?? [])
              .whereType<Map>()
              .map(
                (q) => {
                  'order': q['order'] ?? 0,
                  'prompt': q['prompt'] ?? '',
                  'options': q['options'] ?? [],
                  'correctOption':
                      q['correctOption'] ?? q['correctOptionId'] ?? '',
                  'explanation': q['explanation'],
                },
              )
              .toList(),
        },
      };

      Experiment experiment;
      try {
        experiment = Experiment.fromJson(activityId, merged);
      } catch (e) {
        debugPrint("$e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('This lab activity is missing required steps: $e'),
          ),
        );
        return;
      }

      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) => ClassLabActivityScreen(
                experiment: experiment,
                classId: widget.classId,
                activityId: activityId,
                dueDate: data['dueDate']?.toString(),
                dueTime: data['dueTime']?.toString(),
                maxScore: data['maxScore'] is int
                    ? data['maxScore'] as int
                    : int.tryParse('${data['maxScore'] ?? ''}'),
                labCategory: data['labCategory']?.toString(),
                safetyTips: data['safetyTips']?.toString(),
                apparatus: data['apparatus'] is List
                    ? List<dynamic>.from(data['apparatus'] as List)
                    : const [],
                elements: data['elements'] is List
                    ? List<dynamic>.from(data['elements'] as List)
                    : const [],
                rawSteps: data['steps'] is List
                    ? List<dynamic>.from(data['steps'] as List)
                    : const [],
              ),
            ),
          )
          .then((_) {
            if (mounted) _load();
          });
    } else {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) => RegularActivityScreen(
                classId: widget.classId,
                activityId: activityId,
                data: data,
              ),
            ),
          )
          .then((_) {
            if (mounted) _load();
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: AppColors.primaryGray,
          dividerColor: Colors.transparent,
          dividerHeight: 0,
          tabs: const [
            Tab(text: 'To Do'),
            Tab(text: 'Submitted'),
          ],
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error: $_error', textAlign: TextAlign.center),
                  ),
                )
              : Builder(
                  builder: (context) {
                    final todo = _activities
                        .where((a) => !_submitted.containsKey(a['id']))
                        .toList();
                    final done = _activities
                        .where((a) => _submitted.containsKey(a['id']))
                        .toList();

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        RefreshIndicator(
                          onRefresh: _load,
                          child: _ActivityList(
                            items: todo,
                            emptyText: 'Nothing to do — you\'re all caught up!',
                            onTap: (data) => _openActivity(context, data),
                          ),
                        ),
                        RefreshIndicator(
                          onRefresh: _load,
                          child: _ActivityList(
                            items: done,
                            emptyText: 'No submitted activities yet.',
                            submissionsById: _submitted,
                            onTap: (data) => _openActivity(context, data),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ActivityList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String emptyText;
  final void Function(Map<String, dynamic> data) onTap;

  /// When set (Submitted tab), show submitted date instead of published date.
  final Map<String, Map<String, dynamic>>? submissionsById;

  const _ActivityList({
    required this.items,
    required this.emptyText,
    required this.onTap,
    this.submissionsById,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Center(child: Text(emptyText)),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (_, index) {
        final data = items[index];
        final type = (data['type'] as String? ?? 'activity');

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            child: InkWell(
              onTap: () => onTap(data),
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
                    const SizedBox(height: 8),
                    Text(
                      () {
                        final sub = submissionsById?[data['id'] as String?];
                        if (sub != null) {
                          final when =
                              sub['submitted_at'] ??
                              sub['submittedAt'] ??
                              sub['created_at'];
                          return 'Submitted: ${_formatDate(when)}';
                        }
                        return 'Published: ${_formatDate(data['published_at'] ?? data['created_at'])}';
                      }(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Deadline: ${_formatDeadline(data['dueDate'], data['dueTime'])}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: 0.65),
                      ),
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

String _formatDate(dynamic value) {
  if (value == null || value.toString().isEmpty) return '—';
  try {
    final d = DateTime.parse(value.toString());
    return DateFormat('MMM d, yyyy').format(d);
  } catch (_) {
    return value.toString();
  }
}

String _formatDeadline(dynamic dueDate, dynamic dueTime) {
  if (dueDate == null || dueDate.toString().isEmpty) return 'No deadline';
  final datePart = _formatDate(dueDate);
  final time = dueTime?.toString() ?? '';
  if (time.isEmpty) return datePart;
  return '$datePart · $time';
}
