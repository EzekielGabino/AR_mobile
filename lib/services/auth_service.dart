import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static const _webClientId =
      '620830034182-m1pru269cj1jbh3auaai2rqgnooll7pp.apps.googleusercontent.com';

  static String getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'account-exists-with-different-credential':
        return 'An account with this email already exists with a different sign-in method.';
      case 'invalid-credential':
        return 'Sign-in failed. Please try again.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;

  Future<void> initialize() async {
    await _googleSignIn.initialize(serverClientId: _webClientId);
  }

  Future<UserCredential> signInWithGoogle() async {
    await _googleSignIn.signOut();

    final googleUser = await _googleSignIn.authenticate(scopeHint: ['email']);
    final googleAuth = googleUser.authentication;

    final authorization = await _googleSignIn.authorizationClient
        .authorizationForScopes(['email', 'profile']);

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: authorization?.accessToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      await createStudentProfile(userCredential.user!);
    }

    return userCredential;
  }

  Future<void> createStudentProfile(User user) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fullName': user.displayName ?? '',
      'email': user.email ?? '',
      'photoUrl': user.photoURL,
      'role': 'student',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }
}
