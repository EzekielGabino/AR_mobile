import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/models/experiment_models.dart';

class QuizResultsScreen extends StatelessWidget {
  const QuizResultsScreen({
    super.key,
    required this.questions,
    required this.answers,
  });

  final List<QuizQuestion> questions;
  final Map<int, String> answers;

  int get _score {
    var correct = 0;

    for (final q in questions) {
      if (answers[q.order] == q.correctOption) {
        correct++;
      }
    }

    return correct;
  }

  @override
  Widget build(BuildContext context) {
    final score = _score;
    final total = questions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        automaticallyImplyLeading: false,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ------------------------------------------------------------
          // SCORE
          // ------------------------------------------------------------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.emoji_events, size: 64),

                  const SizedBox(height: 16),

                  const Text(
                    'Quiz Completed!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    '$score / $total',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text('Correct Answers'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ------------------------------------------------------------
          // ANSWER REVIEW
          // ------------------------------------------------------------
          const Text(
            'Answer Review',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          ...questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;

            final selectedAnswer = answers[question.order];
            final isCorrect = selectedAnswer == question.correctOption;

            final selectedOption = question.options
                .where((option) => option.id == selectedAnswer)
                .firstOrNull;

            final correctOption = question.options
                .where((option) => option.id == question.correctOption)
                .firstOrNull;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 8),

                    Text(question.prompt, style: const TextStyle(fontSize: 16)),

                    const SizedBox(height: 12),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect ? Colors.green : Colors.red,
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: Text(
                            selectedOption != null
                                ? 'Your answer: '
                                      '${selectedOption.id.toUpperCase()}. '
                                      '${selectedOption.text}'
                                : 'Your answer: Not answered',
                          ),
                        ),
                      ],
                    ),

                    if (!isCorrect && correctOption != null) ...[
                      const SizedBox(height: 8),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),

                          const SizedBox(width: 8),

                          Expanded(
                            child: Text(
                              'Correct answer: '
                              '${correctOption.id.toUpperCase()}. '
                              '${correctOption.text}',
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (question.explanation != null &&
                        question.explanation!.isNotEmpty) ...[
                      const SizedBox(height: 12),

                      Text(
                        question.explanation!,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 80),
        ],
      ),

      // --------------------------------------------------------------
      // DONE BUTTON
      // --------------------------------------------------------------
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                // Return the student's answers directly to
                // ClassLabActivityScreen.
                Navigator.pop(context, Map<int, String>.from(answers));
              },
              child: const Text(
                'Back to Activity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
