import 'dart:math';

import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/models/element.dart';
import 'package:scilense_ar_mobile/services/periodic_table_service.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

/// Prompt direction for a single fill-in question.
enum _PromptType { symbolToName, nameToSymbol, numberToSymbol, numberToName }

class _Question {
  const _Question({required this.element, required this.type});

  final ElementData element;
  final _PromptType type;

  String get prompt {
    switch (type) {
      case _PromptType.symbolToName:
        return 'What is the name of ${element.symbol}?';
      case _PromptType.nameToSymbol:
        return 'What is the symbol for ${element.name}?';
      case _PromptType.numberToSymbol:
        return 'What is the symbol for atomic number ${element.atomicNumber}?';
      case _PromptType.numberToName:
        return 'What is the name of atomic number ${element.atomicNumber}?';
    }
  }

  String get expected {
    switch (type) {
      case _PromptType.symbolToName:
      case _PromptType.numberToName:
        return element.name;
      case _PromptType.nameToSymbol:
      case _PromptType.numberToSymbol:
        return element.symbol;
    }
  }

  String get hintLabel {
    switch (type) {
      case _PromptType.symbolToName:
      case _PromptType.numberToName:
        return 'Element name';
      case _PromptType.nameToSymbol:
      case _PromptType.numberToSymbol:
        return 'Chemical symbol';
    }
  }

  bool isCorrect(String raw) {
    final answer = _normalize(raw);
    if (answer.isEmpty) return false;

    switch (type) {
      case _PromptType.symbolToName:
      case _PromptType.numberToName:
        return _namesMatch(answer, element.name);
      case _PromptType.nameToSymbol:
      case _PromptType.numberToSymbol:
        return answer.toLowerCase() == element.symbol.toLowerCase();
    }
  }

  static String _normalize(String s) =>
      s.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Case-insensitive; accepts Aluminium/Aluminum.
  static bool _namesMatch(String answer, String expected) {
    final a = answer.toLowerCase();
    final e = expected.toLowerCase();
    if (a == e) return true;
    if ((a == 'aluminum' || a == 'aluminium') &&
        (e == 'aluminum' || e == 'aluminium')) {
      return true;
    }
    if ((a == 'sulfur' || a == 'sulphur') &&
        (e == 'sulfur' || e == 'sulphur')) {
      return true;
    }
    return false;
  }
}

class ElementMemoryScreen extends StatefulWidget {
  const ElementMemoryScreen({super.key});

  @override
  State<ElementMemoryScreen> createState() => _ElementMemoryScreenState();
}

class _ElementMemoryScreenState extends State<ElementMemoryScreen> {
  final _service = PeriodicTableService();
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();
  final _random = Random();

  List<ElementData> _pool = [];
  final List<_Question> _queue = [];

  _Question? _current;
  bool _loading = true;
  String? _loadError;

  /// null = question phase; true/false = feedback phase
  bool? _lastCorrect;
  int _correctCount = 0;
  int _missedCount = 0;

  static const int _firstN = 118;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final all = await _service.loadElements();
      final sorted = List<ElementData>.from(all)
        ..sort((a, b) => a.atomicNumber.compareTo(b.atomicNumber));
      final first20 = sorted
          .where((e) => e.atomicNumber >= 1 && e.atomicNumber <= _firstN)
          .toList();

      if (!mounted) return;
      setState(() {
        _pool = first20.isNotEmpty ? first20 : sorted.take(_firstN).toList();
        _loading = false;
      });
      _nextQuestion();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Could not load elements.';
      });
    }
  }

  void _refillQueue() {
    if (_pool.isEmpty) return;

    final types = _PromptType.values;
    final batch = <_Question>[];
    for (final el in _pool) {
      // One random prompt type per element per cycle
      batch.add(
        _Question(element: el, type: types[_random.nextInt(types.length)]),
      );
    }
    batch.shuffle(_random);

    // Avoid immediate repeat of the same element if possible
    if (_current != null &&
        batch.isNotEmpty &&
        batch.first.element.atomicNumber == _current!.element.atomicNumber &&
        batch.length > 1) {
      final first = batch.removeAt(0);
      batch.add(first);
    }

    _queue.addAll(batch);
  }

  void _nextQuestion() {
    if (_pool.isEmpty) return;
    if (_queue.isEmpty) _refillQueue();
    if (_queue.isEmpty) return;

    setState(() {
      _current = _queue.removeAt(0);
      _lastCorrect = null;
      _inputController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _lastCorrect == null) {
        _inputFocus.requestFocus();
      }
    });
  }

  void _submit() {
    final q = _current;
    if (q == null || _lastCorrect != null) return;

    final ok = q.isCorrect(_inputController.text);
    setState(() {
      _lastCorrect = ok;
      if (ok) {
        _correctCount++;
      } else {
        _missedCount++;
      }
    });
    _inputFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Element Memory'),
        centerTitle: true,
        actions: [
          if (!_loading && _loadError == null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '$_correctCount correct · $_missedCount missed',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _loadError!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    if (_current == null) {
      return const Center(child: Text('No elements available.'));
    }

    final q = _current!;
    final inFeedback = _lastCorrect != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'First $_firstN elements · continuous practice',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PromptCard(prompt: q.prompt),
                        const SizedBox(height: 20),
                        if (!inFeedback) ...[
                          TextField(
                            controller: _inputController,
                            focusNode: _inputFocus,
                            textInputAction: TextInputAction.done,
                            textCapitalization: TextCapitalization.sentences,
                            autocorrect: false,
                            decoration: InputDecoration(
                              labelText: q.hintLabel,
                              filled: true,
                              fillColor: AppColors.cardBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            onSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Submit',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ] else ...[
                          _FeedbackPanel(
                            correct: _lastCorrect!,
                            expected: q.expected,
                            userAnswer: _inputController.text.trim(),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _nextQuestion,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Next',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.prompt});

  final String prompt;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      elevation: 2,
      shadowColor: AppColors.primaryDark.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Text(
          prompt,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({
    required this.correct,
    required this.expected,
    required this.userAnswer,
  });

  final bool correct;
  final String expected;
  final String userAnswer;

  @override
  Widget build(BuildContext context) {
    final color = correct ? const Color(0xFF2E7D32) : AppColors.safetyRed;
    final bg = correct ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(correct ? Icons.check_circle : Icons.cancel, color: color),
              const SizedBox(width: 8),
              Text(
                correct ? 'Correct' : 'Incorrect',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          if (!correct) ...[
            const SizedBox(height: 10),
            if (userAnswer.isNotEmpty)
              Text(
                'Your answer: $userAnswer',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Correct answer: $expected',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
