
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/input_validators.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import 'technician_verify_email_screen.dart';

class TechnicianActivationScreen extends StatefulWidget {
  const TechnicianActivationScreen({super.key});

  @override
  State<TechnicianActivationScreen> createState() =>
      _TechnicianActivationScreenState();
}

class _TechnicianActivationScreenState
    extends State<TechnicianActivationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;

  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // =====================================================
  // CHECK TECHNICIAN INVITATION
  // =====================================================

  Future<void> _requireTechnicianInvitation({
    required String email,
    required String uid,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    // Uses the existing collection-group index.
    // No Cloud Function is required.
    final snapshot = await FirebaseFirestore.instance
        .collectionGroup('technicians')
        .where(
      'workEmailNormalized',
      isEqualTo: normalizedEmail,
    )
        .limit(2)
        .get();

    if (snapshot.docs.isEmpty) {
      throw StateError(
        'Technician Invitation Not Found\n\n'
            'This email address is not registered as an invited '
            'technician in HomeAssist. Please check the work '
            'email provided by your service provider or '
            'contact them for assistance.',
      );
    }

    if (snapshot.docs.length > 1) {
      throw StateError(
        'Multiple technician invitations were found '
            'for this email address. Please contact your '
            'service provider.',
      );
    }

    final technician = snapshot.docs.first.data();

    final invitedEmail =
    (technician['workEmailNormalized'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    if (invitedEmail != normalizedEmail) {
      throw StateError(
        'The technician invitation does not match '
            'this email address.',
      );
    }

    if (technician['active'] != true) {
      throw StateError(
        'This technician invitation is currently '
            'inactive. Please contact your service provider.',
      );
    }

    final accountStatus =
    (technician['accountStatus'] ?? 'pending')
        .toString()
        .trim()
        .toLowerCase();

    final linkedUid =
    (technician['authUid'] ?? '')
        .toString()
        .trim();

    // Support resuming an activation that was already
    // linked to the same Firebase account.
    if (accountStatus == 'active' && linkedUid == uid) {
      return;
    }

    if (linkedUid.isNotEmpty || accountStatus == 'active') {
      throw StateError(
        'This technician invitation has already been '
            'activated. Please sign in to your existing account.',
      );
    }

    if (accountStatus != 'pending') {
      throw StateError(
        'This technician invitation is not currently '
            'available for activation. Please contact '
            'your service provider.',
      );
    }
  }

  // =====================================================
  // TECHNICIAN ACCOUNT ACTIVATION
  // =====================================================

  Future<void> _activate() async {
    if (_loading || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    User? accountUsed;

    bool createdNewAccount = false;
    bool signedInExistingAccount = false;
    bool invitationConfirmed = false;

    try {
      // Step 1: Register or resume a previously
      // created Firebase Authentication account.
      try {
        await _authService.register(
          email: email,
          password: password,
        );

        createdNewAccount = true;
        accountUsed = FirebaseAuth.instance.currentUser;
      } on FirebaseAuthException catch (error) {
        if (error.code != 'email-already-in-use') {
          rethrow;
        }

        // Existing accounts must not be deleted.
        // A previous incomplete activation may be resumed
        // using its original password.
        final credential = await _authService.signIn(
          email: email,
          password: password,
        );

        accountUsed = credential.user;
        signedInExistingAccount = true;

        if (accountUsed == null) {
          throw StateError(
            'Unable to access the existing account.',
          );
        }

        final existingProfile = await UserService()
            .getUser(accountUsed.uid);

        if (existingProfile != null) {
          throw StateError(
            'This email already belongs to an existing '
                'HomeAssist account. Please sign in instead.',
          );
        }
      }

      final user = accountUsed;

      if (user == null) {
        throw StateError(
          'Unable to create or access the technician account.',
        );
      }

      if (user.email?.trim().toLowerCase() != email) {
        throw StateError(
          'The signed-in email does not match '
              'the technician registration email.',
        );
      }

      // Step 2: Check the invitation BEFORE
      // sending any verification email.
      await _requireTechnicianInvitation(
        email: email,
        uid: user.uid,
      );

      invitationConfirmed = true;

      // Step 3: Only eligible invitations proceed
      // to email verification.
      if (!user.emailVerified) {
        await _authService.sendEmailVerification();
      }

      if (!mounted) {
        return;
      }

      // Step 4: Continue to the existing
      // email verification screen.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => TechnicianVerifyEmailScreen(
            email: email,
          ),
        ),
            (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        if (error.code == 'wrong-password' ||
            error.code == 'invalid-credential' ||
            error.code == 'invalid-login-credentials') {
          _errorMessage =
          'An account already exists for this email. '
              'Please enter the password previously '
              'used for this account.';
        } else {
          _errorMessage =
              error.message ??
                  'Unable to activate the technician account.';
        }
      });
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        if (error.code == 'permission-denied') {
          _errorMessage =
          'Unable to check technician invitations '
              'due to database permissions. '
              'Please contact the administrator.';
        } else {
          _errorMessage =
          'Unable to check the technician invitation. '
              'Please check your connection and try again.';
        }
      });
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
        'Unable to activate the technician account. '
            'Please try again.';
      });
    } finally {
      // Step 5: Clean up an authentication session
      // when invitation validation did not succeed.
      //
      // Newly created accounts may be deleted.
      // Existing accounts are NEVER deleted.
      if (!invitationConfirmed) {
        final currentUser = FirebaseAuth.instance.currentUser;

        if (createdNewAccount &&
            accountUsed != null &&
            currentUser?.uid == accountUsed.uid) {
          try {
            await accountUsed.delete();
          } catch (_) {
            // If deletion fails, sign out rather than
            // leaving the rejected account signed in.
            try {
              await FirebaseAuth.instance.signOut();
            } catch (_) {}

            if (mounted) {
              setState(() {
                _errorMessage =
                '${_errorMessage ?? 'Activation was stopped.'}\n\n'
                    'The temporary authentication account '
                    'could not be removed automatically. '
                    'Please contact the administrator '
                    'if you need assistance.';
              });
            }
          }
        } else if (signedInExistingAccount &&
            accountUsed != null &&
            currentUser?.uid == accountUsed.uid) {
          try {
            await FirebaseAuth.instance.signOut();
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Technician Account',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 520,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Activate Technician Account',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Use the work email registered by the service provider '
                          'to activate technician access.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _technicianNotice(),

                            const SizedBox(height: 18),

                            TextFormField(
                              controller: _emailController,
                              keyboardType:
                              TextInputType.emailAddress,
                              validator: InputValidators.email,
                              decoration: const InputDecoration(
                                labelText: 'Work Email',
                                hintText: 'e.g. eric@company.com',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              validator: InputValidators.password,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword =
                                      !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              validator: (value) =>
                                  InputValidators.confirmPassword(
                                    value,
                                    _passwordController.text,
                                  ),
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            _passwordRules(),

                            if (_errorMessage != null) ...[
                              const SizedBox(height: 14),
                              _errorBox(_errorMessage!),
                            ],

                            const SizedBox(height: 18),

                            ElevatedButton(
                              onPressed:
                              _loading ? null : _activate,
                              child: Text(
                                _loading
                                    ? 'Checking Account...'
                                    : 'Create Technician Account',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Back to account registration',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _technicianNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(
          alpha: 0.06,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.engineering_outlined,
            color: AppTheme.primary,
            size: 20,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'A service provider must add the technician and work email '
                  'before this account can be activated.',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordRules() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(
          alpha: 0.06,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Password: at least 8 characters, with an uppercase letter, '
            'a lowercase letter and a number.',
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12.5,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppTheme.error,
        ),
      ),
    );
  }
}
