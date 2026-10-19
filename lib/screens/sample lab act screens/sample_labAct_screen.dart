import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/models/experiment_models.dart';
import 'package:scilense_ar_mobile/screens/sample%20lab%20act%20screens/unity_placeholder_screen.dart';

/// Detail screen for one experiment, reached from either SampleExperiments
/// (browsing the built-in 'experiments' collection — classId/activityId
/// stay null, so nothing downstream can be submitted) or from
/// ActivitiesSection for a real classroom lab activity (classId +
/// activityId passed through so LiveDetectionScreen can show a Submit
/// button and write to classActivities/{activityId}/quizScore).
class SampleLabactScreen extends StatelessWidget {
  final Experiment experiment;
  final String? classId;
  final String? activityId;

  const SampleLabactScreen({
    super.key,
    required this.experiment,
    this.classId,
    this.activityId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(experiment.title), centerTitle: true),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: ListView(
              children: [
                _ExperimentImage(imagePath: experiment.imagePath),
                const SizedBox(height: 20),
                Text(
                  experiment.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                _SectionHeader(title: "Materials Needed"),
                const SizedBox(height: 8),
                ...experiment.materials.map((m) => _MaterialRow(material: m)),
                const SizedBox(height: 24),
                _SectionHeader(title: "Safety Precautions"),
                const SizedBox(height: 8),
                ...experiment.safetyPrecautions.map((p) => _SafetyRow(text: p)),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: 50,
            left: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => UnityPlaceholderScreen()),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("Start Guided Simulation"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header image for the experiment — bundled asset (assets/experiments/...),
/// same reasoning as LabEquipmentImage but simpler since there's no
/// network-image case here. Falls back to a placeholder icon if no path
/// was set on the document, or if the asset fails to load (typo'd path,
/// not registered in pubspec.yaml, etc).
class _ExperimentImage extends StatelessWidget {
  final String? imagePath;

  const _ExperimentImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);

    if (imagePath == null || imagePath!.isEmpty) {
      return ClipRRect(borderRadius: radius, child: _placeholder());
    }

    return ClipRRect(
      borderRadius: radius,
      child: Image.asset(
        imagePath!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.blueGrey.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: const Icon(
        Icons.science_outlined,
        size: 48,
        color: Colors.blueGrey,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _MaterialRow extends StatelessWidget {
  final ExperimentMaterial material;

  const _MaterialRow({required this.material});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.science_outlined, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: material.labEquivalent,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: "  →  "),
                  TextSpan(text: material.realWorldSubstitute),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyRow extends StatelessWidget {
  final String text;

  const _SafetyRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: Colors.orange,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
