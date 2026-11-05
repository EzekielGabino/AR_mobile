import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';
import 'package:scilense_ar_mobile/models/experiment_models.dart';
import 'package:scilense_ar_mobile/screens/class_screens/experiment_quiz_screen.dart';
import 'package:scilense_ar_mobile/screens/sample%20lab%20act%20screens/unity_lab_screen.dart';
import 'package:scilense_ar_mobile/services/activity_submission_service.dart';
import 'package:scilense_ar_mobile/services/auth_service.dart';
import 'package:scilense_ar_mobile/services/lab_progress_store.dart';

// Design-system palette (file-private so it cannot clash with AppColors in app_theme.dart)
const Color _navy = Color(0xFF091540);
const Color _royalBlue = Color(0xFF1B2CC1);
const Color _periwinkle = Color(0xFF7692FF);
const Color _lightBlue = Color(0xFFABD2FA);
const Color _success = Color(0xFF2E9E5B);
const Color _amber = Color(0xFFF2A413);
const Color _amberDark = Color(0xFF8A5A00); // readable amber text on light backgrounds
const Color _amberTint = Color(0xFFFFF7E6); // soft amber card background

/// Class-assigned lab detail — layout aligned with [LabActDetailScreen],
/// plus max score, deadline, and submit flow.
///
/// Quiz answers / results are shown only after the teacher **returns**
/// the submission (status == returned).
class ClassLabActivityScreen extends StatefulWidget {
  final Experiment experiment;
  final String classId;
  final String activityId;
  final String? dueDate;
  final String? dueTime;
  final int? maxScore;
  final String? labCategory;
  final String? safetyTips;
  final List<dynamic> apparatus;
  final List<dynamic> elements;
  final List<dynamic> rawSteps;

