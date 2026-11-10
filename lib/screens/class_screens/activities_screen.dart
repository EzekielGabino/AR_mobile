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

// Design-system palette (file-private so it cannot clash with AppColors in app_theme.dart)
const Color _royalBlue = Color(0xFF1B2CC1);
const Color _periwinkle = Color(0xFF7692FF);
const Color _lightBlue = Color(0xFFABD2FA);
const Color _success = Color(0xFF2E9E5B);

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
        // Visual only: white strip with a thin light-blue divider under the tabs
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: _lightBlue.withValues(alpha: 0.7)),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: _royalBlue,
            unselectedLabelColor: AppColors.primaryGray,
            indicatorColor: _royalBlue,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            dividerColor: Colors.transparent,
            dividerHeight: 0,
            tabs: const [
              Tab(text: 'To Do'),
              Tab(text: 'Submitted'),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: _royalBlue),
                )
              : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: AppColors.safetyRed,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: $_error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
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
                          color: _royalBlue,
                          onRefresh: _load,
                          child: _ActivityList(
                            items: todo,
                            emptyText: 'Nothing to do — you\'re all caught up!',
                            onTap: (data) => _openActivity(context, data),
                          ),
                        ),
                        RefreshIndicator(
                          color: _royalBlue,
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
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon inside a soft light-blue circle (decorative)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _lightBlue.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      submissionsById == null
                          ? Icons.check_circle_outline_rounded
                          : Icons.inbox_outlined,
                      size: 40,
                      color: _periwinkle,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emptyText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: items.length,
      itemBuilder: (_, index) {
        final data = items[index];
        final type = (data['type'] as String? ?? 'activity');
        // Visual only (read-only): used to pick the icon/color of the date line
        final bool isSubmitted =
            submissionsById?[data['id'] as String?] != null;
        final bool isPastDue =
            !isSubmitted && _isPastDue(data['dueDate'], data['dueTime']);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            // Visual only: white card, periwinkle glow, light-blue border, 16 px radius
            margin: EdgeInsets.zero,
            color: Colors.white,
            elevation: 4,
            shadowColor: _periwinkle.withValues(alpha: 0.30),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: _lightBlue.withValues(alpha: 0.7)),
            ),
            child: InkWell(
              onTap: () => onTap(data),
              splashColor: _periwinkle.withValues(alpha: 0.18),
              highlightColor: _lightBlue.withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(type),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: _lightBlue.withValues(alpha: 0.35),
                          side: BorderSide(
                            color: _periwinkle.withValues(alpha: 0.6),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          avatar: Icon(
                            type.toLowerCase() == 'lab'
                                ? Icons.science_rounded
                                : Icons.assignment_rounded,
                            size: 16,
                            color: _royalBlue,
                          ),
                          labelStyle: const TextStyle(
                            color: _royalBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isPastDue) ...[
                          const SizedBox(width: 6),
                          Chip(
                            label: const Text('Past due'),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: const Color(0xFFFFEBEE),
                            side: const BorderSide(color: Color(0xFFEF9A9A)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            avatar: const Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: Color(0xFFC62828),
                            ),
                            labelStyle: const TextStyle(
                              color: Color(0xFFC62828),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          isSubmitted
                              ? Icons.check_circle_rounded
                              : Icons.event_note_rounded,
                          size: 16,
                          color: isSubmitted ? _success : _periwinkle,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            () {
                              final sub =
                                  submissionsById?[data['id'] as String?];
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isPastDue
                              ? Icons.event_busy_rounded
                              : Icons.schedule_rounded,
                          size: 16,
                          color: isPastDue
                              ? const Color(0xFFC62828)
                              : _periwinkle,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isPastDue
                                ? 'Past due: ${_formatDeadline(data['dueDate'], data['dueTime'])}'
                                : 'Deadline: ${_formatDeadline(data['dueDate'], data['dueTime'])}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isPastDue ? FontWeight.w700 : FontWeight.w400,
                              color: isPastDue
                                  ? const Color(0xFFC62828)
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Gradient arrow button (decorative; the whole card is the tap target)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_royalBlue, _periwinkle],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
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

bool _isPastDue(dynamic dueDate, dynamic dueTime) {
  if (dueDate == null || dueDate.toString().isEmpty) return false;
  try {
    final raw = dueDate.toString().trim();
    final d = raw.length >= 10 ? raw.substring(0, 10) : raw;
    var t = (dueTime?.toString() ?? '').trim();
    if (t.isEmpty) {
      t = '23:59:59';
    } else if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(t)) {
      t = '$t:00';
    } else if (t.length >= 8) {
      t = t.substring(0, 8);
    }
    final when = DateTime.parse('${d}T$t');
    return when.isBefore(DateTime.now());
  } catch (_) {
    return false;
  }
}
