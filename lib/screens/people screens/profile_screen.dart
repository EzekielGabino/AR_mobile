import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scilense_ar_mobile/components/auth_gate.dart';
import 'package:scilense_ar_mobile/screens/people%20screens/join_classroom_screen.dart';
import 'package:scilense_ar_mobile/screens/people%20screens/pending_approval_screen.dart';
import 'package:scilense_ar_mobile/services/auth_service.dart';
import 'package:scilense_ar_mobile/services/classroom_service.dart';
import 'package:scilense_ar_mobile/services/supabase_service.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

// Design-system palette (file-private so it cannot clash with AppColors in app_theme.dart)
const Color _navy = Color(0xFF091540);
const Color _royalBlue = Color(0xFF1B2CC1);
const Color _periwinkle = Color(0xFF7692FF);
const Color _lightBlue = Color(0xFFABD2FA);

/// Profile / sign-in. Auth is Supabase (M2 Part A).
/// Classroom join still uses ClassroomService (Firebase until M3).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SupabaseService.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user =
            snapshot.data?.session?.user ??
            AuthService().currentUser ??
            SupabaseService.client.auth.currentUser;

        return Scaffold(
          // Explicit theme background (same as AppTheme.scaffoldBackgroundColor)
          backgroundColor: AppColors.background,
          // AppBar kept exactly as the ORIGINAL (uses the app theme's AppBar style)
          appBar: AppBar(
            title: const Text("Profile"),
            centerTitle: true,
            actions: [
              if (user != null)
                IconButton(
                  onPressed: () => _handleSignOut(context),
                  icon: const Icon(Icons.exit_to_app),
                ),
            ],
          ),
          body: user != null
              ? _SignedInBody(user: user)
              : _SignedOutBody(onSignIn: () => _handleGoogleSignIn(context)),
        );
      },
    );
  }

  static void _handleGoogleSignIn(BuildContext ctx) async {
    try {
      await AuthService().signInWithGoogle();
      // Stay on profile — StreamBuilder rebuilds into signed-in body.
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Sign-in failed. Please try again.')),
      );
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(SnackBar(content: Text(AuthService.getErrorMessage(e))));
    }
  }

  static void _handleSignOut(BuildContext ctx) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        // Visual only: white dialog, 16 px radius, navy title
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign out?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'You will need to sign in again to join a class and submit activities.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(foregroundColor: _royalBlue),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!ctx.mounted) return;
    try {
      await AuthService().signOut();
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(SnackBar(content: Text(AuthService.getErrorMessage(e))));
    }
  }
}

