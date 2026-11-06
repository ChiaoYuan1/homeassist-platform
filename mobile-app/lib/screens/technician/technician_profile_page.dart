import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../auth/change_password_screen.dart';

class TechnicianProfilePage extends StatefulWidget {
  final String providerId;
  final String technicianId;

  const TechnicianProfilePage({
    super.key,
    required this.providerId,
    required this.technicianId,
  });

  @override
  State<TechnicianProfilePage> createState() =>
      _TechnicianProfilePageState();
}

class _TechnicianProfilePageState
    extends State<TechnicianProfilePage> {
  final AuthService _authService =
  AuthService();

  final UserService _userService =
  UserService();

  final TextEditingController
  _phoneController =
  TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _signingOut = false;

  String _name = '';
  String _email = '';
  String _branchId = '';

  List<String> _serviceIds = [];

  bool _active = true;

  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  @override
  void dispose() {
    _phoneController.dispose();

    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final uid =
          _authService.currentUserId;

      if (uid == null) {
        throw StateError(
          'No authenticated technician account was found.',
        );
      }

      final user =
      await _userService.getUser(
        uid,
      );

      final technician =
      await _userService
          .getTechnicianDetails(
        providerId:
        widget.providerId,
        technicianId:
        widget.technicianId,
      );

      if (technician == null) {
        throw StateError(
          'Technician information could not be found.',
        );
      }

      if (!mounted) {
        return;
      }

      final serviceData =
      technician['serviceIds'];

      setState(() {
        _name =
            (technician['name'] ??
                user?.displayName ??
                '')
                .toString()
                .trim();

        _email =
            (technician['workEmail'] ??
                user?.email ??
                '')
                .toString()
                .trim();

        _phoneController.text =
            user?.phone.trim() ?? '';

        _branchId =
            (technician['branchId'] ??
                '')
                .toString()
                .trim();

        _active =
            technician['active'] !=
                false;

        _serviceIds =
        serviceData is List
            ? serviceData
            .map(
              (service) =>
              service.toString(),
        )
            .where(
              (service) =>
          service
              .trim()
              .isNotEmpty,
        )
            .toList()
            : [];

        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;

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

  Future<void> _savePhone() async {
    if (_saving) {
      return;
    }

    final phone =
    _phoneController.text.trim();

    if (phone.isNotEmpty &&
        !RegExp(
          r'^01\d{8,9}$',
        ).hasMatch(phone)) {
      setState(() {
        _message =
        'Please enter a valid Malaysian mobile number, for example 0123456789.';

        _messageIsError = true;
      });

      return;
    }

    final uid =
        _authService.currentUserId;

    if (uid == null) {
      setState(() {
        _message =
        'No authenticated technician account was found.';

        _messageIsError = true;
      });

      return;
    }

    setState(() {
      _saving = true;
      _message = null;
      _messageIsError = false;
    });

    try {
      await _userService
          .updateTechnicianPhone(
        uid: uid,
        providerId:
        widget.providerId,
        technicianId:
        widget.technicianId,
        phone: phone,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _message =
        'Phone number updated successfully.';

        _messageIsError = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _message =
            error
                .toString()
                .replaceFirst(
              'Bad state: ',
              '',
            );

        _messageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    if (_signingOut) {
      return;
    }

    setState(() {
      _signingOut = true;
    });

    try {
      await _authService.signOut();

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
    } finally {
      if (mounted) {
        setState(() {
          _signingOut = false;
        });
      }
    }
  }

  String _formatDisplayName(
      String value,
      ) {
    if (value.trim().isEmpty) {
      return 'Not assigned';
    }

    return value
        .trim()
        .replaceAll(
      '_',
      ' ',
    )
        .split(' ')
        .where(
          (word) =>
      word.isNotEmpty,
    )
        .map(
          (word) =>
      '${word[0].toUpperCase()}'
          '${word.substring(1)}',
    )
        .join(' ');
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
                radius: 38,
                backgroundColor:
                AppTheme.primary
                    .withValues(
                  alpha: 0.12,
                ),
                child: const Icon(
                  Icons
                      .engineering_rounded,
                  size: 40,
                  color:
                  AppTheme.primary,
                ),
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            Text(
              _name.isEmpty
                  ? 'Technician'
                  : _name,
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                fontSize: 22,
                fontWeight:
                FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              _email,
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                color:
                AppTheme
                    .textSecondary,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Center(
              child: Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration:
                BoxDecoration(
                  color:
                  (_active
                      ? AppTheme
                      .primary
                      : AppTheme
                      .error)
                      .withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    20,
                  ),
                ),
                child: Text(
                  _active
                      ? 'Active Technician'
                      : 'Currently Inactive',
                  style:
                  TextStyle(
                    fontWeight:
                    FontWeight
                        .w700,
                    color:
                    _active
                        ? AppTheme
                        .primary
                        : AppTheme
                        .error,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            _ProfileSection(
              title:
              'Contact Information',
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .stretch,
                children: [
                  const Text(
                    'Work Email',
                    style:
                    TextStyle(
                      fontWeight:
                      FontWeight
                          .w700,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    _email,
                    style:
                    const TextStyle(
                      color:
                      AppTheme
                          .textSecondary,
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  const Text(
                    'Phone Number',
                    style:
                    TextStyle(
                      fontWeight:
                      FontWeight
                          .w700,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  TextField(
                    controller:
                    _phoneController,
                    keyboardType:
                    TextInputType
                        .phone,
                    decoration:
                    const InputDecoration(
                      hintText:
                      'e.g. 0123456789',
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  ElevatedButton(
                    onPressed:
                    _saving
                        ? null
                        : _savePhone,
                    child: Text(
                      _saving
                          ? 'Saving...'
                          : 'Save Phone Number',
                    ),
                  ),

                  if (_message !=
                      null) ...[
                    const SizedBox(
                      height: 16,
                    ),

                    Container(
                      padding:
                      const EdgeInsets
                          .all(
                        12,
                      ),
                      decoration:
                      BoxDecoration(
                        color:
                        (_messageIsError
                            ? AppTheme
                            .error
                            : AppTheme
                            .primary)
                            .withValues(
                          alpha:
                          0.08,
                        ),
                        borderRadius:
                        BorderRadius
                            .circular(
                          12,
                        ),
                      ),
                      child: Text(
                        _message!,
                        style:
                        TextStyle(
                          color:
                          _messageIsError
                              ? AppTheme
                              .error
                              : AppTheme
                              .textPrimary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            _ProfileSection(
              title:
              'Work Assignment',
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .stretch,
                children: [
                  const Text(
                    'Assigned Branch',
                    style:
                    TextStyle(
                      fontWeight:
                      FontWeight
                          .w700,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    _formatDisplayName(
                      _branchId,
                    ),
                    style:
                    const TextStyle(
                      color:
                      AppTheme
                          .textSecondary,
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  const Text(
                    'Qualified Services',
                    style:
                    TextStyle(
                      fontWeight:
                      FontWeight
                          .w700,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  if (_serviceIds
                      .isEmpty)
                    const Text(
                      'No qualified services assigned.',
                      style:
                      TextStyle(
                        color:
                        AppTheme
                            .textSecondary,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                      _serviceIds
                          .map(
                            (
                            serviceId,
                            ) {
                          return Chip(
                            label:
                            Text(
                              _formatDisplayName(
                                serviceId,
                              ),
                            ),
                          );
                        },
                      ).toList(),
                    ),

                  const SizedBox(
                    height: 14,
                  ),

                  const Text(
                    'Branch and service assignments are managed by the service provider.',
                    style:
                    TextStyle(
                      color:
                      AppTheme
                          .textSecondary,
                      fontSize:
                      12.5,
                      height:
                      1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            _ProfileSection(
              title:
              'Password & Security',
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .stretch,
                children: [
                  const Text(
                    'Manage your account password and security settings.',
                    style:
                    TextStyle(
                      color:
                      AppTheme
                          .textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
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

            const SizedBox(
              height: 22,
            ),

            OutlinedButton.icon(
              onPressed:
              _signingOut
                  ? null
                  : _signOut,
              icon:
              const Icon(
                Icons.logout_rounded,
              ),
              label: Text(
                _signingOut
                    ? 'Signing Out...'
                    : 'Sign Out',
              ),
            ),

            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSection
    extends StatelessWidget {
  final String title;
  final Widget child;

  const _ProfileSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Card(
      child: Padding(
        padding:
        const EdgeInsets.all(
          18,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style:
              const TextStyle(
                fontSize: 17,
                fontWeight:
                FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            child,
          ],
        ),
      ),
    );
  }
}
