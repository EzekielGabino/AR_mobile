import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:scilense_ar_mobile/components/auth_gate.dart';
import 'package:scilense_ar_mobile/screens/main_screen.dart';
import 'package:scilense_ar_mobile/screens/people%20screens/join_classroom_screen.dart';
import 'package:scilense_ar_mobile/services/auth_service.dart';
import 'package:scilense_ar_mobile/services/classroom_service.dart';
import 'package:scilense_ar_mobile/theme/app_theme.dart';

/// Doubles as two things depending on how it's reached:
/// - Pushed from ChemistryHubScreen/PeopleScreen's profile icon — a
///   normal screen the user can back out of.
/// - Shown directly by AuthGate as the app's root when the student is
///   signed in but hasn't joined a classroom yet — in that case it's
///   the gate itself: account info plus a "Join a Classroom" action,
///   nothing else. A successful join is picked up by AuthGate's own
///   Firestore stream, which swaps the root to MainScreen on its own.
class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        actions: [
          if (auth.currentUser != null)
            IconButton(
              onPressed: () => _handleGoogleSignout(context),
              icon: const Icon(Icons.exit_to_app),
            ),
        ],
      ),
      body: auth.currentUser != null
          ? _SignedInBody(user: auth.currentUser!)
          : Center(
              child: ElevatedButton(
                onPressed: () =>
                    _handleGoogleSignin(context, user: auth.currentUser),
                child: const Text("Sign-in"),
              ),
            ),
    );
  }

  void _handleGoogleSignin(BuildContext ctx, {user}) async {
    try {
      await AuthService().signInWithGoogle();
      if (!ctx.mounted) return;
      Navigator.of(ctx).pop(); // AuthGate has already swapped underneath
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Sign-in failed. Please try again.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(AuthService.getFirebaseErrorMessage(e))),
      );
    }
  }

  void _handleGoogleSignout(BuildContext ctx) async {
    try {
      await AuthService().signOut();
      if (!ctx.mounted) return;
      if (Navigator.of(ctx).canPop()) Navigator.pop(ctx);
    } on FirebaseAuthException catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
    }
  }
}

class _SignedInBody extends StatelessWidget {
  final User user;
  const _SignedInBody({required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ClassroomService().watchMyProfile(user.uid),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final classroomId = data?['classroomId'] as String?;
        final classroomName = data?['classroomName'] as String?;
        final classroomCode = data?['classroomAccessCode'] as String?;
        final inClassroom = classroomId != null && classroomId.isNotEmpty;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _AccountCard(user: user),
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
      await ClassroomService().leaveClassroom();
      // Collapses any pushed screens back to the (now-restricted) root
      // AuthGate is showing, instead of leaving a stale pushed
      // ProfileScreen sitting on top of it.
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }
}

class _AccountCard extends StatelessWidget {
  final User user;
  const _AccountCard({required this.user});

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
              backgroundImage: user.photoURL != null
                  ? NetworkImage(user.photoURL!)
                  : null,
              child: user.photoURL == null
                  ? const Icon(Icons.person, color: AppColors.primary, size: 28)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? 'Student',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (user.email != null)
                    Text(
                      user.email!,
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
    return Card(
      color: AppColors.primaryDark,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.qr_code_scanner, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            const Text(
              'Join Your Classroom',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Scan your teacher's QR code or enter the class code to "
              'unlock experiments, quizzes, and equipment tracking.',
              style: TextStyle(
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
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const JoinClassroomScreen(),
                    ),
                  );
                  // AuthGate's stream already swaps to MainScreen once
                  // Firestore reflects the join — just clear the stack
                  // of anything pushed on top of it (this ProfileScreen,
                  // the scanner) so the user lands cleanly.
                  if (result != null && context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan QR / Enter Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.school, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (code.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Code: $code',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onLeave,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                ),
                child: const Text('Leave Classroom'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
