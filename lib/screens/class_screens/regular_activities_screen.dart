import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scilense_ar_mobile/models/experiment_models.dart';
import 'package:scilense_ar_mobile/screens/class_screens/experiment_quiz_screen.dart';
import 'package:scilense_ar_mobile/services/activity_submission_service.dart';
import 'package:scilense_ar_mobile/services/auth_service.dart';

// Design-system palette (file-private so it cannot clash with AppColors in app_theme.dart)
const Color _royalBlue = Color(0xFF1B2CC1);
const Color _periwinkle = Color(0xFF7692FF);
const Color _lightBlue = Color(0xFFABD2FA);
const Color _success = Color(0xFF2E9E5B);

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
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: _royalBlue),
        ),
      );
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
      backgroundColor: AppColors.background,
      // AppBar kept exactly as the ORIGINAL (uses the app theme's AppBar style)
      appBar: AppBar(
        title: Text(widget.data['title'] as String? ?? 'Activity'),
      ),

      // ------------------------------------------------------------
      // SCROLLABLE CONTENT
      // ------------------------------------------------------------
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visual only: score + date/time sit on a white card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _lightBlue.withValues(alpha: 0.7)),
                boxShadow: [
                  BoxShadow(
                    color: _periwinkle.withValues(alpha: 0.30),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.data['max_score'] ?? 'No Score',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: _royalBlue,
                    ),
                  ),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (date.isNotEmpty) ...[
                            const Icon(
                              Icons.event_rounded,
                              size: 16,
                              color: _periwinkle,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            date as String? ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (time.isNotEmpty) ...[
                            const Icon(
                              Icons.schedule_rounded,
                              size: 16,
                              color: _periwinkle,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            time as String? ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Material(
              color: AppColors.cardBackground,
              elevation: 4,
              shadowColor: _periwinkle.withValues(alpha: 0.30),
              // shape replaces borderRadius so a thin border can be added
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: _lightBlue.withValues(alpha: 0.7)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Gradient icon chip (decorative)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [_royalBlue, _periwinkle],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notes_outlined,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (widget.data['description'] as String?)?.trim().isNotEmpty == true
                          ? widget.data['description'] as String
                          : 'No description provided.',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        height: 1.5,
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
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...files.map((f) {
                      final name = f['name'] as String? ?? 'Attachment';
                      final url =
                          f['url'] as String? ??
                          f['downloadURL'] as String? ??
                          '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: AppColors.cardBackground,
                          elevation: 4,
                          shadowColor: _periwinkle.withValues(alpha: 0.30),
                          clipBehavior: Clip.antiAlias,
                          // shape replaces borderRadius so a thin border can be added
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: _lightBlue.withValues(alpha: 0.7),
                            ),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.attach_file,
                              color: _royalBlue,
                            ),
                            title: Text(
                              name,
                              style: TextStyle(
                                color: url.isNotEmpty
                                    ? _royalBlue
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                decoration: url.isNotEmpty
                                    ? TextDecoration.underline
                                    : null,
                              ),
                            ),
                            trailing: url.isNotEmpty
                                ? const Icon(
                                    Icons.open_in_new,
                                    size: 18,
                                    color: _periwinkle,
                                  )
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
                // Visual only: white card, periwinkle glow, light-blue border, 16 px radius
                color: Colors.white,
                elevation: 4,
                shadowColor: _periwinkle.withValues(alpha: 0.30),
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: _lightBlue.withValues(alpha: 0.7)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _quizCompleted ? Icons.check_circle : Icons.quiz,
                            color: _quizCompleted ? _success : _royalBlue,
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: Text(
                              _quizCompleted ? 'Quiz Completed' : 'Quiz',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _quizCompleted
                            ? 'You have completed the quiz.'
                            : 'Test your understanding of this activity.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        // Gradient shows only while the button is enabled
                        child: Container(
                          decoration: _hasSubmitted
                              ? null
                              : BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [_royalBlue, _periwinkle],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _royalBlue.withValues(alpha: 0.30),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                          child: ElevatedButton.icon(
                            onPressed: _hasSubmitted ? null : _openQuiz,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              disabledBackgroundColor:
                                  _lightBlue.withValues(alpha: 0.5),
                              foregroundColor: Colors.white,
                              disabledForegroundColor: AppColors.textSecondary,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              minimumSize: const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            icon: Icon(
                              _quizCompleted ? Icons.refresh : Icons.quiz,
                            ),
                            label: Text(
                              _quizCompleted ? 'Review Quiz' : 'Take Quiz',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                // Visual only: informational card in light blue
                color: _lightBlue.withValues(alpha: 0.25),
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: _periwinkle.withValues(alpha: 0.6)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: _royalBlue),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'This activity does not have a quiz.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textPrimary),
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
      bottomNavigationBar: Container(
        // Visual only: white bar with a light-blue top border and soft shadow
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: _lightBlue.withValues(alpha: 0.7)),
          ),
          boxShadow: [
            BoxShadow(
              color: _periwinkle.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              // Gradient shows while submit is allowed (also during the spinner)
              child: Container(
                decoration: _canSubmit
                    ? BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [_royalBlue, _periwinkle],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _royalBlue.withValues(alpha: 0.30),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      )
                    : null,
                child: ElevatedButton(
                  onPressed:
                      _canSubmit && !_completing ? _submitActivity : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: _canSubmit
                        ? Colors.transparent
                        : _lightBlue.withValues(alpha: 0.5),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: AppColors.textSecondary,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _completing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _hasSubmitted
                              ? 'Activity Submitted'
                              : 'Submit Activity',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}