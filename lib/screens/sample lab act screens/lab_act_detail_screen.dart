import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/screens/sample%20lab%20act%20screens/lab_onboarding_screen.dart';
import 'package:scilense_ar_mobile/services/lab_onboarding_store.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';
import 'package:scilense_ar_mobile/models/lab_activity_remote.dart';
import 'package:scilense_ar_mobile/services/lab_activity_service.dart';
import 'package:scilense_ar_mobile/screens/sample%20lab%20act%20screens/unity_lab_screen.dart';

const Color _navy = Color(0xFF091540);
const Color _royalBlue = Color(0xFF1B2CC1);
const Color _periwinkle = Color(0xFF7692FF);
const Color _lightBlue = Color(0xFFABD2FA);
const Color _success = Color(0xFF2E9E5B);
const Color _amber = Color(0xFFF2A413);
const Color _amberDark = Color(0xFF8A5A00);
const Color _amberTint = Color(0xFFFFF7E6);

/// Detail for one lab activity: info, materials, Start lab, gated Quiz.
class LabActDetailScreen extends StatefulWidget {
  const LabActDetailScreen({
    super.key,
    required this.activityId,
    this.initialActivity,
    LabActivityService? service,
  }) : _service = service;

  final String activityId;
  final LabActivityRemote? initialActivity;
  final LabActivityService? _service;

  @override
  State<LabActDetailScreen> createState() => _LabActDetailScreenState();
}

class _LabActDetailScreenState extends State<LabActDetailScreen> {
  LabActivityService get _service => widget._service ?? LabActivityService();

  LabActivityRemote? _activity;
  Object? _error;
  bool _loading = true;
  bool _labComplete = false;

  @override
  void initState() {
    super.initState();
    _activity = widget.initialActivity;
    _loading = widget.initialActivity == null;
    _load();
  }

