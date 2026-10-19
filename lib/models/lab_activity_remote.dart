import 'package:cloud_firestore/cloud_firestore.dart';

/// Apparatus entry from Firestore `labActivities/{id}.apparatus[]`.
class RemoteApparatus {
  final String key;
  final String displayName;
  final double maxVol;

  const RemoteApparatus({
    required this.key,
    required this.displayName,
    required this.maxVol,
  });

  factory RemoteApparatus.fromMap(Map<String, dynamic> map) {
    return RemoteApparatus(
      key: map['key'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      maxVol: _toDouble(map['maxVol']),
    );
  }

  Map<String, dynamic> toMap() => {
        'key': key,
        'displayName': displayName,
        'maxVol': maxVol,
      };
}

/// Element / substance entry from `elements[]`.
class RemoteElement {
  final String substanceName;
  final String formula;
  final String type;
  final double minVol;
  final double maxVol;
  final double volume;
  final double molarity;
  final double temperature;
  final String role;
  final String colorHex;

  const RemoteElement({
    required this.substanceName,
    required this.formula,
    required this.type,
    required this.minVol,
    required this.maxVol,
    required this.volume,
    required this.molarity,
    required this.temperature,
    required this.role,
    required this.colorHex,
  });

  factory RemoteElement.fromMap(Map<String, dynamic> map) {
    return RemoteElement(
      substanceName: map['substanceName'] as String? ?? '',
      formula: map['formula'] as String? ?? '',
      type: map['type'] as String? ?? 'liquid',
      minVol: _toDouble(map['minVol']),
      maxVol: _toDouble(map['maxVol']),
      volume: _toDouble(map['volume']),
      molarity: _toDouble(map['molarity']),
      temperature: _toDouble(map['temperature']),
      role: map['role'] as String? ?? 'Neutral',
      colorHex: map['colorHex'] as String? ?? '#FFFFFFFF',
    );
  }

  Map<String, dynamic> toMap() => {
        'substanceName': substanceName,
        'formula': formula,
        'type': type,
        'minVol': minVol,
        'maxVol': maxVol,
        'volume': volume,
        'molarity': molarity,
        'temperature': temperature,
        'role': role,
        'colorHex': colorHex,
      };
}

/// One lab step from `steps[]`.
class RemoteLabStep {
  final String instruction;
  final String action;
  final String targetApparatusName;
  final String elementFormula;
  final double targetVolume;
  final double waitSeconds;
  final String sourceApparatusName;
  final String reactionColorHex;

  const RemoteLabStep({
    required this.instruction,
    required this.action,
    this.targetApparatusName = '',
    this.elementFormula = '',
    this.targetVolume = 0,
    this.waitSeconds = 0,
    this.sourceApparatusName = '',
    this.reactionColorHex = '',
  });

  factory RemoteLabStep.fromMap(Map<String, dynamic> map) {
    return RemoteLabStep(
      instruction: map['instruction'] as String? ?? '',
      action: map['action'] as String? ?? '',
      targetApparatusName: map['targetApparatusName'] as String? ?? '',
      elementFormula: map['elementFormula'] as String? ?? '',
      targetVolume: _toDouble(map['targetVolume']),
      waitSeconds: _toDouble(map['waitSeconds']),
      sourceApparatusName: map['sourceApparatusName'] as String? ?? '',
      reactionColorHex: map['reactionColorHex'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'instruction': instruction,
        'action': action,
        'targetApparatusName': targetApparatusName,
        'elementFormula': elementFormula,
        'targetVolume': targetVolume,
        'waitSeconds': waitSeconds,
        'sourceApparatusName': sourceApparatusName,
        'reactionColorHex': reactionColorHex,
      };
}

class RemoteQuizOption {
  final String id;
  final String text;

  const RemoteQuizOption({required this.id, required this.text});

  factory RemoteQuizOption.fromMap(Map<String, dynamic> map) {
    return RemoteQuizOption(
      id: map['id'] as String? ?? '',
      text: map['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'text': text};
}

class RemoteQuizQuestion {
  final String id;
  final String prompt;
  final List<RemoteQuizOption> options;
  final String correctOptionId;

  const RemoteQuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctOptionId,
  });

  factory RemoteQuizQuestion.fromMap(Map<String, dynamic> map) {
    final rawOptions = map['options'] as List<dynamic>? ?? [];
    return RemoteQuizQuestion(
      id: map['id'] as String? ?? '',
      prompt: map['prompt'] as String? ?? '',
      options: rawOptions
          .whereType<Map>()
          .map((e) => RemoteQuizOption.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      correctOptionId: map['correctOptionId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'prompt': prompt,
        'options': options.map((o) => o.toMap()).toList(),
        'correctOptionId': correctOptionId,
      };
}

/// Full lab activity document from Firestore `labActivities/{id}`.
class LabActivityRemote {
  final String id;
  final String title;
  final String labCategory;
  final String description;
  final String safetyTips;
  final List<RemoteApparatus> apparatus;
  final List<RemoteElement> elements;
  final List<RemoteLabStep> steps;
  final List<RemoteQuizQuestion> quiz;

  const LabActivityRemote({
    required this.id,
    required this.title,
    required this.labCategory,
    required this.description,
    required this.safetyTips,
    required this.apparatus,
    required this.elements,
    required this.steps,
    required this.quiz,
  });

  factory LabActivityRemote.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return LabActivityRemote.fromMap(data, docId: doc.id);
  }

  factory LabActivityRemote.fromMap(Map<String, dynamic> map, {String? docId}) {
    final apparatusRaw = map['apparatus'] as List<dynamic>? ?? [];
    final elementsRaw = map['elements'] as List<dynamic>? ?? [];
    final stepsRaw = map['steps'] as List<dynamic>? ?? [];
    final quizRaw = map['quiz'] as List<dynamic>? ?? [];

    return LabActivityRemote(
      id: (map['id'] as String?)?.isNotEmpty == true
          ? map['id'] as String
          : (docId ?? ''),
      title: map['title'] as String? ?? '',
      labCategory: map['labCategory'] as String? ?? '',
      description: map['description'] as String? ?? '',
      safetyTips: map['safetyTips'] as String? ?? '',
      apparatus: apparatusRaw
          .whereType<Map>()
          .map((e) => RemoteApparatus.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      elements: elementsRaw
          .whereType<Map>()
          .map((e) => RemoteElement.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      steps: stepsRaw
          .whereType<Map>()
          .map((e) => RemoteLabStep.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      quiz: quizRaw
          .whereType<Map>()
          .map((e) => RemoteQuizQuestion.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  /// Payload for Unity [FlutterLabBridge.SendLabActivityJson].
  /// Omits quiz / safety / description (Flutter-only).
  Map<String, dynamic> toUnityJson() {
    return {
      'id': id,
      'title': title,
      'labCategory': labCategory,
      'apparatus': apparatus.map((a) => a.toMap()).toList(),
      'elements': elements.map((e) => e.toMap()).toList(),
      'steps': steps.map((s) => s.toMap()).toList(),
    };
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'labCategory': labCategory,
        'description': description,
        'safetyTips': safetyTips,
        'apparatus': apparatus.map((a) => a.toMap()).toList(),
        'elements': elements.map((e) => e.toMap()).toList(),
        'steps': steps.map((s) => s.toMap()).toList(),
        'quiz': quiz.map((q) => q.toMap()).toList(),
      };
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
