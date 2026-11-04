import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scilense_ar_mobile/screens/people%20screens/join_classroom_screen.dart';
import 'package:scilense_ar_mobile/screens/people%20screens/pending_approval_screen.dart';
import 'package:scilense_ar_mobile/services/auth_service.dart';
import 'package:scilense_ar_mobile/services/classroom_service.dart';
import 'package:scilense_ar_mobile/services/supabase_service.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

/// Profile / sign-in. Auth is Supabase (M2 Part A).
/// Classroom join still uses ClassroomService (Firebase until M3).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SupabaseService.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user = snapshot.data?.session?.user ??
            AuthService().currentUser ??
            SupabaseService.client.auth.currentUser;

        return Scaffold(
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
              : _SignedOutBody(
                  onSignIn: () => _handleGoogleSignIn(context),
                ),
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
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(AuthService.getErrorMessage(e))),
      );
    }
  }

  static void _handleSignOut(BuildContext ctx) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to join a class and submit activities.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
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
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(AuthService.getErrorMessage(e))),
      );
    }
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
              Image.asset(
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
              const SizedBox(height: 16),
              const Text(
                'ScilenseAR',
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
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Sign in with Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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

        final displayName = data?['display_name'] as String? ??
            user.userMetadata?['full_name'] as String? ??
            user.userMetadata?['name'] as String? ??
            user.email ??
            'Student';
        final photoUrl = data?['photo_url'] as String? ??
            user.userMetadata?['avatar_url'] as String?;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _AccountCard(
              displayName: displayName,
              email: user.email,
              photoUrl: photoUrl,
            ),
            const SizedBox(height: 20),
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
        title: const Text('Leave classroom?'),
        content: const Text(
          "You'll lose access to this class's activities until you "
          'rejoin with its code or QR.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
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
        await SupabaseService.client.from('profiles').update({
          'classroom_id': null,
          'classroom_name': null,
          'classroom_access_code': null,
          'classroom_joined_at': null,
        }).eq('id', user.id);
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

  const _AccountCard({
    required this.displayName,
    this.email,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
              backgroundImage:
                  photoUrl != null ? NetworkImage(photoUrl!) : null,
              child: photoUrl == null
                  ? const Icon(Icons.person, color: AppColors.primary, size: 28)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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

class _JoinClassroomCard extends StatelessWidget {
  const _JoinClassroomCard();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: ClassroomService().fetchMyPendingMembership(),
      builder: (context, snap) {
        final pending = snap.data;
        final hasPending = pending != null;
        String? classId;
        String? section;
        String? code;
        if (hasPending) {
          classId = pending['class_id'] as String?;
          final classes = pending['classes'];
          if (classes is Map) {
            section = classes['section_name'] as String?;
            code = classes['access_code'] as String?;
          }
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.headerGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                hasPending ? Icons.hourglass_top : Icons.qr_code_scanner,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                hasPending ? 'Join request pending' : 'Join Your Classroom',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hasPending
                    ? 'Your teacher has not approved this class yet. You can open the waiting screen anytime.'
                    : "Scan your teacher's QR code or enter the class code to "
                        'unlock experiments, quizzes, and equipment tracking.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (hasPending && classId != null && classId.isNotEmpty) {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PendingApprovalScreen(
                            classId: classId!,
                            sectionName: section,
                            accessCode: code,
                          ),
                        ),
                      );
                      // Rebuild card after returning (cancel / still pending)
                      if (context.mounted) {
                        (context as Element).markNeedsBuild();
                      }
                      return;
                    }
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const JoinClassroomScreen(),
                      ),
                    );
                    if (context.mounted) {
                      (context as Element).markNeedsBuild();
                    }
                  },
                  icon: Icon(hasPending ? Icons.hourglass_top : Icons.login),
                  label: Text(
                    hasPending ? 'View waiting status' : 'Join with code or QR',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (code.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Code: $code',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: onLeave,
              child: const Text('Leave classroom'),
            ),
          ],
        ),
      ),
    );
  }
}
