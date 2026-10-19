import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/models/lab_activity_remote.dart';
import 'package:scilense_ar_mobile/services/lab_activity_service.dart';
import 'package:scilense_ar_mobile/screens/sample%20lab%20act%20screens/unity_lab_screen.dart';

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
                'Activity not found for id "$id". Check Firestore document id.';
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
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_activity == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error?.toString() ?? 'Activity not found.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
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
      appBar: AppBar(
        title: Text(activity.title.isEmpty ? 'Lab activity' : activity.title),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Note: $_error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (activity.labCategory.isNotEmpty) ...[
            Chip(label: Text(activity.labCategory)),
            const SizedBox(height: 12),
          ],
          Text(
            activity.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Text('Safety tips', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            activity.safetyTips.isEmpty
                ? 'No safety tips listed.'
                : activity.safetyTips,
          ),
          const SizedBox(height: 20),
          Text('Apparatus', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          if (activity.apparatus.isEmpty)
            const Text('—')
          else
            ...activity.apparatus.map(
              (a) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(a.displayName),
                subtitle: a.maxVol > 0 ? Text('Capacity ${a.maxVol}') : null,
              ),
            ),
          const SizedBox(height: 12),
          Text('Elements', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          if (activity.elements.isEmpty)
            const Text('—')
          else
            ...activity.elements.map(
              (e) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('${e.substanceName} (${e.formula})'),
                subtitle: Text(
                  '${e.type} · ${e.temperature}°C · ${e.role}\nMax Volume · ${e.maxVol}',
                ),
              ),
            ),
          if (_labComplete) ...[
            const SizedBox(height: 16),
            Text(
              'Lab completed this session.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _startLab(activity),
                  child: const Text('Start lab'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _labComplete ? () => _openQuiz(activity) : null,
                  child: const Text('Quiz'),
                ),
              ),
            ],
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
        title: const Text('Quiz results'),
        content: Text('Score: $correct / $total'),
        actions: [
          TextButton(
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
      appBar: AppBar(title: const Text('Quiz')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.questions.length,
        itemBuilder: (context, index) {
          final q = widget.questions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}. ${q.prompt}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...q.options.map(
                    (opt) => RadioListTile<String>(
                      title: Text('${opt.id}. ${opt.text}'),
                      value: opt.id,
                      groupValue: _answers[q.id],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _answers[q.id] = v);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _allAnswered ? _submit : null,
            child: const Text('Submit'),
          ),
        ),
      ),
    );
  }
}
