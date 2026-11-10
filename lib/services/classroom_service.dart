import 'dart:async';

import 'package:scilense_ar_mobile/services/auth_service.dart';
import 'package:scilense_ar_mobile/services/supabase_service.dart';

class ClassroomJoinException implements Exception {
  final String message;
  ClassroomJoinException(this.message);
  @override
  String toString() => message;
}

/// Lightweight view of a classroom after a successful join.
class ClassroomInfo {
  final String id;
  final String sectionName;
  final String gradeLevel;
  final String subject;
  final String accessCode;
  final String teacherUid;
  /// pending | approved | rejected
  final String membershipStatus;

  const ClassroomInfo({
    required this.id,
    required this.sectionName,
    required this.gradeLevel,
    required this.subject,
    required this.accessCode,
    required this.teacherUid,
    this.membershipStatus = 'approved',
  });

  bool get isPending => membershipStatus == 'pending';
  bool get isApproved => membershipStatus == 'approved';
}

/// Join / leave classroom via Supabase (mobile M3).
class ClassroomService {
  static final ClassroomService _instance = ClassroomService._internal();
  factory ClassroomService() => _instance;
  ClassroomService._internal();

  final _profileTicks = StreamController<void>.broadcast();

  dynamic get _client => SupabaseService.client;

  /// Accepts raw codes or QR payloads like https://host/join/ABC123.
  static String normalizeAccessCode(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return '';
    final uri = Uri.tryParse(s);
    if (uri != null && (uri.hasScheme || s.contains('/join/'))) {
      final segments = uri.pathSegments.where((e) => e.isNotEmpty).toList();
      final joinIdx = segments.indexWhere((e) => e.toLowerCase() == 'join');
      if (joinIdx >= 0 && joinIdx + 1 < segments.length) {
        s = segments[joinIdx + 1];
      } else if (uri.queryParameters['code'] != null) {
        s = uri.queryParameters['code']!;
      } else if (uri.queryParameters['access_code'] != null) {
        s = uri.queryParameters['access_code']!;
      } else {
        final joinAt = s.toLowerCase().lastIndexOf('/join/');
        if (joinAt >= 0) {
          s = s.substring(joinAt + 6).split(RegExp(r'[?#/]')).first;
        }
      }
    }
    s = s.trim().toUpperCase();
    final match = RegExp(r'[A-Z0-9]{4,12}').firstMatch(s);
    if (match != null &&
        (s.length > 12 || s.contains('HTTP') || s.contains(' '))) {
      return match.group(0)!;
    }
    return s.replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  /// Call after profile classroom fields change so AuthGate rebuilds.
  void notifyProfileChanged() {
    if (!_profileTicks.isClosed) {
      _profileTicks.add(null);
    }
  }

  Future<Map<String, dynamic>?> fetchMyProfile(String uid) async {
    try {
      final row = await _client
          .from('profiles')
          .select(
            'classroom_id, classroom_name, classroom_access_code, display_name, photo_url, email, role',
          )
          .eq('id', uid)
          .maybeSingle();
      if (row == null) return null;
      return Map<String, dynamic>.from(row as Map);
    } catch (_) {
      return null;
    }
  }

  /// Initial fetch + refresh whenever [notifyProfileChanged] is called.
  Stream<Map<String, dynamic>?> watchMyProfile(String uid) async* {
    yield await fetchMyProfile(uid);
    await for (final _ in _profileTicks.stream) {
      yield await fetchMyProfile(uid);
    }
  }

  Future<ClassroomInfo> joinByAccessCode(String rawCode) async {
    final user = AuthService().currentUser;
    if (user == null) {
      throw ClassroomJoinException(
        'You need to be signed in to join a classroom.',
      );
    }

    final code = normalizeAccessCode(rawCode);
    if (code.isEmpty) {
      throw ClassroomJoinException('Enter or scan a class code first.');
    }

    final rows = await _client
        .from('classes')
        .select(
          'id, section_name, grade_level, subject, access_code, teacher_id',
        )
        .eq('access_code', code)
        .limit(1);

    final list = rows as List;
    if (list.isEmpty) {
      throw ClassroomJoinException('No classroom found for code "$code".');
    }

    final row = Map<String, dynamic>.from(list.first as Map);
    final classId = row['id'] as String;
    final sectionName = row['section_name'] as String? ?? '';
    final gradeLevel = row['grade_level'] as String? ?? '';
    final subject = row['subject'] as String? ?? '';
    final accessCode = row['access_code'] as String? ?? code;
    final teacherUid = row['teacher_id'] as String? ?? '';

    final existing = await fetchMyMembership(classId);
    final existingStatus = existing?['status'] as String?;
    if (existingStatus == 'approved') {
      final info = ClassroomInfo(
        id: classId,
        sectionName: sectionName,
        gradeLevel: gradeLevel,
        subject: subject,
        accessCode: accessCode,
        teacherUid: teacherUid,
        membershipStatus: 'approved',
      );
      await activateApprovedClassroom(info);
      return info;
    }

    // Request membership — stays pending until teacher approves
    try {
      await _client.from('class_members').upsert({
        'class_id': classId,
        'user_id': user.id,
        'role': 'student',
        'status': 'pending',
        'joined_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'class_id,user_id');
    } catch (e) {
      try {
        await _client.from('class_members').insert({
          'class_id': classId,
          'user_id': user.id,
          'role': 'student',
          'status': 'pending',
          'joined_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (e2) {
        throw ClassroomJoinException(
          'Could not request to join class. Run 014_class_join_approval.sql in Supabase. Details: $e2',
        );
      }
    }

    // Do NOT set profiles.classroom_id until approved
    notifyProfileChanged();

    return ClassroomInfo(
      id: classId,
      sectionName: sectionName,
      gradeLevel: gradeLevel,
      subject: subject,
      accessCode: accessCode,
      teacherUid: teacherUid,
      membershipStatus: 'pending',
    );
  }

  /// Pending membership row for the signed-in student (if any).
  Future<Map<String, dynamic>?> fetchMyPendingMembership() async {
    final user = AuthService().currentUser;
    if (user == null) return null;
    try {
      final row = await _client
          .from('class_members')
          .select(
            'class_id, status, role, classes(id, section_name, grade_level, subject, access_code, teacher_id)',
          )
          .eq('user_id', user.id)
          .eq('status', 'pending')
          .maybeSingle();
      if (row == null) return null;
      return Map<String, dynamic>.from(row as Map);
    } catch (_) {
      return null;
    }
  }

  /// Any membership for user (pending/approved/rejected) for a class.
  Future<Map<String, dynamic>?> fetchMyMembership(String classId) async {
    final user = AuthService().currentUser;
    if (user == null) return null;
    try {
      final row = await _client
          .from('class_members')
          .select('class_id, status, role')
          .eq('user_id', user.id)
          .eq('class_id', classId)
          .maybeSingle();
      if (row == null) return null;
      return Map<String, dynamic>.from(row as Map);
    } catch (_) {
      return null;
    }
  }

  Stream<Map<String, dynamic>?> watchMyMemberships() {
    final user = AuthService().currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _client
        .from('class_members')
        .stream(primaryKey: ['class_id', 'user_id'])
        .eq('user_id', user.id)
        .map((rows) {
      if (rows is! List || rows.isEmpty) return null;
      // Prefer approved, else pending, else first
      final list = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      Map<String, dynamic>? approved;
      Map<String, dynamic>? pending;
      for (final m in list) {
        final s = m['status'] as String? ?? '';
        if (s == 'approved') approved = m;
        if (s == 'pending') pending = m;
      }
      return approved ?? pending ?? list.first;
    });
  }

  /// After teacher approves, attach class to profile so AuthGate opens MainScreen.
  Future<void> activateApprovedClassroom(ClassroomInfo info) async {
    final user = AuthService().currentUser;
    if (user == null) return;
    await _client.from('profiles').update({
      'classroom_id': info.id,
      'classroom_name': info.sectionName,
      'classroom_access_code': info.accessCode,
      'classroom_joined_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', user.id);
    notifyProfileChanged();
  }

  Future<void> cancelJoinRequest(String classId) async {
    final user = AuthService().currentUser;
    if (user == null) return;
    await _client
        .from('class_members')
        .delete()
        .eq('class_id', classId)
        .eq('user_id', user.id);
    notifyProfileChanged();
  }

  Future<void> leaveClassroom() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final profile = await fetchMyProfile(user.id);
    final classroomId = profile?['classroom_id'] as String?;

    if (classroomId != null && classroomId.isNotEmpty) {
      try {
        await _client
            .from('class_members')
            .delete()
            .eq('class_id', classroomId)
            .eq('user_id', user.id);
      } catch (_) {}
    }

    await _client.from('profiles').update({
      'classroom_id': null,
      'classroom_name': null,
      'classroom_access_code': null,
      'classroom_joined_at': null,
    }).eq('id', user.id);

    notifyProfileChanged();
  }

  /// Published class lab activities whose content.elements mention [symbol] or [name].
  Future<List<Map<String, dynamic>>> fetchPublishedActivitiesForElement({
    required String classId,
    required String symbol,
    required String name,
  }) async {
    if (classId.isEmpty) return [];
    try {
      final rows = await _client
          .from('class_activities')
          .select('id, title, description, due_date, due_time, type, content, published')
          .eq('class_id', classId)
          .eq('published', true)
          .order('published_at', ascending: false);
      final sym = symbol.trim().toLowerCase();
      final nm = name.trim().toLowerCase();
      final out = <Map<String, dynamic>>[];
      for (final r in (rows as List)) {
        final m = Map<String, dynamic>.from(r as Map);
        final content = m['content'];
        Map<String, dynamic>? cMap;
        if (content is Map) {
          cMap = Map<String, dynamic>.from(content);
        }
        final elements = cMap?['elements'] ?? m['elements'];
        if (elements is! List) continue;
        var hit = false;
        for (final e in elements) {
          if (e is! Map) continue;
          final em = Map<String, dynamic>.from(e);
          final es = (em['symbol'] ?? em['formula'] ?? em['elementFormula'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          final en = (em['name'] ?? em['substanceName'] ?? em['label'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          if (es == sym || en == nm || es.contains(sym) || en.contains(nm)) {
            hit = true;
            break;
          }
        }
        if (hit) out.add(m);
      }
      return out;
    } catch (_) {
      return [];
    }
  }

}
