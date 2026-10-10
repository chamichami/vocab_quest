import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'user_service.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static Future<void> signUp({
    required String username,
    required String email,
    required String password,
    String? photoUrl,
  }) async {
    if (!await UserService.isUsernameFree(username)) {
      throw const AuthException('That username is already taken.');
    }

    final UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }

    final user = cred.user!;
    try {
      await user.updateDisplayName(username.trim());
      if (photoUrl != null) await user.updatePhotoURL(photoUrl);
      await UserService.createProfile(
        user: user,
        username: username,
        photoUrl: photoUrl,
      );
    } on UsernameTakenException {
      await user.delete();
      throw const AuthException('That username was just taken. Try another.');
    } catch (_) {
      await user.delete();
      throw const AuthException('Could not create your profile. Try again.');
    }
  }

  static Future<void> signIn(String identifier, String password) async {
    var email = identifier.trim();
    if (!email.contains('@')) {
      final snap = await UserService.nameDoc(UserService.normalize(email))
          .get();
      if (!snap.exists)
        throw const AuthException('No account with that username.');
      email = snap.data()!['email'] as String;
    }
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }
  }

  static Future<void> signInWithGoogle() async {
    try {
      final UserCredential cred;
      if (kIsWeb) {
        cred = await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        cred = await _auth.signInWithProvider(GoogleAuthProvider());
      }
      await UserService.ensureProfile(cred.user!);
    } on FirebaseAuthException catch (e) {
      const cancelled = {
        'canceled',
        'web-context-canceled',
        'popup-closed-by-user',
        'cancelled-popup-request',
      };
      if (cancelled.contains(e.code)) return;
      throw AuthException(_message(e));
    }
  }

  static Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e));
    }
  }

  static Future<void> signOut() => _auth.signOut();

  static String _message(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks wrong.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong username/email or password.';
      case 'email-already-in-use':
        return 'An account with that email already exists.';
      case 'weak-password':
        return 'Password is too weak (use at least 6 characters).';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a few minutes.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase yet.';
      default:
        return e.message ?? 'Something went wrong (${e.code}).';
    }
  }
}
