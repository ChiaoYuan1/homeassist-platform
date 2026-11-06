import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import 'role_router.dart';

class TechnicianVerifyEmailScreen
    extends StatefulWidget {
  final String email;

  const TechnicianVerifyEmailScreen({
    super.key,
    required this.email,
  });

  @override
  State<TechnicianVerifyEmailScreen>
  createState() =>
      _TechnicianVerifyEmailScreenState();
}

class _TechnicianVerifyEmailScreenState
    extends State<TechnicianVerifyEmailScreen> {
  final AuthService _authService =
  AuthService();

  final UserService _userService =
  UserService();

  bool _checking = false;
  bool _resending = false;

  String? _message;
  bool _messageIsError = false;


  Future<void> _checkVerification() async {
    if (_checking) {
      return;
    }

    setState(() {
      _checking = true;
      _message = null;
      _messageIsError = false;
    });

    try {
      final verified =
      await _authService
          .reloadAndCheckEmailVerified();

      if (!verified) {
        if (!mounted) {
          return;
        }

        setState(() {
          _message =
          'The email has not been verified yet. '
              'Open the verification email, complete '
              'the verification, then try again.';
          _messageIsError = true;
        });

        return;
      }


      final firebaseUser =
          _authService.currentUser;

      if (firebaseUser == null) {
        throw StateError(
          'No authenticated technician account '
              'was found.',
        );
      }


      final technicianUser =
      await _userService
          .activateTechnicianProfile(
        uid: firebaseUser.uid,
        email:
        firebaseUser.email ??
            widget.email,
      );


      if (!mounted) {
        return;
      }


      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              destinationForUser(
                technicianUser,
              ),
        ),
            (_) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _message =
            _friendlyError(error);
        _messageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _checking = false;
        });
      }
    }
  }


  Future<void> _resendVerification() async {
    if (_resending) {
      return;
    }

    setState(() {
      _resending = true;
      _message = null;
      _messageIsError = false;
    });

    try {
      final verified =
      await _authService
          .reloadAndCheckEmailVerified();

      if (!mounted) {
        return;
      }

      if (verified) {
        setState(() {
          _message =
          'Your work email is already verified. '
              'You can continue by pressing '
              '"I\'ve Verified My Email".';

          _messageIsError = false;
        });

        return;
      }

      await _authService
          .sendEmailVerification();

      if (!mounted) {
        return;
      }

      setState(() {
        _message =
        'A new verification email has '
            'been sent to ${widget.email}.';

        _messageIsError = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _message =
        'Unable to resend the verification '
            'email. Please try again.';

        _messageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _resending = false;
        });
      }
    }
  }

  String _friendlyError(
      Object error,
      ) {
    final text =
    error.toString();

    if (text.contains(
      'No technician invitation was found',
    )) {
      return 'No technician invitation was found '
          'for this work email. Please confirm that '
          'the service provider added this email '
          'to the team first.';
    }

    if (text.contains(
      'technician account is inactive',
    )) {
      return 'This technician account is currently '
          'inactive. Please contact the service '
          'provider.';
    }

    if (text.contains(
      'already been activated',
    )) {
      return 'This technician profile has already '
          'been linked to another account.';
    }

    return text
        .replaceFirst(
      'Bad state: ',
      '',
    )
        .replaceFirst(
      'StateError: ',
      '',
    );
  }


  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      AppTheme.background,

      appBar: AppBar(
        title: const Text(
          'Verify Work Email',
        ),
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.all(
              20,
            ),

            child: ConstrainedBox(
              constraints:
              const BoxConstraints(
                maxWidth: 520,
              ),

              child: Card(
                child: Padding(
                  padding:
                  const EdgeInsets.all(
                    22,
                  ),

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .stretch,

                    children: [
                      Icon(
                        Icons
                            .mark_email_read_outlined,
                        size: 48,
                        color:
                        Theme.of(context)
                            .colorScheme
                            .primary,
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      const Text(
                        'Verify Your Work Email',
                        textAlign:
                        TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight:
                          FontWeight.w800,
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      const Text(
                        'A verification link has '
                            'been sent to:',
                        textAlign:
                        TextAlign.center,
                        style: TextStyle(
                          color:
                          AppTheme
                              .textSecondary,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        widget.email,
                        textAlign:
                        TextAlign.center,
                        style: const TextStyle(
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      Container(
                        padding:
                        const EdgeInsets.all(
                          12,
                        ),
                        decoration:
                        BoxDecoration(
                          color:
                          AppTheme.primary
                              .withValues(
                            alpha: 0.06,
                          ),
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),
                        ),
                        child: const Text(
                          'After verifying the email, '
                              'return to HomeAssist and '
                              'press the button below. '
                              'The account will then be '
                              'linked to the technician '
                              'record created by the '
                              'service provider.',
                          style: TextStyle(
                            color:
                            AppTheme
                                .textSecondary,
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ),

                      if (_message != null) ...[
                        const SizedBox(
                          height: 16,
                        ),

                        Container(
                          padding:
                          const EdgeInsets.all(
                            12,
                          ),
                          decoration:
                          BoxDecoration(
                            color:
                            (_messageIsError
                                ? AppTheme.error
                                : AppTheme.primary)
                                .withValues(
                              alpha: 0.08,
                            ),
                            borderRadius:
                            BorderRadius.circular(
                              12,
                            ),
                          ),
                          child: Text(
                            _message!,
                            style: TextStyle(
                              color:
                              _messageIsError
                                  ? AppTheme.error
                                  : AppTheme
                                  .textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(
                        height: 20,
                      ),

                      ElevatedButton(
                        onPressed:
                        _checking
                            ? null
                            : _checkVerification,
                        child: Text(
                          _checking
                              ? 'Checking...'
                              : 'I\'ve Verified My Email',
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      TextButton(
                        onPressed:
                        _resending
                            ? null
                            : _resendVerification,
                        child: Text(
                          _resending
                              ? 'Sending...'
                              : 'Resend Verification Email',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}