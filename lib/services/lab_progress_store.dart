import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local progress for a class lab before formal submit.
/// Survives leaving the activity screen and app restarts.
class LabProgressStore {
  LabProgressStore._();

  static String _key(String activityId, String studentId) =>
      'lab_progress_${activityId}_$studentId';

  static Future<Map<String, dynamic>?> load({
    required String activityId,
    required String studentId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(activityId, studentId));
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save({
    required String activityId,
    required String studentId,
    required bool simulationCompleted,
    required bool quizCompleted,
    required Map<int, String> quizAnswers,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'simulationCompleted': simulationCompleted,
      'quizCompleted': quizCompleted,
      'answers': [
        for (final e in quizAnswers.entries)
          {'order': e.key, 'answer': e.value},
      ],
    };
    await prefs.setString(_key(activityId, studentId), jsonEncode(payload));
  }

  static Future<void> clear({
    required String activityId,
    required String studentId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(activityId, studentId));
  }
}
