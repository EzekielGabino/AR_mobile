import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/models/experiment_models.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

// Design-system palette (file-private so it cannot clash with AppColors in app_theme.dart)
const Color _royalBlue = Color(0xFF1B2CC1);
const Color _periwinkle = Color(0xFF7692FF);
const Color _lightBlue = Color(0xFFABD2FA);

class ExperimentQuizScreen extends StatefulWidget {
  const ExperimentQuizScreen({
    super.key,
    required this.experiment,
    this.classId,
    this.activityId,
    /// order → option id (from a previous attempt)
    this.initialAnswers = const {},
  });

  final Experiment experiment;
  final String? classId;
  final String? activityId;
  final Map<int, String> initialAnswers;

  @override
  State<ExperimentQuizScreen> createState() => _ExperimentQuizScreenState();
}

class _ExperimentQuizScreenState extends State<ExperimentQuizScreen> {
  /// question **index** → selected option id
  final Map<int, String> _answersByIndex = {};

  @override
  void initState() {
    super.initState();
    _seedFromInitial();
  }

  void _seedFromInitial() {
    final questions = widget.experiment.quiz.questions;
    if (widget.initialAnswers.isEmpty || questions.isEmpty) return;

    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      // Match by order, then by 1-based index fallback
      final ans = widget.initialAnswers[q.order] ??
          widget.initialAnswers[i + 1] ??
          widget.initialAnswers[i];
      if (ans != null && ans.isNotEmpty) {
        _answersByIndex[i] = ans;
      }
    }
  }

  bool get _allAnswered {
    final questions = widget.experiment.quiz.questions;
    if (questions.isEmpty) return false;
    return questions.asMap().keys.every(_answersByIndex.containsKey);
  }

  void _submitQuiz() {
    if (!_allAnswered) return;

    final questions = widget.experiment.quiz.questions;
    // Always key by 1-based index so answers stay aligned with question list
    // order (web quizzes often leave every question order = 0).
    final byIndex = <int, String>{};
    for (var i = 0; i < questions.length; i++) {
      byIndex[i + 1] = _answersByIndex[i]!;
    }

    Navigator.pop(context, byIndex);
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.experiment.quiz.questions;
    final isReview = widget.initialAnswers.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      // AppBar kept exactly as the ORIGINAL (uses the app theme's AppBar style)
      appBar: AppBar(
        title: Text(isReview ? 'Edit quiz answers' : 'Quiz'),
      ),
      body: questions.isEmpty
          ? Center(
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
                    child: const Icon(
                      Icons.quiz_outlined,
                      size: 40,
                      color: _periwinkle,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No quiz questions yet.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final q = questions[index];
                final selectedId = _answersByIndex[index];

                return Card(
                  // Visual only: white card, periwinkle glow, light-blue border, 16 px radius
                  color: Colors.white,
                  elevation: 4,
                  shadowColor: _periwinkle.withValues(alpha: 0.30),
                  margin: const EdgeInsets.symmetric(vertical: 8),
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
                          'Question ${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _royalBlue,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          q.prompt,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...q.options.map((opt) {
                          // Visual only (read-only): highlights the chosen option
                          final bool isSelected = selectedId == opt.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: RadioListTile<String>(
                              key: ValueKey('q${index}_${opt.id}'),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              activeColor: _royalBlue,
                              tileColor: isSelected
                                  ? _lightBlue.withValues(alpha: 0.35)
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected
                                      ? _royalBlue
                                      : _lightBlue.withValues(alpha: 0.8),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              title: Text(
                                '${opt.id.toUpperCase()}. ${opt.text}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              value: opt.id,
                              groupValue: selectedId,
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _answersByIndex[index] = value;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: questions.isEmpty
          ? null
          : Container(
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress bar (decorative, only reads _answersByIndex.length)
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _answersByIndex.length / questions.length,
                                minHeight: 8,
                                color: _periwinkle,
                                backgroundColor:
                                    _lightBlue.withValues(alpha: 0.45),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_answersByIndex.length}/${questions.length}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _royalBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        // Gradient shows only while the button is enabled
                        child: Container(
                          decoration: _allAnswered
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
                            onPressed: _allAnswered ? _submitQuiz : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              disabledBackgroundColor:
                                  _lightBlue.withValues(alpha: 0.5),
                              foregroundColor: Colors.white,
                              disabledForegroundColor:
                                  AppColors.textSecondary,
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
                            child: Text(
                              _allAnswered
                                  ? (isReview ? 'Save answers' : 'Submit Quiz')
                                  : 'Answer all '
                                      '(${_answersByIndex.length}/${questions.length})',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}