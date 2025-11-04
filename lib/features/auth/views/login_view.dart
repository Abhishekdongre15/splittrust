import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneFormKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.failure && state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        final theme = Theme.of(context);
        final isLoading = state.status == AuthStatus.authenticating ||
            state.status == AuthStatus.sendingOtp ||
            state.status == AuthStatus.verifyingOtp;

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Sign in to SplitTrust',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Continue with your mobile number or email to sync your groups and balances.',
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            TabBar(
                              labelStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              tabs: const [
                                Tab(text: 'Mobile OTP'),
                                Tab(text: 'Email & Password'),
                              ],
                            ),
                            SizedBox(
                              height: 360,
                              child: TabBarView(
                                children: [
                                  _buildPhoneLogin(context, state, isLoading),
                                  _buildEmailLogin(context, isLoading),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'By continuing you agree to the SplitTrust Terms of Service and Privacy Policy.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhoneLogin(BuildContext context, AuthState state, bool isLoading) {
    final theme = Theme.of(context);
    final otpVisible = state.status == AuthStatus.otpSent || state.status == AuthStatus.verifyingOtp;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _phoneFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mobile number', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '+91 98765 43210',
                prefixIcon: Icon(Icons.phone_android_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter your mobile number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: otpVisible ? 1 : 0,
              child: otpVisible
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('One-time password', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Enter 6-digit code',
                            prefixIcon: Icon(Icons.key_rounded),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: isLoading
                  ? null
                  : () {
                      if (!_phoneFormKey.currentState!.validate()) {
                        return;
                      }
                      if (otpVisible) {
                        context.read<AuthCubit>().verifyOtp(_otpController.text.trim());
                      } else {
                        context.read<AuthCubit>().sendOtp(_phoneController.text.trim());
                      }
                    },
              icon: Icon(otpVisible ? Icons.verified_rounded : Icons.sms_outlined),
              label: Text(otpVisible ? 'Verify & Continue' : 'Send OTP'),
            ),
            if (state.status == AuthStatus.sendingOtp || state.status == AuthStatus.verifyingOtp)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(minHeight: 3),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailLogin(BuildContext context, bool isLoading) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _emailFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email address', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'you@email.com',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter your email';
                }
                if (!value.contains('@')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text('Password', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Enter your password',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter your password';
                }
                return null;
              },
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: isLoading
                  ? null
                  : () {
                      if (!_emailFormKey.currentState!.validate()) {
                        return;
                      }
                      context.read<AuthCubit>().loginWithEmail(
                            _emailController.text.trim(),
                            _passwordController.text.trim(),
                          );
                    },
              icon: const Icon(Icons.login_rounded),
              label: const Text('Login securely'),
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(minHeight: 3),
              ),
          ],
        ),
      ),
    );
  }
}
