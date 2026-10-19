import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/screens/chemistry_screens/chemistry_hub_screen.dart';
import 'package:scilense_ar_mobile/screens/main_screen.dart';
import 'package:scilense_ar_mobile/services/classroom_service.dart';

/// Two real states now, not three:
/// - No classroom (whether or not signed in) -> ChemistryHubScreen. It
///   already gates "Sample Experiments" behind auth.currentUser on its
///   own, so a signed-in student without a class sees the same hub an
///   anonymous visitor does, just with a profile icon that lets them
///   sign in / join a classroom. ProfileScreen is reached FROM here,
///   never forced as the root — signing in should never take features
///   away.
/// - Signed in AND enrolled in a classroom -> MainScreen, the full app.
///   Leaving the classroom clears the Firestore field this gate
///   watches, dropping the student back to ChemistryHubScreen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          return ChemistryHubScreen();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: ClassroomService().watchMyProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final classroomId =
                profileSnapshot.data?.data()?['classroomId'] as String?;
            final hasClassroom = classroomId != null && classroomId.isNotEmpty;

            return hasClassroom
                ? MainScreen(classId: classroomId)
                : ChemistryHubScreen();
          },
        );
      },
    );
  }
}
