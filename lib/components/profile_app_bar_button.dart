import 'package:flutter/material.dart';
import 'package:scilense_ar_mobile/screens/people%20screens/profile_screen.dart';
import 'package:scilense_ar_mobile/services/auth_service.dart';
import 'package:scilense_ar_mobile/services/classroom_service.dart';
import 'package:scilense_ar_mobile/services/supabase_service.dart';

/// App-bar control that opens [ProfileScreen].
/// When signed in, shows the user's photo; otherwise a person outline icon.
///
/// Set [onlyWhenNoClassroom] to hide the button once the user has joined a class
/// (use People → profile instead).
class ProfileAppBarButton extends StatelessWidget {
  const ProfileAppBarButton({
    super.key,
    this.onlyWhenNoClassroom = false,
    this.onReturned,
  });

  final bool onlyWhenNoClassroom;
  final VoidCallback? onReturned;

  String? _authPhotoUrl() {
    final user = AuthService().currentUser ??
        SupabaseService.client.auth.currentUser;
    if (user == null) return null;
    final meta = user.userMetadata;
    if (meta == null) return null;
    final fromMeta = meta['avatar_url'] ?? meta['picture'] ?? meta['photo_url'];
    if (fromMeta is String && fromMeta.isNotEmpty) return fromMeta;
    return null;
  }

  Widget _avatar(String? photoUrl) {
    final url = photoUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 14,
        backgroundImage: NetworkImage(url),
        onBackgroundImageError: (_, __) {},
        backgroundColor: Colors.black12,
      );
    }
    return Icon(
      AuthService().isSignedIn ? Icons.person : Icons.person_outline,
    );
  }

  Future<void> _open(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
    onReturned?.call();
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().uid ?? SupabaseService.client.auth.currentUser?.id;

    if (uid == null) {
      return IconButton(
        tooltip: 'Sign in',
        onPressed: () => _open(context),
        icon: const Icon(Icons.person_outline),
      );
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: ClassroomService().watchMyProfile(uid),
      builder: (context, snap) {
        final classroomId = snap.data?['classroom_id'] as String?;
        final inClass = classroomId != null && classroomId.isNotEmpty;
        if (onlyWhenNoClassroom && inClass) {
          return const SizedBox.shrink();
        }

        final photo = (snap.data?['photo_url'] as String?)?.trim();
        final resolved =
            (photo != null && photo.isNotEmpty) ? photo : _authPhotoUrl();

        return IconButton(
          tooltip: inClass ? 'Profile' : 'Profile / Join class',
          onPressed: () => _open(context),
          icon: _avatar(resolved),
        );
      },
    );
  }
}
