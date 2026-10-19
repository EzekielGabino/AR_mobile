import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/components/class_screens/experiment_quiz_screen.dart';
import 'package:scilense_ar_mobile/models/experiment_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scilense_ar_mobile/screens/sample%20lab%20act%20screens/unity_placeholder_screen.dart';
import 'package:scilense_ar_mobile/services/activity_submission_service.dart';

class ClassLabActivityScreen extends StatefulWidget {
  final Experiment experiment;
  final String classId;
  final String activityId;

  const ClassLabActivityScreen({
    super.key,
    required this.experiment,
    required this.classId,
    required this.activityId,
  });

  @override
  State<ClassLabActivityScreen> createState() => _ClassLabActivityScreenState();
}

class _ClassLabActivityScreenState extends State<ClassLabActivityScreen> {
  final ActivitySubmissionService _submissionService =
      ActivitySubmissionService();
  bool _simulationCompleted = false;
  bool _quizCompleted = false;

  Map<int, String> _quizAnswers = {};

  bool _isSubmitting = false;

  bool _isLoadingSubmission = true;
  bool _hasSubmitted = false;

  Map<String, dynamic>? _submission;

  bool get _hasQuiz => widget.experiment.quiz.questions.isNotEmpty;

  bool get _canTakeQuiz => _simulationCompleted;

  bool get _canSubmit {
    if (_hasSubmitted) return false;

    if (!_simulationCompleted) return false;

    if (!_hasQuiz) return true;

    return _quizCompleted;
  }

  @override
  void initState() {
    super.initState();
    _loadStudentSubmission();
  }

