import 'package:flutter/material.dart';

import '../../core/app_enums.dart';
import '../../core/input_validators.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'technician_activation_screen.dart';
import 'verify_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _viewModel = AuthViewModel();

  UserRole _role = UserRole.customer;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final user = await _viewModel.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _nameController.text.trim(),
      phone: _phoneController.text,
      role: _role,
    );

    if (user == null || !mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const VerifyEmailScreen(),
      ),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Join HomeAssist',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Create a verified account before using HomeAssist services.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: ListenableBuilder(
                          listenable: _viewModel,
                          builder: (context, _) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _roleSelector(),
                                const SizedBox(height: 18),
                                TextFormField(
                                  controller: _nameController,
                                  textCapitalization: TextCapitalization.words,
                                  validator: (value) =>
                                      InputValidators.requiredText(
                                        value,
                                        label: _role == UserRole.provider
                                            ? 'Contact person name'
                                            : 'Full name',
                                      ),
                                  decoration: InputDecoration(
                                    labelText: _role == UserRole.provider
                                        ? 'Contact Person Name'
                                        : 'Full Name',
                                    prefixIcon:
                                    const Icon(Icons.person_outline),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  validator: InputValidators.malaysiaMobile,
                                  decoration: const InputDecoration(
                                    labelText: 'Malaysian Mobile Number',
                                    hintText: '+60123456789',
                                    prefixIcon: Icon(Icons.phone_outlined),
                                  ),
                                ),
                                const SizedBox(height: 12),
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
                                  validator: InputValidators.password,
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
                                    prefixIcon:
                                    const Icon(Icons.lock_outline),
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
                                if (_role == UserRole.provider) ...[
                                  const SizedBox(height: 14),
                                  _providerNotice(),
                                ],
                                if (_viewModel.errorMessage != null) ...[
                                  const SizedBox(height: 14),
                                  _errorBox(_viewModel.errorMessage!),
                                ],
                                const SizedBox(height: 18),
                                ElevatedButton(
                                  onPressed: _viewModel.isLoading
                                      ? null
                                      : _register,
                                  child: Text(
                                    _viewModel.isLoading
                                        ? 'Creating Account...'
                                        : 'Create Account',
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Already have an account? Sign in'),
                    ),

                    const SizedBox(height: 8),

                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const TechnicianActivationScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.engineering_outlined,
                      ),
                      label: const Text(
                        'Are you a technician? Activate your account',
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

  Widget _roleSelector() {
    return SegmentedButton<UserRole>(
      segments: const [
        ButtonSegment<UserRole>(
          value: UserRole.customer,
          icon: Icon(Icons.person_outline),
          label: Text('Customer'),
        ),
        ButtonSegment<UserRole>(
          value: UserRole.provider,
          icon: Icon(Icons.business_outlined),
          label: Text('Service Provider'),
        ),
      ],
      selected: {_role},
      onSelectionChanged: (selection) {
        setState(() => _role = selection.first);
      },
    );
  }

  Widget _passwordRules() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.06),
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

  Widget _providerNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: AppTheme.warning,
            size: 20,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'After email verification, service providers must submit SSM '
                  'business information and relevant service credentials for '
                  'administrator approval.',
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