/// Visual-only button wrapper: gradient + glow around a normal ElevatedButton.
/// The onPressed callback is passed straight through.
class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.onPressed, required this.label});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [_royalBlue, _periwinkle],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _royalBlue.withValues(alpha: 0.30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Signed-out: app mark + name, then Google sign-in.
class _SignedOutBody extends StatelessWidget {
  const _SignedOutBody({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Soft glow behind the app mark (decorative)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _lightBlue.withValues(alpha: 0.8)),
                  boxShadow: [
                    BoxShadow(
                      color: _periwinkle.withValues(alpha: 0.30),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/branding/app_icon.png',
                  width: 112,
                  height: 112,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.science_outlined,
                    size: 96,
                    color: AppColors.primary.withValues(alpha: 0.85),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'ScilensAR',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to join a class and track lab activities.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: _GradientButton(
                  onPressed: onSignIn,
                  label: 'Sign in with Google',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignedInBody extends StatelessWidget {
  final User user;
  const _SignedInBody({required this.user});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadProfile(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final classroomId = data?['classroom_id'] as String?;
        final classroomName = data?['classroom_name'] as String?;
        final classroomCode = data?['classroom_access_code'] as String?;
        final inClassroom = classroomId != null && classroomId.isNotEmpty;

        final displayName =
            data?['display_name'] as String? ??
            user.userMetadata?['full_name'] as String? ??
            user.userMetadata?['name'] as String? ??
            user.email ??
            'Student';
        final photoUrl =
            data?['photo_url'] as String? ??
            user.userMetadata?['avatar_url'] as String?;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _AccountCard(
              displayName: displayName,
              email: user.email,
              photoUrl: photoUrl,
            ),
            const SizedBox(height: 24),
            inClassroom
                ? _ClassroomCard(
                    name: classroomName ?? 'Your Classroom',
                    code: classroomCode ?? '',
                    onLeave: () => _confirmLeave(context),
                  )
                : const _JoinClassroomCard(),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _loadProfile() async {
    try {
      return await SupabaseService.client
          .from('profiles')
          .select(
            'classroom_id, classroom_name, classroom_access_code, display_name, photo_url',
          )
          .eq('id', user.id)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  void _confirmLeave(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        // Visual only: white dialog, 16 px radius, navy title
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Leave classroom?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          "You'll lose access to this class's activities until you "
          'rejoin with its code or QR.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(foregroundColor: _royalBlue),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // leaveClassroom still Firebase until M3 — call if it doesn't throw hard
      try {
        await ClassroomService().leaveClassroom();
      } catch (_) {}
      try {
        await SupabaseService.client
            .from('profiles')
            .update({
              'classroom_id': null,
              'classroom_name': null,
              'classroom_access_code': null,
              'classroom_joined_at': null,
            })
            .eq('id', user.id);
      } catch (_) {}
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }
}

class _AccountCard extends StatelessWidget {
  final String displayName;
  final String? email;
  final String? photoUrl;

  const _AccountCard({required this.displayName, this.email, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      // Visual only: white card, periwinkle glow, thin light-blue border, 16 px radius
      color: Colors.white,
      elevation: 4,
      shadowColor: _periwinkle.withValues(alpha: 0.30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _lightBlue.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Gradient ring around the avatar (decorative)
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_royalBlue, _periwinkle],
                ),
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: _lightBlue.withValues(alpha: 0.35),
                backgroundImage: photoUrl != null
                    ? NetworkImage(photoUrl!)
                    : null,
                child: photoUrl == null
                    ? const Icon(Icons.person, color: _royalBlue, size: 28)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (email != null)
                    Text(
                      email!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinClassroomCard extends StatefulWidget {
  const _JoinClassroomCard();

  @override
  State<_JoinClassroomCard> createState() => _JoinClassroomCardState();
}

class _JoinClassroomCardState extends State<_JoinClassroomCard> {
  Map<String, dynamic>? _pending;
  bool _loading = true;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _refresh();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final pending = await ClassroomService().fetchMyPendingMembership();
      // Approved while sitting on profile (no classroom on profile yet)
      final user = AuthService().currentUser;
      if (user != null) {
        final rows = await SupabaseService.client
            .from('class_members')
            .select('class_id, status')
            .eq('user_id', user.id)
            .eq('status', 'approved')
            .limit(1);
        final list = rows as List;
        if (list.isNotEmpty) {
          final classId = (list.first as Map)['class_id']?.toString();
          if (classId != null && classId.isNotEmpty && mounted) {
            await _activateAndGo(classId);
            return;
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _pending = pending;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _activateAndGo(String classId) async {
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
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (_) => false,
      );
    } catch (_) {}
  }

  Future<void> _openWaitingOrJoin() async {
    final pending = _pending;
    if (pending != null) {
      final classId = pending['class_id'] as String?;
      String? section;
      String? code;
      final classes = pending['classes'];
      if (classes is Map) {
        section = classes['section_name'] as String?;
        code = classes['access_code'] as String?;
      }
      if (classId != null && classId.isNotEmpty) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PendingApprovalScreen(
              classId: classId,
              sectionName: section,
              accessCode: code,
            ),
          ),
        );
        await _refresh();
        return;
      }
    }
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const JoinClassroomScreen()));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final hasPending = _pending != null;
    String? section;
    String? code;
    if (hasPending) {
      final classes = _pending!['classes'];
      if (classes is Map) {
        section = classes['section_name'] as String?;
        code = classes['access_code'] as String?;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _periwinkle.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _lightBlue.withValues(alpha: 0.5)),
            ),
            child: Icon(
              hasPending ? Icons.hourglass_top : Icons.qr_code_scanner,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasPending ? 'Waiting for approval' : 'Join a classroom',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasPending
                ? 'Your request${section != null && section.isNotEmpty ? ' for "$section"' : ''} is pending. Open status to wait, or stay here — this screen updates when your teacher approves.'
                : 'Scan your teacher\'s QR code or enter the class access code.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (hasPending && (code?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            Text(
              'Code: $code',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _openWaitingOrJoin,
              icon: Icon(hasPending ? Icons.hourglass_top : Icons.login),
              label: Text(
                hasPending ? 'View waiting status' : 'Join with code or QR',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryDark,
                elevation: 0,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassroomCard extends StatelessWidget {
  final String name;
  final String code;
  final VoidCallback onLeave;

  const _ClassroomCard({
    required this.name,
    required this.code,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      // Visual only: white card, periwinkle glow, thin light-blue border, 16 px radius
      color: Colors.white,
      elevation: 4,
      shadowColor: _periwinkle.withValues(alpha: 0.30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _lightBlue.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Gradient icon chip (decorative)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_royalBlue, _periwinkle],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            if (code.isNotEmpty) ...[
              const SizedBox(height: 8),
              // Monospace code on a light-blue chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _lightBlue.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Code: '),
                      TextSpan(
                        text: code,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          color: _royalBlue,
                        ),
                      ),
                    ],
                  ),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: onLeave,
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Leave classroom'),
            ),
          ],
        ),
      ),
    );
  }
}
