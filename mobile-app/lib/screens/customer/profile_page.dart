import 'package:flutter/material.dart';

import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../auth/change_password_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
  });

  @override
  State<ProfilePage> createState() =>
      _ProfilePageState();
}

class _ProfilePageState
    extends State<ProfilePage> {
  final _nameController =
  TextEditingController();

  final _phoneController =
  TextEditingController();

  bool _loading = true;
  bool _saving = false;

  String _email = '';
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();

    super.dispose();
  }

  Future<void> _loadProfile() async {
    final firebaseUser =
        AppServices.auth.currentUser;

    if (firebaseUser == null) {
      setState(() {
        _loading = false;
      });

      return;
    }

    try {
      final user =
      await AppServices.user.getUser(
        firebaseUser.uid,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _email =
            firebaseUser.email ??
                user?.email ??
                '';

        _nameController.text =
            user?.displayName ??
                firebaseUser.displayName ??
                '';

        _phoneController.text =
            user?.phone ?? '';

        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _email =
            firebaseUser.email ?? '';

        _nameController.text =
            firebaseUser.displayName ?? '';

        _loading = false;

        _message =
        'Unable to load profile information.';

        _messageIsError = true;
      });
    }
  }

  Future<void> _saveProfile() async {
    final firebaseUser =
        AppServices.auth.currentUser;

    if (firebaseUser == null) {
      return;
    }

    final name =
    _nameController.text.trim();

    final phone =
    _phoneController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _message =
        'Please enter your name.';
        _messageIsError = true;
      });

      return;
    }

    if (phone.isNotEmpty &&
        !RegExp(r'^01\d{8,9}$')
            .hasMatch(phone)) {
      setState(() {
        _message =
        'Please enter a valid Malaysian mobile number.';
        _messageIsError = true;
      });

      return;
    }

    setState(() {
      _saving = true;
      _message = null;
    });

    try {
      await AppServices.user
          .updateCustomerProfile(
        uid: firebaseUser.uid,
        displayName: name,
        phone: phone,
      );

      await AppServices.auth
          .updateDisplayName(
        name,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
        _message =
        'Profile updated successfully.';
        _messageIsError = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
        _message =
            error
                .toString()
                .replaceFirst(
              'Bad state: ',
              '',
            );
        _messageIsError = true;
      });
    }
  }

  Future<void> _signOut() async {
    await AppServices.auth.signOut();

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const LoginScreen(),
      ),
          (_) => false,
    );
  }

  String get _displayName {
    final name =
    _nameController.text.trim();

    if (name.isNotEmpty) {
      return name;
    }

    return 'Customer';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      AppTheme.background,

      appBar: AppBar(
        title: const Text(
          'Profile',
        ),
      ),

      body: _loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: _loadProfile,

        child: ListView(
          padding:
          const EdgeInsets.all(
            20,
          ),

          children: [
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor:
                AppTheme.primary
                    .withValues(
                  alpha: 0.10,
                ),

                child: const Icon(
                  Icons
                      .person_outline_rounded,
                  size: 40,
                  color:
                  AppTheme.primary,
                ),
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            Center(
              child: Text(
                _displayName,
                textAlign:
                TextAlign.center,

                style:
                const TextStyle(
                  fontSize: 20,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Center(
              child: Text(
                _email.isEmpty
                    ? 'Customer Account'
                    : _email,

                textAlign:
                TextAlign.center,

                style:
                const TextStyle(
                  color: AppTheme
                      .textSecondary,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            const Center(
              child: Chip(
                avatar: Icon(
                  Icons
                      .person_outline,
                  size: 17,
                ),
                label: Text(
                  'Customer Account',
                ),
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
                    const Text(
                      'Personal Information',
                      style:
                      TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight
                            .w600,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    TextField(
                      controller:
                      _nameController,

                      textCapitalization:
                      TextCapitalization
                          .words,

                      decoration:
                      const InputDecoration(
                        labelText:
                        'Full Name',
                        prefixIcon:
                        Icon(
                          Icons
                              .person_outline,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    TextField(
                      controller:
                      _phoneController,

                      keyboardType:
                      TextInputType
                          .phone,

                      decoration:
                      const InputDecoration(
                        labelText:
                        'Phone Number',
                        hintText:
                        '01XXXXXXXX',
                        prefixIcon:
                        Icon(
                          Icons
                              .phone_outlined,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    TextField(
                      controller:
                      TextEditingController(
                        text: _email,
                      ),

                      readOnly: true,

                      decoration:
                      const InputDecoration(
                        labelText:
                        'Email Address',
                        prefixIcon:
                        Icon(
                          Icons
                              .email_outlined,
                        ),
                        suffixIcon:
                        Icon(
                          Icons
                              .lock_outline,
                          size: 18,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    SizedBox(
                      width:
                      double.infinity,

                      child:
                      ElevatedButton(
                        onPressed:
                        _saving
                            ? null
                            : _saveProfile,

                        child: Text(
                          _saving
                              ? 'Saving...'
                              : 'Save Changes',
                        ),
                      ),
                    ),

                    if (_message !=
                        null) ...[
                      const SizedBox(
                        height: 12,
                      ),

                      Text(
                        _message!,

                        style:
                        TextStyle(
                          fontSize: 13,
                          color:
                          _messageIsError
                              ? Theme.of(
                            context,
                          )
                              .colorScheme
                              .error
                              : AppTheme
                              .primary,
                        ),
                      ),
                    ],
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
                      'Password & Security',
                      style:
                      TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight
                            .w600,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    const Text(
                      'Manage your account password and security settings.',
                      style:
                      TextStyle(
                        fontSize: 13,
                        color: AppTheme
                            .textSecondary,
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    ListTile(
                      contentPadding:
                      EdgeInsets.zero,

                      leading:
                      const Icon(
                        Icons
                            .lock_outline,
                      ),

                      title:
                      const Text(
                        'Change Password',
                      ),

                      subtitle:
                      const Text(
                        'Update your account password',
                      ),

                      trailing:
                      const Icon(
                        Icons
                            .chevron_right,
                      ),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const ChangePasswordScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            OutlinedButton.icon(
              onPressed:
              _signOut,

              icon:
              const Icon(
                Icons.logout,
              ),

              label:
              const Text(
                'Sign Out',
              ),
            ),

            const SizedBox(
              height: 24,
            ),
          ],
        ),
      ),
    );
  }
}