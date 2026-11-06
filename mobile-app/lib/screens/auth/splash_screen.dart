import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/app_enums.dart';
import '../../services/app_services.dart';
import 'login_screen.dart';
import 'role_router.dart';
import 'verify_email_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _route();
    });
  }

  Future<void> _route() async {
    if (_hasNavigated) {
      return;
    }

    try {
      final firebaseUser =
          AppServices.auth.currentUser;

      if (firebaseUser == null) {
        _go(
          const LoginScreen(),
        );
        return;
      }

      await firebaseUser.reload();

      final refreshedUser =
          AppServices.auth.currentUser;

      if (refreshedUser == null) {
        _go(
          const LoginScreen(),
        );
        return;
      }

      final user =
      await AppServices.user.getUser(
        refreshedUser.uid,
      );

      if (
      !mounted ||
          _hasNavigated
      ) {
        return;
      }

      if (user == null) {
        _go(
          const LoginScreen(),
        );
        return;
      }

      if (
      user.role != UserRole.admin &&
          !refreshedUser.emailVerified
      ) {
        _go(
          const VerifyEmailScreen(),
        );
        return;
      }

      _go(
        destinationForUser(
          user,
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (
      error.code ==
          'invalid-user-token' ||
          error.code ==
              'user-token-expired' ||
          error.code ==
              'user-disabled'
      ) {
        await AppServices.auth.signOut();

        if (!mounted) {
          return;
        }

        _go(
          const LoginScreen(),
        );

        return;
      }

      rethrow;
    } catch (error) {
      await AppServices.auth.signOut();

      if (!mounted) {
        return;
      }

      _go(
        const LoginScreen(),
      );
    }
  }

  void _go(Widget page) {
    if (!mounted || _hasNavigated) {
      return;
    }

    _hasNavigated = true;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}