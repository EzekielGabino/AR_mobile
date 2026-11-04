import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/models/experiment_models.dart';

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
      appBar: AppBar(
        title: Text(isReview ? 'Edit quiz answers' : 'Quiz'),
      ),
      body: questions.isEmpty
          ? const Center(child: Text('No quiz questions yet.'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 100),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final q = questions[index];
                final selectedId = _answersByIndex[index];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(q.prompt),
                        const SizedBox(height: 4),
                        ...q.options.map((opt) {
                          return RadioListTile<String>(
                            key: ValueKey('q${index}_${opt.id}'),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text('${opt.id.toUpperCase()}. ${opt.text}'),
                            value: opt.id,
                            groupValue: selectedId,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _answersByIndex[index] = value;
                              });
                            },
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
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _allAnswered ? _submitQuiz : null,
                  child: Text(
                    _allAnswered
                        ? (isReview ? 'Save answers' : 'Submit Quiz')
                        : 'Answer all '
                            '(${_answersByIndex.length}/${questions.length})',
                  ),
                ),
              ),
            ),
    );
  }
}
