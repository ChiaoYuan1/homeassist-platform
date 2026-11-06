import 'package:flutter/material.dart';

import '../../core/input_validators.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _viewModel = AuthViewModel();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final sent = await _viewModel.sendPasswordReset(
      _emailController.text.trim(),
    );

    if (!mounted || !sent) {
      return;
    }

    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Reset Password')),
      body: Center(
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
                    return Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.lock_reset_outlined,
                            size: 46,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Forgot your password?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Enter the email used for the HomeAssist account. Firebase will send a password reset link.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 22),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: InputValidators.email,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          if (_viewModel.errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _viewModel.errorMessage!,
                              style: const TextStyle(color: AppTheme.error),
                            ),
                          ],
                          if (_sent) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Reset email sent. Check the inbox and spam folder.',
                              style: TextStyle(color: AppTheme.success),
                            ),
                          ],
                          const SizedBox(height: 18),
                          ElevatedButton(
                            onPressed: _viewModel.isLoading ? null : _sendReset,
                            child: Text(
                              _viewModel.isLoading
                                  ? 'Sending...'
                                  : 'Send Reset Email',
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
