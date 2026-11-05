import 'dart:math';

import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/models/element.dart';
import 'package:scilense_ar_mobile/services/periodic_table_service.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

// Design-system palette (file-private so it cannot clash with AppColors in app_theme.dart)
const Color _navy = Color(0xFF091540);
const Color _royalBlue = Color(0xFF1B2CC1);
const Color _periwinkle = Color(0xFF7692FF);
const Color _lightBlue = Color(0xFFABD2FA);

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
      // AppBar kept exactly as the ORIGINAL (uses the app theme's AppBar style)
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
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _royalBlue));
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

    // Visual only: accuracy derived from the existing counters (read-only)
    final int totalAnswered = _correctCount + _missedCount;
    final double accuracy = totalAnswered == 0
        ? 0.0
        : _correctCount / totalAnswered;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
            const SizedBox(height: 8),
            // Accuracy progress bar (decorative, reads _correctCount/_missedCount only)
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: accuracy,
                      minHeight: 8,
                      color: _periwinkle,
                      backgroundColor: _lightBlue.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(accuracy * 100).round()}%',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _royalBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PromptCard(prompt: q.prompt),
                        const SizedBox(height: 24),
                        if (!inFeedback) ...[
                          TextField(
                            controller: _inputController,
                            focusNode: _inputFocus,
                            textInputAction: TextInputAction.done,
                            textCapitalization: TextCapitalization.sentences,
                            autocorrect: false,
                            // Monospace for symbols / element names being typed
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText: q.hintLabel,
                              labelStyle: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                              floatingLabelStyle: const TextStyle(
                                color: _royalBlue,
                                fontWeight: FontWeight.w600,
                              ),
                              prefixIcon: const Icon(
                                Icons.edit_rounded,
                                color: _periwinkle,
                              ),
                              filled: true,
                              fillColor: AppColors.cardBackground,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _lightBlue.withValues(alpha: 0.9),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _lightBlue.withValues(alpha: 0.9),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: _royalBlue,
                                  width: 2,
                                ),
                              ),
                            ),
                            onSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 16),
                          _GradientButton(
                            onPressed: _submit,
                            label: 'Submit',
                            colors: const [_royalBlue, _periwinkle],
                          ),
                        ] else ...[
                          _FeedbackPanel(
                            correct: _lastCorrect!,
                            expected: q.expected,
                            userAnswer: _inputController.text.trim(),
                          ),
                          const SizedBox(height: 16),
                          _GradientButton(
                            onPressed: _nextQuestion,
                            label: 'Next',
                            colors: const [_navy, _royalBlue],
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

/// Visual-only button wrapper: gradient + glow around a normal FilledButton.
/// The onPressed callback is passed straight through to the FilledButton.
class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.onPressed,
    required this.label,
    required this.colors,
  });

  final VoidCallback onPressed;
  final String label;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: colors,
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
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
      elevation: 4,
      shadowColor: _periwinkle.withValues(alpha: 0.30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _lightBlue.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Friendly icon chip (decorative)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _lightBlue.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.science_rounded,
                size: 24,
                color: _royalBlue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              prompt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ],
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

    // Light entrance animation (visual only)
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.scale(scale: 0.96 + 0.04 * value, child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  correct ? Icons.check_circle : Icons.cancel,
                  color: color,
                  size: 28,
                ),
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
              const SizedBox(height: 8),
              if (userAnswer.isNotEmpty)
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Your answer: '),
                      // Monospace for the typed value
                      TextSpan(
                        text: userAnswer,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Correct answer: '),
                    // Monospace for the expected symbol / name
                    TextSpan(
                      text: expected,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ],
                ),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
