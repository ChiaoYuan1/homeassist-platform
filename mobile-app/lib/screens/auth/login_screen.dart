import 'package:flutter/material.dart';

import '../../core/app_enums.dart';
import '../../core/input_validators.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'role_router.dart';
import 'verify_email_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _viewModel = AuthViewModel();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final user = await _viewModel.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (user == null || !mounted) {
      return;
    }

    if (user.role != UserRole.admin && !_viewModel.currentUserEmailVerified) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const VerifyEmailScreen(),
        ),
            (_) => false,
      );
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => destinationForUser(user),
      ),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _brandHeader(),
                    const SizedBox(height: 26),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: ListenableBuilder(
                          listenable: _viewModel,
                          builder: (context, _) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Welcome back',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Sign in to continue to HomeAssist.',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
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
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  validator: (value) =>
                                      InputValidators.requiredText(
                                        value,
                                        label: 'Password',
                                      ),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon:
                                    const Icon(Icons.lock_outline),
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
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                          const ForgotPasswordScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text('Forgot password?'),
                                  ),
                                ),
                                if (_viewModel.errorMessage != null) ...[
                                  _errorBox(_viewModel.errorMessage!),
                                  const SizedBox(height: 12),
                                ],
                                ElevatedButton(
                                  onPressed:
                                  _viewModel.isLoading ? null : _login,
                                  child: Text(
                                    _viewModel.isLoading
                                        ? 'Signing in...'
                                        : 'Sign In',
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text('Create account'),
                        ),
                      ],
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

  Widget _brandHeader() {
    return const Column(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Color(0xFFEFF6FF),
          child: Icon(
            Icons.home_repair_service_rounded,
            color: AppTheme.primary,
            size: 34,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'HomeAssist',
          style: TextStyle(
            fontSize: 29,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Household services, easier to manage.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ],
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