  Future<void> _loadStudentSubmission() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoadingSubmission = false;
        });
      }
      return;
    }

    try {
      final submission = await _submissionService.getStudentSubmission(
        activityId: widget.activityId,
        studentId: user.uid,
      );

      if (!mounted) return;

      if (submission != null) {
        setState(() {
          _submission = submission;
          _hasSubmitted = true;

          _simulationCompleted = submission['simulationCompleted'] == true;

          final answers = submission['answers'];

          if (answers is List) {
            _quizAnswers = {
              for (final answer in answers)
                if (answer is Map &&
                    answer['order'] is num &&
                    answer['answer'] != null)
                  (answer['order'] as num).toInt(): answer['answer'].toString(),
            };

            _quizCompleted = answers is List && answers.isNotEmpty;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading student submission: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSubmission = false;
        });
      }
    }
  }

  Future<void> _startGuidedSimulation() async {
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => UnityPlaceholderScreen()),
    );

    if (!mounted) return;

    if (completed == true) {
      setState(() {
        _simulationCompleted = true;
      });
    }
  }

  Future<void> _openQuiz() async {
    if (!_canTakeQuiz) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please finish the guided simulation before taking the quiz.',
          ),
        ),
      );
      return;
    }

    final result = await Navigator.push<Map<int, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => ExperimentQuizScreen(
          experiment: widget.experiment,
          classId: widget.classId,
          activityId: widget.activityId,
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _quizAnswers = result;
      _quizCompleted = true;
    });
  }

  int _calculateQuizScore() {
    var score = 0;

    for (final question in widget.experiment.quiz.questions) {
      if (_quizAnswers[question.order] == question.correctOption) {
        score++;
      }
    }

    return score;
  }

  Future<void> _submitActivity() async {
    if (!_canSubmit || _isSubmitting) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to submit this activity.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final answers = _quizAnswers.entries.map((entry) {
        return {'order': entry.key, 'answer': entry.value};
      }).toList();

      await _submissionService.submitActivity(
        activityId: widget.activityId,
        classId: widget.classId,
        studentId: user.uid,
        activityType: 'lab',
        simulationCompleted: _simulationCompleted,
        answers: answers,
        score: _hasQuiz ? _calculateQuizScore() : null,
        feedback: null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activity submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Return to the previous screen after successful submission.
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit activity: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final experiment = widget.experiment;

    return Scaffold(
      appBar: AppBar(title: const Text('Lab Activity')),

      body: _isLoadingSubmission
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  Positioned(
                    right: 30,
                    child: Text(
                      _submission?['score'] != null
                          ? 'Points: ${_submission!['score']} / ${experiment.maxScore}'
                          : 'Points: Not graded / ${experiment.maxScore}',
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ------------------------------------------------------------
                      // TITLE
                      // ------------------------------------------------------------
                      Text(
                        experiment.title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 20),

                      // ------------------------------------------------------------
                      // DESCRIPTION
                      // ------------------------------------------------------------
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        experiment.description.isEmpty
                            ? 'No description provided.'
                            : experiment.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),

                      const SizedBox(height: 24),

                      // ------------------------------------------------------------
                      // MATERIALS
                      // ------------------------------------------------------------
                      Text(
                        'Materials',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 8),

                      if (experiment.materials.isEmpty)
                        const Text('No materials listed.')
                      else
                        ...experiment.materials.map(
                          (material) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Lab Equivalent'),
                                    const Text('    ->    '),
                                    const Text('Real World Equivalent'),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '• ${material.labEquivalent}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge,
                                    ),
                                    SizedBox(width: 80),
                                    Text(
                                      '• ${material.realWorldSubstitute}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // ------------------------------------------------------------
                      // SAFETY
                      // ------------------------------------------------------------
                      Text(
                        'Safety Precautions',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 8),

                      if (experiment.safetyPrecautions.isEmpty)
                        const Text('No safety precautions listed.')
                      else
                        ...experiment.safetyPrecautions.map(
                          (precaution) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(precaution)),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // ------------------------------------------------------------
                      // GUIDED SIMULATION CARD
                      // ------------------------------------------------------------
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _simulationCompleted
                                        ? Icons.check_circle
                                        : Icons.science,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _simulationCompleted
                                          ? 'Guided Simulation Complete'
                                          : 'Guided Simulation',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              Text(
                                _simulationCompleted
                                    ? 'You have completed the guided laboratory simulation.'
                                    : 'Follow the AR-guided steps to complete the experiment.',
                              ),

                              const SizedBox(height: 16),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _hasSubmitted
                                      ? null
                                      : _startGuidedSimulation,
                                  icon: Icon(
                                    _simulationCompleted
                                        ? Icons.refresh
                                        : Icons.play_arrow,
                                  ),
                                  label: Text(
                                    _simulationCompleted
                                        ? 'Review Simulation'
                                        : 'Start Guided Simulation',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ------------------------------------------------------------
                      // QUIZ CARD
                      // ------------------------------------------------------------
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _quizCompleted
                                        ? Icons.check_circle
                                        : _canTakeQuiz
                                        ? Icons.quiz
                                        : Icons.lock,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _quizCompleted
                                          ? 'Quiz Completed'
                                          : 'Quiz',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              if (!_simulationCompleted)
                                const Text(
                                  '⚠ Finish the guided simulation first before taking the quiz.',
                                )
                              else if (_quizCompleted)
                                const Text('You have completed the quiz.')
                              else
                                const Text(
                                  'Test your understanding of the experiment.',
                                ),

                              const SizedBox(height: 16),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _hasSubmitted || !_hasQuiz
                                      ? null
                                      : _openQuiz,
                                  icon: Icon(
                                    _canTakeQuiz ? Icons.quiz : Icons.lock,
                                  ),
                                  label: Text(
                                    _quizCompleted
                                        ? 'Review Quiz'
                                        : 'Take Quiz',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Extra space so the last content isn't hidden behind
                      // the bottom submit button.
                      const SizedBox(height: 100),
                    ],
                  ),
                ],
              ),
            ),

      // --------------------------------------------------------------
      // ALWAYS-VISIBLE SUBMIT BUTTON
      // --------------------------------------------------------------
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _canSubmit && !_isSubmitting ? _submitActivity : null,
              child: _isSubmitting
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
