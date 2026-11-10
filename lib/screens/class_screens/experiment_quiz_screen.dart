import 'dart:math';

import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/models/experiment_models.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

const Color _royalBlue = Color(0xFF1B2CC1);
const Color _periwinkle = Color(0xFF7692FF);
const Color _lightBlue = Color(0xFFABD2FA);

class ExperimentQuizScreen extends StatefulWidget {
  const ExperimentQuizScreen({
    super.key,
    required this.experiment,
    this.classId,
    this.activityId,
    /// order / 1-based index → option id (from a previous attempt)
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
  /// Display index → selected option id
  final Map<int, String> _answersByIndex = {};

  /// Display list (may be shuffled)
  late List<QuizQuestion> _displayQuestions;

  /// Display index → original question index in experiment.quiz.questions
  late List<int> _originalIndices;

  late final bool _isReview;

  @override
  void initState() {
    super.initState();
    _isReview = widget.initialAnswers.isNotEmpty;
    _buildDisplayQuestions();
    _seedFromInitial();
  }

  void _buildDisplayQuestions() {
    final source = widget.experiment.quiz.questions;
    final indices = List<int>.generate(source.length, (i) => i);
    final rng = Random();

    if (!_isReview && indices.length > 1) {
      indices.shuffle(rng);
    }

    _originalIndices = indices;
    _displayQuestions = [
      for (final i in indices)
        _withMaybeShuffledOptions(source[i], shuffle: !_isReview, rng: rng),
    ];
  }

  QuizQuestion _withMaybeShuffledOptions(
    QuizQuestion q, {
    required bool shuffle,
    required Random rng,
  }) {
    final opts = List<QuizOption>.from(q.options);
    if (shuffle && opts.length > 1) {
      opts.shuffle(rng);
    }
    return QuizQuestion(
      order: q.order,
      prompt: q.prompt,
      options: opts,
      correctOption: q.correctOption,
      explanation: q.explanation,
    );
  }

  void _seedFromInitial() {
    if (widget.initialAnswers.isEmpty || _displayQuestions.isEmpty) return;

    for (var displayI = 0; displayI < _displayQuestions.length; displayI++) {
      final origI = _originalIndices[displayI];
      final q = _displayQuestions[displayI];
      final ans = widget.initialAnswers[origI + 1] ??
          widget.initialAnswers[q.order] ??
          widget.initialAnswers[origI] ??
          widget.initialAnswers[displayI + 1];
      if (ans != null && ans.isNotEmpty) {
        _answersByIndex[displayI] = ans;
      }
    }
  }

  bool get _allAnswered {
    if (_displayQuestions.isEmpty) return false;
    return _displayQuestions.asMap().keys.every(_answersByIndex.containsKey);
  }

  void _submitQuiz() {
    if (!_allAnswered) return;

    // Key by 1-based **original** question index so scoring stays stable
    // after shuffle.
    final byOriginalIndex = <int, String>{};
    for (var displayI = 0; displayI < _displayQuestions.length; displayI++) {
      final origI = _originalIndices[displayI];
      byOriginalIndex[origI + 1] = _answersByIndex[displayI]!;
    }

    Navigator.pop(context, byOriginalIndex);
  }

  @override
  Widget build(BuildContext context) {
    final questions = _displayQuestions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isReview ? 'Review quiz' : 'Lab quiz'),
        centerTitle: true,
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: questions.isEmpty
          ? const Center(child: Text('No quiz questions for this lab.'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final q = questions[index];
                final selected = _answersByIndex[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  color: Colors.white,
                  elevation: 3,
                  shadowColor: _periwinkle.withValues(alpha: 0.28),
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
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _royalBlue,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          q.prompt,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...q.options.map((opt) {
                          final isSelected = selected == opt.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: isSelected
                                  ? _lightBlue.withValues(alpha: 0.45)
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  setState(() {
                                    _answersByIndex[index] = opt.id;
                                  });
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? _royalBlue
                                          : _periwinkle.withValues(alpha: 0.35),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        size: 20,
                                        color: isSelected
                                            ? _royalBlue
                                            : AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          opt.text,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _allAnswered ? _submitQuiz : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _royalBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          _periwinkle.withValues(alpha: 0.35),
                    ),
                    child: Text(
                      _isReview ? 'Save answers' : 'Done',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
