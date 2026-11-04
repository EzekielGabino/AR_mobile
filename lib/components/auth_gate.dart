import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scilense_ar_mobile/screens/chemistry_screens/chemistry_hub_screen.dart';
import 'package:scilense_ar_mobile/screens/main_screen.dart';
import 'package:scilense_ar_mobile/services/classroom_service.dart';
import 'package:scilense_ar_mobile/services/supabase_service.dart';

/// Session + approved classroom (profiles.classroom_id) → MainScreen.
/// Pending joins are handled under Profile → Join → Waiting (not here).
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

        return StreamBuilder<Map<String, dynamic>?>(
          stream: ClassroomService().watchMyProfile(user.id),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting &&
                !profileSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data = profileSnapshot.data;
            final classroomId = data?['classroom_id'] as String?;
            final hasClassroom =
                classroomId != null && classroomId.isNotEmpty;

            return hasClassroom
                ? MainScreen(classId: classroomId)
                : const ChemistryHubScreen();
          },
        );
      },
    );
  }
}
