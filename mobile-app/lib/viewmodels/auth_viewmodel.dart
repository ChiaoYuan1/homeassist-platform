import 'package:firebase_auth/firebase_auth.dart';

import '../core/app_enums.dart';
import '../core/input_validators.dart';
import '../models/user_model.dart';
import '../services/app_services.dart';
import 'base_viewmodel.dart';

class AuthViewModel extends BaseViewModel {
  bool get currentUserEmailVerified => AppServices.auth.isEmailVerified;
  String? get currentUserEmail => AppServices.auth.currentUser?.email;

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    setLoading(true);
    clearError();

    try {
      final credential = await AppServices.auth.signIn(
        email: email,
        password: password,
      );

      final profile = await AppServices.user.getUser(credential.user!.uid);
      if (profile == null) {
        await AppServices.auth.signOut();
        setError('This account does not have a HomeAssist profile.');
        return null;
      }

      return profile;
    } on FirebaseAuthException catch (e) {
      setError(_authErrorMessage(e));
      return null;
    } catch (e) {
      setError('Unable to sign in. Please try again.');
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<UserModel?> register({
    required String email,
    required String password,
    required String displayName,
    required String phone,
    required UserRole role,
  }) async {
    setLoading(true);
    clearError();

    User? createdUser;

    try {
      final credential = await AppServices.auth.register(
        email: email,
        password: password,
      );

      createdUser = credential.user;
      if (createdUser == null) {
        throw StateError('Firebase did not return a user account.');
      }

      await AppServices.auth.updateDisplayName(displayName);

      await AppServices.user.createUserProfile(
        uid: createdUser.uid,
        email: email,
        displayName: displayName,
        phone: InputValidators.malaysiaMobileE164(phone),
        role: role,
      );

      await AppServices.auth.sendEmailVerification();

      return await AppServices.user.getUser(createdUser.uid);
    } on FirebaseAuthException catch (e) {
      setError(_authErrorMessage(e));
      return null;
    } catch (e) {
      setError('Unable to create the account. Please try again.');
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> resendVerificationEmail() async {
    setLoading(true);
    clearError();

    try {
      await AppServices.auth.sendEmailVerification();
      return true;
    } on FirebaseAuthException catch (e) {
      setError(_authErrorMessage(e));
      return false;
    } catch (e) {
      setError('Unable to send the verification email.');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> checkEmailVerified() async {
    setLoading(true);
    clearError();

    try {
      return await AppServices.auth.reloadAndCheckEmailVerified();
    } catch (e) {
      setError('Unable to refresh verification status.');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    setLoading(true);
    clearError();

    try {
      await AppServices.auth.sendPasswordResetEmail(email);
      return true;
    } on FirebaseAuthException catch (e) {
      setError(_authErrorMessage(e));
      return false;
    } catch (e) {
      setError('Unable to send the password reset email.');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> signOut() async {
    await AppServices.auth.signOut();
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'The password does not meet the required security rules.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'A network error occurred. Check the internet connection.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
}