  const ClassLabActivityScreen({
    super.key,
    required this.experiment,
    required this.classId,
    required this.activityId,
    this.dueDate,
    this.dueTime,
    this.maxScore,
    this.labCategory,
    this.safetyTips,
    this.apparatus = const [],
    this.elements = const [],
    this.rawSteps = const [],
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

  Experiment get experiment => widget.experiment;

  bool get _hasQuiz => experiment.quiz.questions.isNotEmpty;

  bool get _canTakeQuiz => _simulationCompleted && !_hasSubmitted;

  bool get _canSubmit {
    if (_hasSubmitted) return false;
    if (!_simulationCompleted) return false;
    if (!_hasQuiz) return true;
    return _quizCompleted;
  }

  /// Teacher has graded and returned the work.
  bool get _isReturned {
    final status = (_submission?['status'] as String?)?.toLowerCase() ?? '';
    return status == 'returned';
  }

  int? get _maxScore => widget.maxScore ?? experiment.maxScore;

  /// Answer for question at display index. Prefer 1-based index keys.
  String? _answerForQuestion(QuizQuestion q, int index) {
    final v1 = _quizAnswers[index + 1];
    if (v1 != null && v1.isNotEmpty) return v1;
    final v0 = _quizAnswers[index];
    if (v0 != null && v0.isNotEmpty) return v0;
    if (q.order != 0) {
      final vo = _quizAnswers[q.order];
      if (vo != null && vo.isNotEmpty) return vo;
    }
    return null;
  }

  String _optionLabel(QuizQuestion q, String? optionId) {
    if (optionId == null || optionId.isEmpty) return '—';
    final want = optionId.trim().toLowerCase();
    for (final o in q.options) {
      if (o.id.trim().toLowerCase() == want) {
        final id = o.id.toUpperCase();
        return id.isEmpty ? o.text : '$id. ${o.text}';
      }
    }
    return optionId;
  }

  bool _isCorrect(QuizQuestion q, String? answerId) {
    if (answerId == null || answerId.isEmpty) return false;
    final correct = q.correctOption.trim().toLowerCase();
    if (correct.isEmpty) return false;
    return answerId.trim().toLowerCase() == correct;
  }


  @override
  void initState() {
    super.initState();
    _loadStudentSubmission();
  }

  Future<void> _loadStudentSubmission() async {
    final user = AuthService().currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingSubmission = false);
      return;
    }

    try {
      final submission = await _submissionService.getStudentSubmission(
        activityId: widget.activityId,
        studentId: user.id,
      );

      if (!mounted) return;

      if (submission != null) {
        setState(() {
          _submission = submission;
          _hasSubmitted = true;
          _simulationCompleted =
              submission['simulationCompleted'] == true ||
              submission['simulation_completed'] == true;

          final answers = submission['answers'];
          if (answers is List) {
            _quizAnswers = {};
            for (var i = 0; i < answers.length; i++) {
              final answer = answers[i];
              if (answer is! Map) continue;
              final a = Map<String, dynamic>.from(answer);
              final ans = a['answer']?.toString();
              if (ans == null || ans.isEmpty) continue;
              // Prefer explicit questionIndex (0-based) → store as 1-based
              final qi = a['questionIndex'];
              if (qi is num) {
                _quizAnswers[qi.toInt() + 1] = ans;
                continue;
              }
              // Else use order, but force 1-based index when order is 0
              final rawOrder = a['order'];
              int key;
              if (rawOrder is num && rawOrder.toInt() != 0) {
                key = rawOrder.toInt();
              } else if (rawOrder != null &&
                  int.tryParse(rawOrder.toString()) != null &&
                  int.parse(rawOrder.toString()) != 0) {
                key = int.parse(rawOrder.toString());
              } else {
                key = i + 1;
              }
              _quizAnswers[key] = ans;
            }
            _quizCompleted = _quizAnswers.isNotEmpty;
          }
        });
      } else {
        // Restore local in-progress state (lab done / quiz answers)
        final local = await LabProgressStore.load(
          activityId: widget.activityId,
          studentId: user.id,
        );
        if (!mounted) return;
        if (local != null) {
          final answers = local['answers'];
          setState(() {
            _simulationCompleted = local['simulationCompleted'] == true;
            _quizCompleted = local['quizCompleted'] == true;
            if (answers is List) {
              _quizAnswers = {
                for (final a in answers)
                  if (a is Map &&
                      a['order'] is num &&
                      a['answer'] != null)
                    (a['order'] as num).toInt(): a['answer'].toString(),
              };
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading student submission: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSubmission = false);
    }
  }

  Future<void> _persistProgress() async {
    final user = AuthService().currentUser;
    if (user == null || _hasSubmitted) return;
    await LabProgressStore.save(
      activityId: widget.activityId,
      studentId: user.id,
      simulationCompleted: _simulationCompleted,
      quizCompleted: _quizCompleted,
      quizAnswers: _quizAnswers,
    );
  }

  /// Map mobile [StepType] → Unity [StepAction] name (LabContentMapper).
  String _unityActionFor(ExperimentStep s) {
    switch (s.type) {
      case StepType.setup:
      case StepType.align:
        return 'PlaceApparatus';
      case StepType.addElement:
        return 'AddElement';
      case StepType.trigger:
        return 'Observe';
      case StepType.explanation:
        return 'Observe';
    }
  }

  /// Prefer teacher-authored step maps (action: PlaceApparatus, etc.).
  List<Map<String, dynamic>> _unitySteps() {
    if (widget.rawSteps.isNotEmpty) {
      final out = <Map<String, dynamic>>[];
      var i = 0;
      for (final s in widget.rawSteps) {
        i++;
        if (s is! Map) continue;
        final m = Map<String, dynamic>.from(s);
        out.add({
          'order': m['order'] ?? i,
          'instruction': m['instruction'] ?? '',
          'action': m['action'] ?? 'PlaceApparatus',
          'elementFormula': m['elementFormula'] ?? '',
          'targetApparatusName': m['targetApparatusName'] ?? '',
          'sourceApparatusName': m['sourceApparatusName'] ?? '',
          'targetVolume': m['targetVolume'] ?? 0,
          'waitSeconds': m['waitSeconds'] ?? 0,
          'reactionColorHex': m['reactionColorHex'] ?? '',
        });
      }
      if (out.isNotEmpty) return out;
    }

    return experiment.steps.map((s) {
      return {
        'order': s.order,
        'instruction': s.instruction ?? '',
        'action': _unityActionFor(s),
        'elementFormula': s.formula ?? s.element ?? '',
        'targetApparatusName': s.label ?? '',
        'sourceApparatusName': '',
        'targetVolume': s.targetAmount ?? 0,
        'waitSeconds': 0,
        'reactionColorHex': s.reactionColor ?? s.color ?? '',
      };
    }).toList();
  }

  /// Same shape as [LabActivityRemote.toUnityJson] for Unity bridge.
  Map<String, dynamic> _toUnityJson() {
    final steps = _unitySteps();

    // Prefer full web apparatus/elements maps when present
    final apparatus = widget.apparatus.isNotEmpty
        ? widget.apparatus.map((a) {
            if (a is Map) return Map<String, dynamic>.from(a);
            return {'displayName': a.toString(), 'key': a.toString()};
          }).toList()
        : experiment.materials
            .map((m) => {
                  'displayName': m.labEquivalent,
                  'key': m.labEquivalent,
                })
            .toList();

    final elements = widget.elements.isNotEmpty
        ? widget.elements.map((e) {
            if (e is Map) return Map<String, dynamic>.from(e);
            return {'substanceName': e.toString()};
          }).toList()
        : <Map<String, dynamic>>[];

    return {
      'id': widget.activityId,
      'title': experiment.title,
      'labCategory': widget.labCategory ?? '',
      'apparatus': apparatus,
      'elements': elements,
      'steps': steps,
    };
  }

  Future<void> _startLab() async {
    if (_hasSubmitted) return;
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UnityLabScreen(activityJson: _toUnityJson()),
      ),
    );
    if (!mounted) return;
    if (completed == true) {
      setState(() => _simulationCompleted = true);
      await _persistProgress();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lab complete — quiz unlocked.')),
      );
    }
  }

  Future<void> _openQuiz() async {
    if (!_hasQuiz) return;
    if (!_simulationCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Finish the lab activity before taking the quiz.'),
        ),
      );
      return;
    }
    if (_hasSubmitted) return;

