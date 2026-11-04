import 'package:scilense_ar_mobile/services/supabase_service.dart';

class ActivitySubmissionService {
  dynamic get _client => SupabaseService.client;

  Future<String> submitActivity({
    required String activityId,
    required String classId,
    required String studentId,
    required String activityType,
    required bool simulationCompleted,
    required List<Map<String, dynamic>> answers,
    int? score,
    String? feedback,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final row = await _client.from('activity_submissions').upsert({
      'activity_id': activityId,
      'class_id': classId,
      'student_id': studentId,
      'activity_type': activityType,
      'status': 'submitted',
      'started_at': now,
      'submitted_at': now,
      'simulation_completed': simulationCompleted,
      'answers': answers,
      'score': score,
      'feedback': feedback,
    }, onConflict: 'activity_id,student_id').select('id').maybeSingle();

    return (row?['id'] as String?) ?? '';
  }

  Future<Map<String, dynamic>?> getStudentSubmission({
    required String activityId,
    required String studentId,
  }) async {
    final row = await _client
        .from('activity_submissions')
        .select()
        .eq('activity_id', activityId)
        .eq('student_id', studentId)
        .maybeSingle();
    if (row == null) return null;
    return Map<String, dynamic>.from(row as Map);
  }

  /// activityId → submission row (camel-ish map for UI)
  Future<Map<String, Map<String, dynamic>>> fetchMySubmissions({
    required String classId,
    required String studentId,
  }) async {
    final rows = await _client
        .from('activity_submissions')
        .select()
        .eq('class_id', classId)
        .eq('student_id', studentId);

    final map = <String, Map<String, dynamic>>{};
    for (final r in (rows as List)) {
      final m = Map<String, dynamic>.from(r as Map);
      final aid = m['activity_id'] as String?;
      if (aid != null) map[aid] = m;
    }
    return map;
  }

  Future<String> markSubmitted({
    required String activityId,
    required String classId,
    required String studentId,
    required String activityType,
    List<Map<String, dynamic>> answers = const [],
    int? score,
    String? feedback,
  }) {
    return submitActivity(
      activityId: activityId,
      classId: classId,
      studentId: studentId,
      activityType: activityType,
      simulationCompleted: false,
      answers: answers,
      score: score,
      feedback: feedback,
    );
  }
}
