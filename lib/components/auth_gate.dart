import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scilense_ar_mobile/screens/chemistry_screens/chemistry_hub_screen.dart';
import 'package:scilense_ar_mobile/screens/main_screen.dart';
import 'package:scilense_ar_mobile/services/classroom_service.dart';
import 'package:scilense_ar_mobile/services/supabase_service.dart';

/// Session + approved classroom (profiles.classroom_id) → MainScreen.
/// Also watches class_members so approval while on Chemistry Hub / Profile
/// activates the classroom without requiring the Waiting screen to be open.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SupabaseService.client.auth.onAuthStateChange,
      builder: (context, authSnapshot) {
        final session = authSnapshot.data?.session ??
            SupabaseService.client.auth.currentSession;
        final user = session?.user;

        if (user == null) {
          return const ChemistryHubScreen();
        }

        return _SignedInShell(userId: user.id);
      },
    );
  }
}

class _SignedInShell extends StatefulWidget {
  const _SignedInShell({required this.userId});

  final String userId;

  @override
  State<_SignedInShell> createState() => _SignedInShellState();
}

class _SignedInShellState extends State<_SignedInShell> {
  StreamSubscription? _membershipSub;
  Timer? _pollTimer;
  bool _activating = false;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _listenMemberships();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _checkMembershipOnce();
      _loadProfile();
    });
  }

  @override
  void dispose() {
    _membershipSub?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final data = await ClassroomService().fetchMyProfile(widget.userId);
    if (!mounted) return;
    setState(() => _profile = data);
  }

  void _listenMemberships() {
    try {
      _membershipSub = ClassroomService().watchMyMemberships().listen((row) {
        if (row == null) return;
        final status = (row['status'] as String?)?.toLowerCase() ?? '';
        if (status == 'approved') {
          final classId = row['class_id']?.toString();
          if (classId != null && classId.isNotEmpty) {
            _activateIfNeeded(classId);
          }
        }
      });
    } catch (_) {
      // Polling still runs
    }
  }

  Future<void> _checkMembershipOnce() async {
    final classroomId = _profile?['classroom_id'] as String?;
    if (classroomId != null && classroomId.isNotEmpty) return;
    if (_activating) return;
    try {
      final pending = await ClassroomService().fetchMyPendingMembership();
      // Also check any approved row even if profile not updated yet
      final rows = await SupabaseService.client
          .from('class_members')
          .select('class_id, status')
          .eq('user_id', widget.userId)
          .eq('status', 'approved')
          .limit(1);
      final list = rows as List;
      if (list.isNotEmpty) {
        final classId = (list.first as Map)['class_id']?.toString();
        if (classId != null && classId.isNotEmpty) {
          await _activateIfNeeded(classId);
        }
      }
      // Keep pending reference so UI elsewhere can refresh; no-op here
      pending;
    } catch (_) {}
  }

  Future<void> _activateIfNeeded(String classId) async {
    if (_activating) return;
    final existing = _profile?['classroom_id'] as String?;
    if (existing != null && existing.isNotEmpty) return;
    _activating = true;
    try {
      final rows = await SupabaseService.client
          .from('classes')
          .select(
            'id, section_name, grade_level, subject, access_code, teacher_id',
          )
          .eq('id', classId)
          .limit(1);
      final list = rows as List;
      if (list.isEmpty) return;
      final row = Map<String, dynamic>.from(list.first as Map);
      final info = ClassroomInfo(
        id: row['id'] as String,
        sectionName: row['section_name'] as String? ?? '',
        gradeLevel: row['grade_level'] as String? ?? '',
        subject: row['subject'] as String? ?? '',
        accessCode: row['access_code'] as String? ?? '',
        teacherUid: row['teacher_id'] as String? ?? '',
        membershipStatus: 'approved',
      );
      await ClassroomService().activateApprovedClassroom(info);
      await _loadProfile();
    } catch (_) {
    } finally {
      _activating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final classroomId = _profile?['classroom_id'] as String?;
    final hasClassroom = classroomId != null && classroomId.isNotEmpty;

    if (_profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return hasClassroom
        ? MainScreen(classId: classroomId)
        : const ChemistryHubScreen();
  }
}
