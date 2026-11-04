import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:scilense_ar_mobile/services/supabase_service.dart';

/// Student Auth via Supabase (mobile M2 Part A).
/// Classroom join still uses legacy paths until M3.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  /// Web client ID (same OAuth client as teacher web / Firebase Google).
  static const _webClientId =
      '620830034182-m1pru269cj1jbh3auaai2rqgnooll7pp.apps.googleusercontent.com';

  SupabaseClient get _client => SupabaseService.client;

  User? get currentUser => _client.auth.currentUser;

  bool get isSignedIn => currentUser != null;

  String? get uid => currentUser?.id;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> initialize() async {
    await _googleSignIn.initialize(serverClientId: _webClientId);
  }

  // ---------------------------------------------------------------------------
  // Email / password
  // ---------------------------------------------------------------------------

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final res = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName?.trim() ?? '',
        'name': fullName?.trim() ?? '',
        'role': 'student',
      },
    );
    final user = res.user;
    if (user != null) {
      await ensureStudentProfile(user);
    }
    return res;
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = res.user;
    if (user != null) {
      await ensureStudentProfile(user);
    }
    return res;
  }

  // ---------------------------------------------------------------------------
  // Google
  // ---------------------------------------------------------------------------

  Future<AuthResponse> signInWithGoogle() async {
    await _googleSignIn.signOut();

    final googleUser = await _googleSignIn.authenticate(scopeHint: ['email']);
    final googleAuth = googleUser.authentication;

    final authorization = await _googleSignIn.authorizationClient
        .authorizationForScopes(['email', 'profile']);

    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw AuthException('Google sign-in failed: missing ID token.');
    }

    final res = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: authorization?.accessToken,
    );

    final user = res.user;
    if (user != null) {
      await ensureStudentProfile(user);
    }
    return res;
  }

  // ---------------------------------------------------------------------------
  // Profile (public.profiles)
  // ---------------------------------------------------------------------------

  /// Ensures a profiles row exists for mobile use.
  /// Throws [AuthException] if this account is a teacher (web-only).
  Future<void> ensureStudentProfile(User user) async {
    final meta = user.userMetadata ?? {};
    final name = (meta['full_name'] as String?)?.trim().isNotEmpty == true
        ? meta['full_name'] as String
        : (meta['name'] as String?)?.trim().isNotEmpty == true
        ? meta['name'] as String
        : (user.email ?? 'Student');

    final photo = meta['avatar_url'] as String? ?? meta['picture'] as String?;

    // Load existing role first — do not demote teachers to student
    Map<String, dynamic>? existing;
    try {
      final row = await _client
          .from('profiles')
          .select('id, role')
          .eq('id', user.id)
          .maybeSingle();
      if (row != null) {
        existing = Map<String, dynamic>.from(row as Map);
      }
    } catch (_) {}

    final existingRole =
        (existing?['role'] as String?)?.trim().toLowerCase() ?? '';

    if (existingRole == 'teacher' || existingRole == 'educator') {
      await signOut();
      throw AuthException(
        'This account is registered as a teacher. '
        'Please use the SciLens AR teacher website, not the student app.',
      );
    }

    // New or student profile — force student role (trigger may have defaulted wrong before 015)
    await _client.from('profiles').upsert({
      'id': user.id,
      'email': user.email,
      'display_name': name,
      'photo_url': photo,
      'role': 'student',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _client.auth.signOut();
  }

  /// Human-readable Auth errors (Supabase + Google).
  static String getErrorMessage(Object e) {
    if (e is AuthException) {
      final m = e.message.toLowerCase();
      if (m.contains('invalid login') || m.contains('invalid credentials')) {
        return 'Invalid email or password.';
      }
      if (m.contains('already registered') || m.contains('already exists')) {
        return 'An account with this email already exists.';
      }
      if (m.contains('network')) {
        return 'No internet connection.';
      }
      return e.message;
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  /// @Deprecated — kept so older call sites compile during migration.
  static String getFirebaseErrorMessage(Object e) => getErrorMessage(e);
}