    final answers = await Navigator.of(context).push<Map<int, String>>(
      MaterialPageRoute(
        builder: (_) => ExperimentQuizScreen(
          experiment: experiment,
          classId: widget.classId,
          activityId: widget.activityId,
          initialAnswers: Map<int, String>.from(_quizAnswers),
        ),
      ),
    );

    if (!mounted) return;
    if (answers != null) {
      setState(() {
        _quizAnswers = answers;
        _quizCompleted = true;
      });
      await _persistProgress();
    }
  }

  int? _calculateQuizScore() {
    if (!_hasQuiz) return null;
    var correct = 0;
    for (final q in experiment.quiz.questions) {
      final ans = _quizAnswers[q.order];
      if (ans != null && ans == q.correctOption) correct++;
    }
    return correct;
  }

  Future<void> _submitActivity() async {
    if (!_canSubmit || _isSubmitting) return;
    final user = AuthService().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to submit.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final answers = <Map<String, dynamic>>[
        for (var i = 0; i < experiment.quiz.questions.length; i++)
          if (_answerForQuestion(experiment.quiz.questions[i], i) != null)
            {
              'order': i + 1,
              'questionIndex': i,
              'answer': _answerForQuestion(experiment.quiz.questions[i], i),
            },
      ];

      await _submissionService.submitActivity(
        activityId: widget.activityId,
        classId: widget.classId,
        studentId: user.id,
        activityType: 'lab',
        simulationCompleted: _simulationCompleted,
        answers: answers,
        // Score left null until teacher grades & returns
        score: null,
        feedback: null,
      );

      if (!mounted) return;
      setState(() {
        _hasSubmitted = true;
        _submission = {
          'status': 'submitted',
          'answers': answers,
          'simulation_completed': true,
        };
      });
      final uid = user.id;
      await LabProgressStore.clear(
        activityId: widget.activityId,
        studentId: uid,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Submitted. Waiting for teacher to return grades.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _deadlineLabel() {
    final dueDate = widget.dueDate;
    final dueTime = widget.dueTime;
    if (dueDate == null || dueDate.isEmpty) return 'No deadline';
    try {
      final d = DateTime.parse(dueDate);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      var label = '${months[d.month - 1]} ${d.day}, ${d.year}';
      if (dueTime != null && dueTime.isNotEmpty) label += ' · $dueTime';
      return label;
    } catch (_) {
      if (dueTime != null && dueTime.isNotEmpty) return '$dueDate · $dueTime';
      return dueDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSubmission) {
      return Scaffold(
        backgroundColor: AppColors.background,
        // AppBar kept exactly as the ORIGINAL (uses the app theme's AppBar style)
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: _royalBlue),
        ),
      );
    }

    final category = widget.labCategory ?? '';
    final safety = (widget.safetyTips ?? '').trim().isNotEmpty
        ? widget.safetyTips!.trim()
        : experiment.safetyPrecautions.join('\n');

    return Scaffold(
      backgroundColor: AppColors.background,
      // AppBar kept exactly as the ORIGINAL (uses the app theme's AppBar style)
      appBar: AppBar(
        title: Text(
          experiment.title.isEmpty ? 'Lab activity' : experiment.title,
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
        children: [
          // Max score + deadline (class assignment metadata)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(
                  Icons.star_outline,
                  size: 16,
                  color: _royalBlue,
                ),
                label: Text(
                  _isReturned && _submission?['score'] != null
                      ? 'Score: ${_submission!['score']} / ${_maxScore ?? '—'}'
                      : 'Max score: ${_maxScore ?? '—'}',
                ),
                visualDensity: VisualDensity.compact,
                backgroundColor: _lightBlue.withValues(alpha: 0.35),
                side: BorderSide(color: _periwinkle.withValues(alpha: 0.6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                labelStyle: const TextStyle(
                  color: _navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Chip(
                avatar: const Icon(Icons.event, size: 16, color: _royalBlue),
                label: Text(_deadlineLabel()),
                visualDensity: VisualDensity.compact,
                backgroundColor: _lightBlue.withValues(alpha: 0.35),
                side: BorderSide(color: _periwinkle.withValues(alpha: 0.6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                labelStyle: const TextStyle(
                  color: _navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_hasSubmitted)
                Chip(
                  avatar: Icon(
                    _isReturned ? Icons.done_all : Icons.hourglass_top,
                    size: 16,
                    // Green = returned, amber = waiting for teacher
                    color: _isReturned ? _success : _amberDark,
                  ),
                  label: Text(_isReturned ? 'Returned' : 'Submitted'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: _isReturned
                      ? _success.withValues(alpha: 0.12)
                      : _amber.withValues(alpha: 0.15),
                  side: BorderSide(
                    color: _isReturned
                        ? _success.withValues(alpha: 0.6)
                        : _amber.withValues(alpha: 0.6),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  labelStyle: TextStyle(
                    color: _isReturned ? _success : _amberDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (category.isNotEmpty) ...[
            Chip(
              label: Text(category),
              backgroundColor: _lightBlue.withValues(alpha: 0.35),
              side: BorderSide(color: _periwinkle.withValues(alpha: 0.6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              labelStyle: const TextStyle(
                color: _royalBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
          ],

          Text(
            experiment.description.isEmpty
                ? 'No description provided.'
                : experiment.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),

          _SectionCard(
            icon: Icons.health_and_safety_outlined,
            title: 'Safety tips',
            child: Text(
              safety.isEmpty ? 'No safety tips listed.' : safety,
              style: const TextStyle(
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          _SectionCard(
            icon: Icons.science_outlined,
            title: 'Apparatus',
            child: (widget.apparatus.isEmpty && experiment.materials.isEmpty)
                ? const Text('—', style: TextStyle(color: AppColors.textSecondary))
                : Column(
                    children: [
                      if (widget.apparatus.isNotEmpty)
                        ...widget.apparatus.map((a) {
                          final map = a is Map
                              ? Map<String, dynamic>.from(a)
                              : null;
                          final name = map?['displayName'] as String? ??
                              map?['key'] as String? ??
                              a.toString();
                          final maxVol = map?['maxVol'];
                          return _BulletRow(
                            title: name,
                            subtitle: maxVol != null ? 'Capacity $maxVol' : null,
                          );
                        })
                      else
                        ...experiment.materials.map(
                          (m) => _BulletRow(
                            title: m.labEquivalent,
                            subtitle: m.realWorldSubstitute.isEmpty
                                ? null
                                : m.realWorldSubstitute,
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),

          _SectionCard(
            icon: Icons.bubble_chart_outlined,
            title: 'Elements',
            child: widget.elements.isEmpty
                ? const Text('—', style: TextStyle(color: AppColors.textSecondary))
                : Column(
                    children: widget.elements.map((e) {
                      final map = e is Map
                          ? Map<String, dynamic>.from(e)
                          : <String, dynamic>{};
                      final name =
                          map['substanceName'] as String? ?? 'Substance';
                      final formula = map['formula'] as String? ?? '';
                      final type = map['type'] as String? ?? '';
                      final temp = map['temperature'];
                      final role = map['role'] as String? ?? '';
                      final maxVol = map['maxVol'];
                      return _BulletRow(
                        title: formula.isEmpty ? name : '$name ($formula)',
                        subtitle: [
                          if (type.isNotEmpty) type,
                          if (temp != null) '${temp}°C',
                          if (role.isNotEmpty) role,
                          if (maxVol != null) 'Max vol $maxVol',
                        ].join(' · '),
                      );
                    }).toList(),
                  ),
          ),

          if (_simulationCompleted && !_hasSubmitted) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 20, color: _success),
                const SizedBox(width: 8),
                Text(
                  'Lab completed this session.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          // Answers / results only after teacher returns
          if (_isReturned) ...[
            const SizedBox(height: 24),
            Text(
              'Results',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              // Visual only: white card, periwinkle glow, light-blue border, 16 px radius
              color: Colors.white,
              elevation: 4,
              shadowColor: _periwinkle.withValues(alpha: 0.30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: _lightBlue.withValues(alpha: 0.7)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score: ${_submission?['score'] ?? '—'} / ${_maxScore ?? '—'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: _royalBlue,
                      ),
                    ),
                    if ((_submission?['feedback'] as String?)?.isNotEmpty ==
                        true) ...[
                      const SizedBox(height: 8),
                      Text('Feedback: ${_submission!['feedback']}'),
                    ],
                    if (_quizAnswers.isNotEmpty ||
                        experiment.quiz.questions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Your answers:'),
                      const SizedBox(height: 8),
                      ...List.generate(experiment.quiz.questions.length, (i) {
                        final q = experiment.quiz.questions[i];
                        final ansId = _answerForQuestion(q, i);
                        final ansLabel = _optionLabel(q, ansId);
                        final ok = _isCorrect(q, ansId);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Q${i + 1}: $ansLabel${ansId == null ? '' : (ok ? ' ✓' : ' ✗')}',
                              ),
                              if (ansId != null && !ok)
                                Text(
                                  'Correct: ${_optionLabel(q, q.correctOption)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ] else if (_hasSubmitted) ...[
            const SizedBox(height: 24),
            Card(
              color: Colors.amber.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: _amber.withValues(alpha: 0.6)),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.hourglass_top, size: 20, color: _amberDark),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Submitted. Your teacher will review and return a score. '
                        'Answers and results appear after it is returned.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: Container(
        // Visual only: white bar with a soft top shadow
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
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
                        child: FilledButton(
                          onPressed: _hasSubmitted ? null : _startLab,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            disabledBackgroundColor:
                                _lightBlue.withValues(alpha: 0.5),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: AppColors.textSecondary,
                            shadowColor: Colors.transparent,
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text(
                            _simulationCompleted ? 'Review lab' : 'Start lab',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _canTakeQuiz && _hasQuiz ? _openQuiz : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _royalBlue,
                          disabledForegroundColor: AppColors.textSecondary,
                          minimumSize: const Size.fromHeight(56),
                          side: BorderSide(
                            color: _canTakeQuiz && _hasQuiz
                                ? _royalBlue
                                : _lightBlue,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text(
                          _quizCompleted ? 'Quiz done' : 'Quiz',
                        ),
                      ),
                    ),
                  ],
                ),
                if (!_hasSubmitted) ...[
                  const SizedBox(height: 8),
                  SizedBox(
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
                            _canSubmit && !_isSubmitting ? _submitActivity : null,
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
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit activity',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Visual only: the safety card is AMBER (design-system safety warning color).
    // Detected from the existing title string; no new parameter was added.
    final bool isSafety = title == 'Safety tips';

    return Material(
      color: isSafety ? _amberTint : AppColors.cardBackground,
      elevation: 4,
      shadowColor: (isSafety ? _amber : _periwinkle).withValues(alpha: 0.30),
      // shape replaces borderRadius so a thin border can be added
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSafety
              ? _amber.withValues(alpha: 0.6)
              : _lightBlue.withValues(alpha: 0.7),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon chip: gradient for normal cards, amber for the safety card
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: isSafety
                        ? null
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_royalBlue, _periwinkle],
                          ),
                    color: isSafety ? _amber.withValues(alpha: 0.25) : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSafety ? _amberDark : Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isSafety ? _amberDark : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle?.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 8, color: _periwinkle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (sub != null && sub.isNotEmpty)
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}