  Future<void> _load() async {
    try {
      final id = widget.activityId;
      if (id.isEmpty) {
        setState(() {
          _error = 'Missing activity id';
          _loading = false;
        });
        return;
      }

      final remote = await _service.fetchById(id);
      if (!mounted) return;

      if (remote == null) {
        setState(() {
          if (widget.initialActivity != null) {
            _activity = widget.initialActivity;
            _error = null;
          } else {
            _error =
                'Activity not found for id "$id". Check Supabase practice_lab_activities.';
          }
          _loading = false;
        });
        return;
      }

      setState(() {
        _activity = remote;
        _error = null;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('LabActDetail load error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
        _activity ??= widget.initialActivity;
      });
    }
  }

  Future<void> _startLab(LabActivityRemote activity) async {
    if (await LabOnboardingStore.shouldShow()) {
      final go = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LabOnboardingScreen()),
      );
      if (go != true || !mounted) return;
    }
    if (!mounted) return;
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => UnityLabScreen(activityJson: activity.toUnityJson()),
      ),
    );

    if (!mounted) return;
    if (completed == true) {
      setState(() => _labComplete = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lab complete — quiz unlocked.')),
      );
    }
  }

  Future<void> _openQuiz(LabActivityRemote activity) async {
    if (!_labComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Finish the lab activity before taking the quiz.'),
        ),
      );
      return;
    }
    if (activity.quiz.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No quiz for this activity.')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _LabActQuizScreen(questions: activity.quiz),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _activity == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator(color: _royalBlue)),
      );
    }

    if (_activity == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.safetyRed,
                ),
                const SizedBox(height: 16),
                Text(
                  _error?.toString() ?? 'Activity not found.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                _GradientButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _load();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activity = _activity!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(activity.title.isEmpty ? 'Lab activity' : activity.title),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'Note: $_error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          if (activity.labCategory.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: const Icon(
                  Icons.science_outlined,
                  size: 16,
                  color: _royalBlue,
                ),
                label: Text(activity.labCategory),
                labelStyle: const TextStyle(
                  color: _royalBlue,
                  fontWeight: FontWeight.w700,
                ),
                backgroundColor: _lightBlue.withValues(alpha: 0.35),
                side: const BorderSide(color: _periwinkle),
                shape: const StadiumBorder(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            activity.description,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.textPrimary, height: 1.5),
          ),
          const SizedBox(height: 24),
          _SectionCard(
            icon: Icons.health_and_safety_outlined,
            title: 'Safety tips',
            child: Text(
              activity.safetyTips.isEmpty
                  ? 'No safety tips listed.'
                  : activity.safetyTips,
              style: const TextStyle(color: AppColors.textPrimary, height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.science_outlined,
            title: 'Apparatus',
            child: activity.apparatus.isEmpty
                ? const Text(
                    '—',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                : Column(
                    children: activity.apparatus
                        .map(
                          (a) => _BulletRow(
                            title: a.displayName,
                            subtitle: a.maxVol > 0
                                ? 'Capacity ${a.maxVol}'
                                : null,
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            icon: Icons.bubble_chart_outlined,
            title: 'Elements',
            child: activity.elements.isEmpty
                ? const Text(
                    '—',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                : Column(
                    children: activity.elements
                        .map(
                          (e) => _BulletRow(
                            title: '${e.substanceName} (${e.formula})',
                            subtitle:
                                '${e.type} · ${e.temperature}°C · ${e.role} · Max vol ${e.maxVol}',
                          ),
                        )
                        .toList(),
                  ),
          ),
          if (_labComplete) ...[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _success.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: _success,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Lab completed this session.',
                      style: const TextStyle(
                        color: _success,
                        fontWeight: FontWeight.w700,
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
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: _lightBlue.withValues(alpha: 0.7)),
          ),
          boxShadow: [
            BoxShadow(
              color: _periwinkle.withValues(alpha: 0.20),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _GradientButton(
                    onPressed: () => _startLab(activity),
                    child: const Text('Start lab'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _labComplete ? () => _openQuiz(activity) : null,
                    style: ButtonStyle(
                      minimumSize: const WidgetStatePropertyAll(Size(88, 56)),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      textStyle: const WidgetStatePropertyAll(
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.disabled)
                            ? _navy.withValues(alpha: 0.35)
                            : _royalBlue,
                      ),
                      backgroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.disabled)
                            ? _lightBlue.withValues(alpha: 0.30)
                            : Colors.white,
                      ),
                      side: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.disabled)
                            ? BorderSide(
                                color: _lightBlue.withValues(alpha: 0.7),
                              )
                            : const BorderSide(color: _royalBlue, width: 1.5),
                      ),
                    ),
                    child: const Text('Quiz'),
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

class _LabActQuizScreen extends StatefulWidget {
  const _LabActQuizScreen({required this.questions});

  final List<RemoteQuizQuestion> questions;

  @override
  State<_LabActQuizScreen> createState() => _LabActQuizScreenState();
}

class _LabActQuizScreenState extends State<_LabActQuizScreen> {
  final Map<String, String> _answers = {};

  bool get _allAnswered =>
      widget.questions.isNotEmpty &&
      widget.questions.every((q) => _answers.containsKey(q.id));

  void _submit() {
    if (!_allAnswered) return;
    int correct = 0;
    for (final q in widget.questions) {
      if (_answers[q.id] == q.correctOptionId) correct++;
    }
    final total = widget.questions.length;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          color: _navy,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        title: const Text('Quiz results'),
        content: Text(
          'Score: $correct / $total',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _royalBlue,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: _royalBlue,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Quiz')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.questions.length,
        itemBuilder: (context, index) {
          final q = widget.questions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: AppColors.cardBackground,
            elevation: 4,
            shadowColor: _periwinkle.withValues(alpha: 0.30),
            surfaceTintColor: Colors.transparent,
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
                    '${index + 1}. ${q.prompt}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: _navy,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...q.options.map((opt) {
                    final selected = _answers[q.id] == opt.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RadioListTile<String>(
                        title: Text(
                          '${opt.id}. ${opt.text}',
                          style: TextStyle(
                            color: _navy,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        value: opt.id,
                        groupValue: _answers[q.id],
                        activeColor: _royalBlue,
                        selected: selected,
                        selectedTileColor: _lightBlue.withValues(alpha: 0.35),
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: selected
                                ? _periwinkle
                                : _lightBlue.withValues(alpha: 0.7),
                          ),
                        ),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _answers[q.id] = v);
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: _lightBlue.withValues(alpha: 0.7)),
          ),
          boxShadow: [
            BoxShadow(
              color: _periwinkle.withValues(alpha: 0.20),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _GradientButton(
              onPressed: _allAnswered ? _submit : null,
              child: const Text('Submit'),
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
    // Amber styling for the safety card. Matches on the title string; if the
    // title is renamed it simply falls back to the default blue style.
    final isSafety = title == 'Safety tips';

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, t, animChild) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - t)),
            child: animChild,
          ),
        );
      },
      child: Material(
        color: isSafety ? _amberTint : AppColors.cardBackground,
        elevation: 4,
        shadowColor: (isSafety ? _amber : _periwinkle).withValues(alpha: 0.30),
        surfaceTintColor: Colors.transparent,
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
                  Container(
                    width: 36,
                    height: 36,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isSafety ? _amberDark : _navy,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: (isSafety ? _amber : _lightBlue).withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
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
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 8, color: _periwinkle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _navy,
                  ),
                ),
                if (sub != null && sub.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      sub,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
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

/// Wraps a [FilledButton] with the royal blue -> periwinkle gradient and a
/// soft glow. [onPressed] is passed straight through, so a null value still
/// disables the button; only the disabled look changes (pale light blue).
class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.onPressed, required this.child});

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled
            ? const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [_royalBlue, _periwinkle],
              )
            : null,
        color: enabled ? null : _lightBlue.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: _royalBlue.withValues(alpha: 0.30),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledForegroundColor: _navy.withValues(alpha: 0.35),
          shadowColor: Colors.transparent,
          minimumSize: const Size(88, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        child: child,
      ),
    );
  }
}
