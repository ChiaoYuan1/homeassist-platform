import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  String requireUserId() {
    final uid = currentUserId;
    if (uid == null) {
      throw StateError('No authenticated user is available.');
    }
    return uid;
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> register({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user is available.');
    }

    await user.updateDisplayName(displayName.trim());
    await user.reload();
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user is available.');
    }

    if (!user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<bool> reloadAndCheckEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }

    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError(
        'No signed-in user was found.',
      );
    }

    final email = user.email;

    if (email == null || email.isEmpty) {
      throw StateError(
        'This account does not have an email address.',
      );
    }

    try {
      final credential =
      EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(
        credential,
      );

      await user.updatePassword(
        newPassword,
      );
    } on FirebaseAuthException catch (error) {
      switch (error.code) {
        case 'wrong-password':
        case 'invalid-credential':
          throw StateError(
            'The current password is incorrect.',
          );

        case 'weak-password':
          throw StateError(
            'The new password does not meet the password requirements.',
          );

        case 'requires-recent-login':
          throw StateError(
            'Please sign in again before changing your password.',
          );

        case 'too-many-requests':
          throw StateError(
            'Too many attempts. Please try again later.',
          );

        default:
          throw StateError(
            error.message ??
                'Unable to change the password.',
          );
      }
    }
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  Future<void> signOut() => _auth.signOut();
}
