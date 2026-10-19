import 'package:cloud_firestore/cloud_firestore.dart';

class ActivitySubmissionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Submit a new activity.
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
    final submissionRef = _db.collection('activitySubmissions').doc();

    await submissionRef.set({
      'activityId': activityId,
      'classId': classId,
      'studentId': studentId,
      'activityType': activityType,
      'status': 'submitted',
      'startedAt': FieldValue.serverTimestamp(),
      'submittedAt': FieldValue.serverTimestamp(),
      'simulationCompleted': simulationCompleted,
      'answers': answers,
      'score': score,
      'feedback': feedback,
      'gradedAt': null,
      'gradedBy': null,
      'returnedAt': null,
    });

    return submissionRef.id;
  }

  /// Get this student's submission for one activity.
  Future<Map<String, dynamic>?> getStudentSubmission({
    required String activityId,
    required String studentId,
  }) async {
    final query = await _db
        .collection('activitySubmissions')
        .where('activityId', isEqualTo: activityId)
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return null;
    }

    return query.docs.first.data();
  }

  /// Watch all submissions belonging to the current student.
  ///
  /// Used by the Activities screen to determine which
  /// activities have already been submitted.
  Stream<Map<String, DocumentSnapshot<Map<String, dynamic>>>>
  watchMySubmissions({required String classId, required String studentId}) {
    return _db
        .collection('activitySubmissions')
        .where('classId', isEqualTo: classId)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
          return {
            for (final doc in snapshot.docs)
              doc.data()['activityId'] as String: doc,
          };
        });
  }

  /// Mark a regular activity as submitted.
  ///
  /// This is useful for activities that don't use the
  /// guided laboratory simulation flow.
  Future<String> markSubmitted({
    required String activityId,
    required String classId,
    required String studentId,
    required String activityType,
    List<Map<String, dynamic>> answers = const [],
    int? score,
    String? feedback,
  }) async {
    final submissionRef = _db.collection('activitySubmissions').doc();

    await submissionRef.set({
      'activityId': activityId,
      'classId': classId,
      'studentId': studentId,
      'activityType': activityType,
      'status': 'submitted',

      'startedAt': FieldValue.serverTimestamp(),
      'submittedAt': FieldValue.serverTimestamp(),

      'simulationCompleted': false,

      'answers': answers,

      'score': score,
      'feedback': feedback,

      'gradedAt': null,
      'gradedBy': null,
      'returnedAt': null,
    });

    return submissionRef.id;
  }
}
