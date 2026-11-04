import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scilense_ar_mobile/models/experiment_models.dart';
import 'package:scilense_ar_mobile/screens/class_screens/experiment_quiz_screen.dart';
import 'package:scilense_ar_mobile/services/activity_submission_service.dart';
import 'package:scilense_ar_mobile/services/auth_service.dart';

class RegularActivityScreen extends StatefulWidget {
  final String classId;
  final String activityId;
  final Map<String, dynamic> data;

  const RegularActivityScreen({
    super.key,
    required this.classId,
    required this.activityId,
    required this.data,
  });

  @override
  State<RegularActivityScreen> createState() => _RegularActivityScreenState();
}

class _RegularActivityScreenState extends State<RegularActivityScreen> {
  final ActivitySubmissionService _submissionService =
      ActivitySubmissionService();

  final user = AuthService().currentUser;

  bool _completing = false;
  bool _loadingSubmission = true;
  bool _hasSubmitted = false;
  bool _quizCompleted = false;

  Map<int, String> _quizAnswers = {};

  ExperimentQuiz? get _quiz {
    final raw = widget.data['quiz'];

    if (raw == null) return null;

    try {
      return ExperimentQuiz.fromJson(Map<String, dynamic>.from(raw as Map));
    } catch (_) {
      return null;
    }
  }

  bool get _hasQuiz {
    return _quiz != null && _quiz!.questions.isNotEmpty;
  }

  bool get _canSubmit {
    if (_hasSubmitted) return false;

    if (!_hasQuiz) {
      return true;
    }

    return _quizCompleted;
  }

  @override
  void initState() {
    super.initState();
    _loadSubmission();
  }

  Future<void> _loadSubmission() async {
    if (user == null) {
      if (mounted) {
        setState(() => _loadingSubmission = false);
      }
      return;
    }

    try {
      final submission = await _submissionService.getStudentSubmission(
        activityId: widget.activityId,
        studentId: user!.id,
      );

      if (!mounted) return;

      setState(() {
        _hasSubmitted = submission != null;
        _loadingSubmission = false;

        if (submission != null) {
          _quizCompleted = true;

          final rawAnswers = submission['answers'];

          if (rawAnswers is List) {
            _quizAnswers = {
              for (final answer in rawAnswers)
                if (answer is Map &&
                    answer['order'] is int &&
                    answer['answer'] is String)
                  answer['order'] as int: answer['answer'] as String,
            };
          }
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loadingSubmission = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load submission status: $e')),
      );
    }
  }

  Future<void> _submitActivity() async {
    if (!_canSubmit || _completing) return;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in to submit this activity.'),
        ),
      );
      return;
    }

    setState(() => _completing = true);

    try {
      final answers = _quizAnswers.entries
          .map((entry) => {'order': entry.key, 'answer': entry.value})
          .toList();

      await _submissionService.markSubmitted(
        classId: widget.classId,
        activityId: widget.activityId,
        studentId: user!.id,
        activityType: 'regular',
        answers: answers,
      );

      if (!mounted) return;

      setState(() {
        _hasSubmitted = true;
        _completing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity submitted successfully!')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() => _completing = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to submit activity: $e')));
    }
  }

  Future<void> _openQuiz() async {
    final quiz = _quiz;

    if (quiz == null || quiz.questions.isEmpty) return;
    if (_hasSubmitted) return;

    final wrapped = Experiment(
      id: widget.activityId,
      title: widget.data['title'] as String? ?? 'Activity',
      materials: const [],
      safetyPrecautions: const [],
      steps: const [],
      quiz: quiz,
    );

    final answers = await Navigator.of(context).push<Map<int, String>>(
      MaterialPageRoute(
        builder: (_) => ExperimentQuizScreen(
          experiment: wrapped,
          classId: widget.classId,
          activityId: widget.activityId,
        ),
      ),
    );

    if (!mounted) return;

    if (answers != null) {
      setState(() {
        _quizAnswers = answers;
        _quizCompleted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = _quiz;

    if (_loadingSubmission) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final dateValue = widget.data['due_date'] ?? widget.data['published_at'];

    final timeValue = widget.data['due_time'] ?? widget.data['published_at'];

    String date = dateValue != null && dateValue.toString().isNotEmpty
        ? DateFormat('MMM dd, yyyy')
              .format(DateTime.parse(dateValue.toString()))
        : '';

    String time = timeValue != null && timeValue.toString().isNotEmpty
        ? DateFormat('h:mm a').format(DateTime.parse(timeValue.toString()))
        : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.data['title'] as String? ?? 'Activity'),
      ),

      // ------------------------------------------------------------
      // SCROLLABLE CONTENT
      // ------------------------------------------------------------
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.data['max_score'] ?? 'No Score',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),

                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      date as String? ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      time as String? ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            Material(
              color: AppColors.cardBackground,
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notes_outlined, size: 20, color: AppColors.accent),
                        SizedBox(width: 8),
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      (widget.data['description'] as String?)?.trim().isNotEmpty == true
                          ? widget.data['description'] as String
                          : 'No description provided.',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------------
            // ATTACHMENTS
            // --------------------------------------------------------
            Builder(
              builder: (context) {
                final raw = widget.data['attachments'];
                final files = <Map<String, dynamic>>[];
                if (raw is List) {
                  for (final item in raw) {
                    if (item is Map) {
                      files.add(Map<String, dynamic>.from(item));
                    }
                  }
                }
                if (files.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attachments',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...files.map((f) {
                      final name = f['name'] as String? ?? 'Attachment';
                      final url =
                          f['url'] as String? ??
                          f['downloadURL'] as String? ??
                          '';
                      return Material(
                        color: AppColors.cardBackground,
                        elevation: 1,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          leading: const Icon(Icons.attach_file, color: AppColors.accent),
                          title: Text(
                            name,
                            style: TextStyle(
                              color: url.isNotEmpty
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                              fontWeight: FontWeight.w600,
                              decoration: url.isNotEmpty
                                  ? TextDecoration.underline
                                  : null,
                            ),
                          ),
                          trailing: url.isNotEmpty
                              ? const Icon(Icons.open_in_new, size: 18)
                              : null,
                          onTap: url.isEmpty
                              ? null
                              : () async {
                                  final uri = Uri.tryParse(url);
                                  if (uri == null) return;
                                  final ok = await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                  if (!ok && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Could not open file.'),
                                      ),
                                    );
                                  }
                                },
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            // --------------------------------------------------------
            // QUIZ CARD
            // --------------------------------------------------------
            if (quiz != null && quiz.questions.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _quizCompleted ? Icons.check_circle : Icons.quiz,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              _quizCompleted ? 'Quiz Completed' : 'Quiz',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _quizCompleted
                            ? 'You have completed the quiz.'
                            : 'Test your understanding of this activity.',
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _hasSubmitted ? null : _openQuiz,
                          icon: Icon(
                            _quizCompleted ? Icons.refresh : Icons.quiz,
                          ),
                          label: Text(
                            _quizCompleted ? 'Review Quiz' : 'Take Quiz',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This activity does not have a quiz.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Space so the fixed bottom button does not cover
            // the last part of the content.
            const SizedBox(height: 100),
          ],
        ),
      ),

      // ------------------------------------------------------------
      // FIXED SUBMIT BUTTON
      // ------------------------------------------------------------
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _canSubmit && !_completing ? _submitActivity : null,
              child: _completing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _hasSubmitted ? 'Activity Submitted' : 'Submit Activity',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
