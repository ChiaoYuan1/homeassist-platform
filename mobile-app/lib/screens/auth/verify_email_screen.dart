import 'package:flutter/material.dart';

import '../../services/app_services.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/homeassist_action_dialog.dart';
import 'login_screen.dart';
import 'role_router.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _viewModel = AuthViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _checkVerification() async {
    final verified = await _viewModel.checkEmailVerified();
    if (!mounted) {
      return;
    }

    if (!verified) {
      await showHomeAssistMessageDialog(
        context: context,
        title: 'Email Not Verified',
        message: 'The email is not verified yet. '
            'Please open the verification link in your email first.',
        type: HomeAssistMessageType.warning,
      );
      return;
    }

    final uid = AppServices.auth.currentUserId;
    if (uid == null) {
      _goToLogin();
      return;
    }

    final profile = await AppServices.user.getUser(uid);
    if (!mounted) {
      return;
    }

    if (profile == null) {
      await showHomeAssistMessageDialog(
        context: context,
        title: 'Profile Not Found',
        message: 'The HomeAssist profile could not be found. '
            'Please try again or sign in with a different account.',
        type: HomeAssistMessageType.error,
      );
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => destinationForUser(profile),
      ),
          (_) => false,
    );
  }

  Future<void> _resend() async {
    final sent = await _viewModel.resendVerificationEmail();
    if (!mounted || !sent) {
      return;
    }

    await showHomeAssistSuccessDialog(
      context: context,
      title: 'Verification Email Sent',
      message: 'A new verification email has been sent. '
          'Please check your inbox and spam folder.',
    );
  }

  Future<void> _useDifferentAccount() async {
    await _viewModel.signOut();
    if (!mounted) {
      return;
    }
    _goToLogin();
  }

  void _goToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _viewModel.currentUserEmail ?? 'your email address';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ListenableBuilder(
                    listenable: _viewModel,
                    builder: (context, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.mark_email_read_outlined,
                              color: AppTheme.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'Verify your email',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'A verification link was sent to $email. '
                                'Open the link, then return to HomeAssist.',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              height: 1.45,
                            ),
                          ),
                          if (_viewModel.errorMessage != null) ...[
                            const SizedBox(height: 16),
                            _errorBox(_viewModel.errorMessage!),
                          ],
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _viewModel.isLoading
                                ? null
                                : _checkVerification,
                            icon: const Icon(Icons.verified_outlined),
                            label: Text(
                              _viewModel.isLoading
                                  ? 'Checking...'
                                  : "I've Verified My Email",
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _viewModel.isLoading ? null : _resend,
                            icon: const Icon(Icons.refresh_outlined),
                            label: const Text('Resend Verification Email'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _viewModel.isLoading
                                ? null
                                : _useDifferentAccount,
                            child: const Text('Use a different account'),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppTheme.error),
      ),
    );
  }
}
