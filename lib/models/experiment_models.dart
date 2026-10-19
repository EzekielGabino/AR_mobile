double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

enum StepType { setup, align, addElement, trigger, explanation }

/// Physical state of an addElement ingredient. Defaults to `liquid` when
/// missing from Firestore/JSON — every existing sample experiment doc
/// predates this field and was authored as liquid-style ingredients
/// (water, dissolved baking soda, etc), so defaulting elsewhere would
/// silently change behavior for old data.
enum ElementState { solid, liquid, gas }

ElementState _parseElementState(dynamic value) {
  switch (value) {
    case 'solid':
      return ElementState.solid;
    case 'gas':
      return ElementState.gas;
    case 'liquid':
      return ElementState.liquid;
    default:
      return ElementState.liquid;
  }
}

class ExperimentMaterial {
  final String labEquivalent;
  final String realWorldSubstitute;

  const ExperimentMaterial({
    required this.labEquivalent,
    required this.realWorldSubstitute,
  });

  factory ExperimentMaterial.fromJson(Map<String, dynamic> json) {
    return ExperimentMaterial(
      labEquivalent: json['labEquivalent'] as String? ?? '',
      realWorldSubstitute: json['realWorldSubstitute'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'labEquivalent': labEquivalent,
    'realWorldSubstitute': realWorldSubstitute,
  };
}

class ExperimentStep {
  final int order;
  final StepType type;
  final String? element; // e.g. 'baking_soda'
  final String? label;
  final String? formula;
  final String? unit; // e.g. 'tbsp', 'tsp'
  final double? targetAmount;
  final List<double>? amountOptions;
  final String? color; // hex string
  final String? instruction;
  final String? explanation;
  final String? realWorldConnection;
  final bool safetyDialog;
  final bool triggerImmediately;
  // Only meaningful on addElement steps. Drives which visual/physics
  // treatment the ingredient gets once its amount is confirmed — see
  // ReactionPhysicsOverlay.solidDropToken in live_detection_screen_v2.
  final ElementState elementState;
  // Reaction-animation params, set on the trigger step.
  final String? reactionType; // 'foamEruption', 'precipitate', 'combustion'
  // get a Forge2D physics layer (see reaction_physics_overlay.dart);
  // 'colorChange', 'thermal', 'viscosityChange', 'layering',
  // 'neutralizationSnap' stay purely visual via WaterVolumeOverlay.
  final String? reactionColor; // hex string, e.g. foam color
  final int? reactionDurationMs; // how long the animation plays
  final double? foamIntensity; // 0-1, how vigorous the bubbling/overflow is

  const ExperimentStep({
    required this.order,
    required this.type,
    this.element,
    this.label,
    this.formula,
    this.unit,
    this.targetAmount,
    this.amountOptions,
    this.color,
    this.instruction,
    this.explanation,
    this.realWorldConnection,
    this.safetyDialog = false,
    this.triggerImmediately = false,
    this.elementState = ElementState.liquid,
    this.reactionType,
    this.reactionColor,
    this.reactionDurationMs,
    this.foamIntensity,
  });

  factory ExperimentStep.fromJson(Map<String, dynamic> json) {
    return ExperimentStep(
      order: _toInt(json['order']) ?? 0,
      type: StepType.values.byName(json['type'] as String),
      element: json['element'] as String?,
      label: json['label'] as String?,
      formula: json['formula'] as String?,
      unit: json['unit'] as String?,
      targetAmount: _toDouble(json['targetAmount']),
      amountOptions: (json['amountOptions'] as List?)
          ?.map((e) => _toDouble(e) ?? 0.0)
          .toList(),
      color: json['color'] as String?,
      instruction: json['instruction'] as String?,
      explanation: json['explanation'] as String?,
      realWorldConnection: json['realWorldConnection'] as String?,
      safetyDialog: json['safetyDialog'] as bool? ?? false,
      triggerImmediately: json['triggerImmediately'] as bool? ?? false,
      elementState: _parseElementState(json['elementState']),
      reactionType: json['reactionType'] as String?,
      reactionColor: json['reactionColor'] as String?,
      reactionDurationMs: _toInt(json['reactionDurationMs']),
      foamIntensity: _toDouble(json['foamIntensity']),
    );
  }
}

class QuizOption {
  final String id;
  final String text;

  const QuizOption({required this.id, required this.text});

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }
}

class QuizQuestion {
  final int order;
  final String prompt;
  final List<QuizOption> options;
  final String correctOption; // matches a QuizOption.id
  final String? explanation;

  const QuizQuestion({
    required this.order,
    required this.prompt,
    required this.options,
    required this.correctOption,
    this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      order: _toInt(json['order']) ?? 0,
      prompt: json['prompt'] as String? ?? '',
      options: (json['options'] as List? ?? [])
          .map((o) => QuizOption.fromJson(Map<String, dynamic>.from(o as Map)))
          .toList(),
      correctOption: json['correctOption'] as String? ?? '',
      explanation: json['explanation'] as String?,
    );
  }
}

class ExperimentQuiz {
  final List<QuizQuestion> questions;

  const ExperimentQuiz({required this.questions});

  factory ExperimentQuiz.fromJson(Map<String, dynamic> json) {
    return ExperimentQuiz(
      questions:
          (json['questions'] as List? ?? [])
              .map(
                (q) =>
                    QuizQuestion.fromJson(Map<String, dynamic>.from(q as Map)),
              )
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order)),
    );
  }

  factory ExperimentQuiz.empty() => const ExperimentQuiz(questions: []);
}

class Experiment {
  final String id;
  final String? imagePath;
  final String title;
  final String description;
  final int? maxScore;
  final List<ExperimentMaterial> materials;
  final List<String> safetyPrecautions;
  final List<ExperimentStep> steps;
  final ExperimentQuiz quiz;

  const Experiment({
    required this.id,
    required this.title,
    this.imagePath,
    this.description = '',
    this.maxScore,
    required this.materials,
    required this.safetyPrecautions,
    required this.steps,
    required this.quiz,
  });

  factory Experiment.fromJson(String id, Map<String, dynamic> json) {
    return Experiment(
      id: id,
      title: json['title'] as String,
      imagePath: (json['imagePath'] as String?),
      description: json['description'] as String? ?? '',
      maxScore: _toInt(json['maxScore']),
      materials: (json['materials'] as List? ?? [])
          .map((m) => ExperimentMaterial.fromJson(m as Map<String, dynamic>))
          .toList(),
      safetyPrecautions: List<String>.from(json['safetyPrecautions'] ?? []),
      steps:
          (json['steps'] as List)
              .map((s) => ExperimentStep.fromJson(s as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order)),
      quiz: json['quiz'] != null
          ? ExperimentQuiz.fromJson(
              Map<String, dynamic>.from(json['quiz'] as Map),
            )
          : ExperimentQuiz.empty(),
    );
  }
}
