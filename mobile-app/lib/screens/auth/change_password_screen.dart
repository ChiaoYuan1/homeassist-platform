import 'package:flutter/material.dart';

import '../../core/input_validators.dart';
import '../../services/app_services.dart';
import '../../theme/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({
    super.key,
  });

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController =
  TextEditingController();

  final _newPasswordController =
  TextEditingController();

  final _confirmPasswordController =
  TextEditingController();

  bool _hideCurrentPassword = true;
  bool _hideNewPassword = true;
  bool _hideConfirmPassword = true;

  bool _updating = false;
  bool _sendingReset = false;

  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> _changePassword() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _message = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentPassword =
        _currentPasswordController.text;

    final newPassword =
        _newPasswordController.text;

    if (currentPassword == newPassword) {
      setState(() {
        _message =
        'The new password must be different from your current password.';
        _messageIsError = true;
      });

      return;
    }

    setState(() {
      _updating = true;
    });

    try {
      await AppServices.auth.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (!mounted) {
        return;
      }

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      setState(() {
        _updating = false;
        _message =
        'Password updated successfully.';
        _messageIsError = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _updating = false;

        _message = error
            .toString()
            .replaceFirst(
          'Bad state: ',
          '',
        );

        _messageIsError = true;
      });
    }
  }

  Future<void> _sendPasswordReset() async {
    final user =
        AppServices.auth.currentUser;

    final email = user?.email;

    if (email == null ||
        email.trim().isEmpty) {
      setState(() {
        _message =
        'No email address is available for this account.';
        _messageIsError = true;
      });

      return;
    }

    setState(() {
      _sendingReset = true;
      _message = null;
    });

    try {
      await AppServices.auth
          .sendPasswordResetEmail(
        email,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _sendingReset = false;
        _message =
        'Password reset email sent to $email.';
        _messageIsError = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _sendingReset = false;

        _message = error
            .toString()
            .replaceFirst(
          'Bad state: ',
          '',
        );

        _messageIsError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final newPassword =
        _newPasswordController.text;

    final hasMinimumLength =
        newPassword.length >= 8;

    final hasUppercase =
    RegExp(r'[A-Z]')
        .hasMatch(newPassword);

    final hasLowercase =
    RegExp(r'[a-z]')
        .hasMatch(newPassword);

    final hasNumber =
    RegExp(r'\d')
        .hasMatch(newPassword);

    return Scaffold(
      backgroundColor:
      AppTheme.background,

      appBar: AppBar(
        title: const Text(
          'Change Password',
        ),
      ),

      body: Form(
        key: _formKey,

        child: ListView(
          padding:
          const EdgeInsets.all(20),

          children: [
            const Text(
              'Password & Security',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            const Text(
              'Enter your current password before choosing a new one.',
              style: TextStyle(
                color:
                AppTheme.textSecondary,
                height: 1.4,
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            Card(
              child: Padding(
                padding:
                const EdgeInsets.all(
                  18,
                ),

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

                  children: [
                    TextFormField(
                      controller:
                      _currentPasswordController,

                      obscureText:
                      _hideCurrentPassword,

                      enableSuggestions:
                      false,

                      autocorrect:
                      false,

                      decoration:
                      InputDecoration(
                        labelText:
                        'Current Password',

                        prefixIcon:
                        const Icon(
                          Icons
                              .lock_outline,
                        ),

                        suffixIcon:
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _hideCurrentPassword =
                              !_hideCurrentPassword;
                            });
                          },

                          icon: Icon(
                            _hideCurrentPassword
                                ? Icons
                                .visibility_outlined
                                : Icons
                                .visibility_off_outlined,
                          ),
                        ),
                      ),

                      validator:
                          (value) =>
                          InputValidators
                              .requiredText(
                            value,
                            label:
                            'Current password',
                          ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    TextFormField(
                      controller:
                      _newPasswordController,

                      obscureText:
                      _hideNewPassword,

                      enableSuggestions:
                      false,

                      autocorrect:
                      false,

                      onChanged: (_) {
                        setState(() {});
                      },

                      decoration:
                      InputDecoration(
                        labelText:
                        'New Password',

                        prefixIcon:
                        const Icon(
                          Icons
                              .key_outlined,
                        ),

                        suffixIcon:
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _hideNewPassword =
                              !_hideNewPassword;
                            });
                          },

                          icon: Icon(
                            _hideNewPassword
                                ? Icons
                                .visibility_outlined
                                : Icons
                                .visibility_off_outlined,
                          ),
                        ),
                      ),

                      validator:
                      InputValidators
                          .password,
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    Container(
                      width:
                      double.infinity,

                      padding:
                      const EdgeInsets.all(
                        14,
                      ),

                      decoration:
                      BoxDecoration(
                        color: AppTheme
                            .primary
                            .withValues(
                          alpha: 0.04,
                        ),

                        borderRadius:
                        BorderRadius
                            .circular(
                          12,
                        ),
                      ),

                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                        children: [
                          const Text(
                            'Password requirements',
                            style:
                            TextStyle(
                              fontWeight:
                              FontWeight
                                  .w600,
                            ),
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          _PasswordRequirement(
                            text:
                            'At least 8 characters',
                            met:
                            hasMinimumLength,
                          ),

                          _PasswordRequirement(
                            text:
                            'At least one uppercase letter',
                            met:
                            hasUppercase,
                          ),

                          _PasswordRequirement(
                            text:
                            'At least one lowercase letter',
                            met:
                            hasLowercase,
                          ),

                          _PasswordRequirement(
                            text:
                            'At least one number',
                            met:
                            hasNumber,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    TextFormField(
                      controller:
                      _confirmPasswordController,

                      obscureText:
                      _hideConfirmPassword,

                      enableSuggestions:
                      false,

                      autocorrect:
                      false,

                      decoration:
                      InputDecoration(
                        labelText:
                        'Confirm New Password',

                        prefixIcon:
                        const Icon(
                          Icons
                              .lock_reset_outlined,
                        ),

                        suffixIcon:
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _hideConfirmPassword =
                              !_hideConfirmPassword;
                            });
                          },

                          icon: Icon(
                            _hideConfirmPassword
                                ? Icons
                                .visibility_outlined
                                : Icons
                                .visibility_off_outlined,
                          ),
                        ),
                      ),

                      validator: (value) =>
                          InputValidators
                              .confirmPassword(
                            value,
                            _newPasswordController
                                .text,
                          ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    SizedBox(
                      width:
                      double.infinity,

                      child:
                      ElevatedButton(
                        onPressed:
                        _updating
                            ? null
                            : _changePassword,

                        child: Text(
                          _updating
                              ? 'Updating...'
                              : 'Update Password',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            Card(
              child: Padding(
                padding:
                const EdgeInsets.all(
                  18,
                ),

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

                  children: [
                    const Text(
                      'Forgot Your Current Password?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    const Text(
                      'A password reset link can be sent to the email address associated with this account.',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                        AppTheme
                            .textSecondary,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    SizedBox(
                      width:
                      double.infinity,

                      child:
                      OutlinedButton.icon(
                        onPressed:
                        _sendingReset
                            ? null
                            : _sendPasswordReset,

                        icon: const Icon(
                          Icons
                              .email_outlined,
                        ),

                        label: Text(
                          _sendingReset
                              ? 'Sending...'
                              : 'Reset Password by Email',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_message !=
                null) ...[
              const SizedBox(
                height: 16,
              ),

              Container(
                padding:
                const EdgeInsets.all(
                  14,
                ),

                decoration:
                BoxDecoration(
                  color: _messageIsError
                      ? Theme.of(
                    context,
                  )
                      .colorScheme
                      .errorContainer
                      : AppTheme
                      .primary
                      .withValues(
                    alpha: 0.08,
                  ),

                  borderRadius:
                  BorderRadius
                      .circular(
                    12,
                  ),
                ),

                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

                  children: [
                    Icon(
                      _messageIsError
                          ? Icons
                          .error_outline
                          : Icons
                          .check_circle_outline,

                      size: 20,

                      color: _messageIsError
                          ? Theme.of(
                        context,
                      )
                          .colorScheme
                          .error
                          : AppTheme
                          .primary,
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: Text(
                        _message!,

                        style:
                        TextStyle(
                          color:
                          _messageIsError
                              ? Theme.of(
                            context,
                          )
                              .colorScheme
                              .error
                              : null,

                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(
              height: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordRequirement
    extends StatelessWidget {
  final String text;
  final bool met;

  const _PasswordRequirement({
    required this.text,
    required this.met,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 7,
      ),

      child: Row(
        children: [
          Icon(
            met
                ? Icons
                .check_circle_rounded
                : Icons
                .radio_button_unchecked,

            size: 17,

            color: met
                ? AppTheme.primary
                : AppTheme
                .textSecondary,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              text,

              style: TextStyle(
                fontSize: 12.5,

                color: met
                    ? null
                    : AppTheme
                    .textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}