import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClassroomJoinException implements Exception {
  final String message;
  ClassroomJoinException(this.message);
  @override
  String toString() => message;
}

/// Lightweight view of a classroom section — just what the mobile UI
/// needs after a successful join. Mirrors the fields Class­Controller.php
/// / create.blade.php write on the web side.
class ClassroomInfo {
  final String id;
  final String sectionName;
  final String gradeLevel;
  final String subject;
  final String accessCode;
  final String teacherUid;

  const ClassroomInfo({
    required this.id,
    required this.sectionName,
    required this.gradeLevel,
    required this.subject,
    required this.accessCode,
    required this.teacherUid,
  });
}

/// Handles a student joining/leaving a classroom section created on the
/// web teacher portal. Mirrors ClassroomController.php's joinClassroom
/// logic, but writes directly to Firestore from the mobile client (same
/// pattern AuthService already uses for the 'users' collection) instead
/// of going through the Laravel API, since the mobile app has no session
/// cookie to authenticate an HTTP call with.
///
/// On a successful join, 'classroomId' (plus a little display metadata)
/// is stamped onto the student's own users/{uid} doc. That's what
/// AuthGate watches to decide between the restricted profile-only state
/// and the full MainScreen — a single cheap document read instead of
/// scanning every class for a matching student entry.
class ClassroomService {
  static final ClassroomService _instance = ClassroomService._internal();
  factory ClassroomService() => _instance;
  ClassroomService._internal();

  final _db = FirebaseFirestore.instance;

  Future<ClassroomInfo> joinByAccessCode(String rawCode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw ClassroomJoinException(
        'You need to be signed in to join a classroom.',
      );
    }

    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      throw ClassroomJoinException('Enter or scan a class code first.');
    }

    final query = await _db
        .collection('classes')
        .where('access_code', isEqualTo: code)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw ClassroomJoinException('No classroom found for code "$code".');
    }

    final classRef = query.docs.first.reference;

    // Transaction so two students joining at once can't clobber each
    // other's append to the same students array.
    final classData = await _db.runTransaction<Map<String, dynamic>>((
      tx,
    ) async {
      final snap = await tx.get(classRef);
      final data = Map<String, dynamic>.from(snap.data() ?? {});
      final students = List<Map<String, dynamic>>.from(
        (data['students'] as List?)?.map(
              (s) => Map<String, dynamic>.from(s as Map),
            ) ??
            [],
      );

      final alreadyEnrolled = students.any((s) => s['uid'] == user.uid);
      if (!alreadyEnrolled) {
        students.add({
          'uid': user.uid,
          'name': user.displayName ?? user.email ?? 'Student',
          'joined_at': DateTime.now().toIso8601String(),
        });
        tx.update(classRef, {'students': students});
      }
      return data;
    });

    await _db.collection('users').doc(user.uid).set({
      'classroomId': classRef.id,
      'classroomName': classData['section_name'],
      'classroomAccessCode': classData['access_code'],
      'classroomJoinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return ClassroomInfo(
      id: classRef.id,
      sectionName: classData['section_name'] as String? ?? 'Untitled Section',
      gradeLevel: classData['grade_level'] as String? ?? '',
      subject: classData['subject'] as String? ?? '',
      accessCode: classData['access_code'] as String? ?? '',
      teacherUid: classData['teacher_uid'] as String? ?? '',
    );
  }

  /// Removes the current user from their classroom's roster and clears
  /// the pointer on their profile doc — this is what sends AuthGate back
  /// to the restricted, profile-only state.
  Future<void> leaveClassroom() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = _db.collection('users').doc(user.uid);
    final userSnap = await userRef.get();
    final classroomId = userSnap.data()?['classroomId'] as String?;

    if (classroomId != null) {
      final classRef = _db.collection('classes').doc(classroomId);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(classRef);
        if (!snap.exists) return;
        final students = List<Map<String, dynamic>>.from(
          (snap.data()?['students'] as List?)?.map(
                (s) => Map<String, dynamic>.from(s as Map),
              ) ??
              [],
        );
        students.removeWhere((s) => s['uid'] == user.uid);
        tx.update(classRef, {'students': students});
      });
    }

    await userRef.set({
      'classroomId': FieldValue.delete(),
      'classroomName': FieldValue.delete(),
      'classroomAccessCode': FieldValue.delete(),
      'classroomJoinedAt': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  /// Live stream of the current user's profile doc — AuthGate and
  /// ProfileScreen both watch this to react instantly to a join/leave.
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchMyProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getStudents(String uid) {
    return _db.collection('classes').doc(uid).snapshots();
  }
}
