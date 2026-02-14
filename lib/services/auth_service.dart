import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(firebaseAuthProvider));
});

class AuthService {
  final FirebaseAuth _auth;
  AuthService(this._auth);

  Future<void> login({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _friendlyAuthError(e);
    }
  }

  // ✅ WEB: Google login
  Future<void> signInWithGoogleWeb() async {
    final provider = GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});

    await _auth.signInWithRedirect(provider);
  }

  Future<void> completeGoogleRedirectIfAny() async {
    try {
      await _auth.getRedirectResult();
    } catch (_) {}
  }

  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _friendlyAuthError(e);
    }
  }

  Future<void> sendResetEmail({required String email}) async {
    try {
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://ramadanhero.my/#/login',
        handleCodeInApp: false,
      );

      await _auth.sendPasswordResetEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_friendlyAuthError(e));
    }
  }

  Future<void> logout() => _auth.signOut();

  String _friendlyAuthError(FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-email' => 'Please enter a valid email address.',
      'user-not-found' => 'No account found for that email.',
      'wrong-password' => 'Incorrect password. Please try again.',
      'invalid-credential' => 'Invalid login credentials.',
      'email-already-in-use' => 'That email is already registered.',
      'weak-password' => 'Password is too weak (min 6 characters).',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      _ => e.message ?? 'Authentication error. Please try again.',
    };
  }
}
