import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/components/class_screens/quiz_results_screen.dart';
import 'package:scilense_ar_mobile/models/experiment_models.dart';

class ExperimentQuizScreen extends StatefulWidget {
  const ExperimentQuizScreen({
    super.key,
    required this.experiment,
    this.classId,
    this.activityId,
  });

  final Experiment experiment;

  // Kept for compatibility with existing callers.
  // They are no longer used to submit the quiz directly.
  final String? classId;
  final String? activityId;

  @override
  State<ExperimentQuizScreen> createState() => _ExperimentQuizScreenState();
}

class _ExperimentQuizScreenState extends State<ExperimentQuizScreen> {
  // question.order -> selected option id
  final Map<int, String> _answers = {};

  bool get _allAnswered {
    final questions = widget.experiment.quiz.questions;

    if (questions.isEmpty) return false;

    return questions.every((q) => _answers.containsKey(q.order));
  }

  Future<void> _submitQuiz() async {
    if (!_allAnswered) return;

    // Show the results first.
    final result = await Navigator.push<Map<int, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultsScreen(
          questions: widget.experiment.quiz.questions,
          answers: Map<int, String>.from(_answers),
        ),
      ),
    );

    if (!mounted || result == null) return;

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.experiment.quiz.questions;

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),

      body: questions.isEmpty
          ? const Center(child: Text('No quiz questions yet.'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 100),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final q = questions[index];
                final selectedId = _answers[q.order];

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
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text('${opt.id.toUpperCase()}. ${opt.text}'),
                            value: opt.id,
                            groupValue: selectedId,
                            onChanged: (value) {
                              if (value == null) return;

                              setState(() {
                                _answers[q.order] = value;
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
                        ? 'Submit Quiz'
                        : 'Answer all '
                              '(${_answers.length}/${questions.length})',
                  ),
                ),
              ),
            ),
    );
  }
}
