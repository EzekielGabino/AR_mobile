import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/components/auth_gate.dart';
import 'package:scilense_ar_mobile/services/auth_service.dart';
import 'package:scilense_ar_mobile/services/classroom_service.dart';
import 'package:scilense_ar_mobile/services/supabase_service.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

/// Shown while class_members.status is pending for this student.
class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({
    super.key,
    required this.classId,
    this.sectionName,
    this.accessCode,
  });

  final String classId;
  final String? sectionName;
  final String? accessCode;

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  StreamSubscription? _sub;
  bool _cancelling = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _listen() {
    final uid = AuthService().currentUser?.id;
    if (uid == null) return;

    _sub = SupabaseService.client
        .from('class_members')
        .stream(primaryKey: ['class_id', 'user_id'])
        .eq('user_id', uid)
        .listen((rows) async {
      Map<String, dynamic>? mine;
      for (final r in rows) {
        final m = Map<String, dynamic>.from(r);
        if (m['class_id'] == widget.classId) {
          mine = m;
          break;
        }
      }
      if (mine == null || !mounted) return;
      final status = mine['status'] as String? ?? '';
      if (status == 'approved') {
        await _onApproved();
      } else if (status == 'rejected') {
        setState(() {
          _statusMessage =
              'Your request was declined. You can cancel and try another code.';
        });
      }
    });
  }

  Future<void> _onApproved() async {
    final rows = await SupabaseService.client
        .from('classes')
        .select('id, section_name, grade_level, subject, access_code, teacher_id')
        .eq('id', widget.classId)
        .limit(1);
    final list = rows as List;
    if (list.isEmpty) return;
    final row = Map<String, dynamic>.from(list.first as Map);
    final info = ClassroomInfo(
      id: row['id'] as String,
      sectionName: row['section_name'] as String? ?? widget.sectionName ?? '',
      gradeLevel: row['grade_level'] as String? ?? '',
      subject: row['subject'] as String? ?? '',
      accessCode: row['access_code'] as String? ?? widget.accessCode ?? '',
      teacherUid: row['teacher_id'] as String? ?? '',
      membershipStatus: 'approved',
    );
    await ClassroomService().activateApprovedClassroom(info);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (_) => false,
    );
  }

  Future<void> _cancel() async {
    setState(() => _cancelling = true);
    try {
      await ClassroomService().cancelJoinRequest(widget.classId);
      if (!mounted) return;
      // Return to profile (join stack)
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not cancel: $e')),
      );
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.sectionName?.isNotEmpty == true
        ? widget.sectionName!
        : 'Classroom';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Waiting for approval'),
        // Back → Profile (or previous route in the join stack)
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_top, size: 64, color: AppColors.primary),
            const SizedBox(height: 20),
            Text(
              'Request sent',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your teacher needs to approve your join request for “$title” before you can open the class.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _statusMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.safetyRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 28),
            const CircularProgressIndicator(),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _cancelling ? null : _cancel,
                child: Text(_cancelling ? 'Cancelling…' : 'Cancel request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
