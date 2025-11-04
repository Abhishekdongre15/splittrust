import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../data/auth_repository.dart';

enum _AuthPage { landing, login, signup, phone }

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _page = ValueNotifier<_AuthPage>(_AuthPage.landing);

  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>();

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _loginPasswordVisible = false;
  bool _signupPasswordVisible = false;

  @override
  void dispose() {
    _page.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
        }
        if (state.status == AuthStatus.otpSent && _page.value != _AuthPage.phone) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _page.value = _AuthPage.phone;
          });
        }
      },
      builder: (context, state) {
        final isBusy = state.status == AuthStatus.authenticating ||
            state.status == AuthStatus.sendingOtp ||
            state.status == AuthStatus.verifyingOtp;

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: theme.colorScheme.surface,
            body: SafeArea(
              child: Stack(
                children: [
                  ValueListenableBuilder<_AuthPage>(
                    valueListenable: _page,
                    builder: (context, page, _) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        child: _buildPage(context, page, state, isBusy),
                      );
                    },
                  ),
                  if (isBusy)
                    const Align(
                      alignment: Alignment.topCenter,
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPage(BuildContext context, _AuthPage page, AuthState state, bool isBusy) {
    switch (page) {
      case _AuthPage.landing:
        return _LandingView(onLogin: () => _page.value = _AuthPage.login, onSignup: () => _page.value = _AuthPage.signup);
      case _AuthPage.login:
        return _buildLoginForm(context, isBusy);
      case _AuthPage.signup:
        return _buildSignupForm(context, isBusy);
      case _AuthPage.phone:
        return _buildPhoneForm(context, state, isBusy);
    }
  }

  Widget _buildLoginForm(BuildContext context, bool isBusy) {
    final theme = Theme.of(context);
    return Padding(
      key: const ValueKey('login-form'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackButton(onPressed: () => _page.value = _AuthPage.landing),
          const SizedBox(height: 16),
          Text('Log in', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Enter the email and password you use for SplitTrust.',
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _loginFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email address', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _loginEmailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'name@email.com',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter your email address';
                        }
                        if (!value.contains('@')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Password', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _loginPasswordController,
                      obscureText: !_loginPasswordVisible,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_loginPasswordVisible ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _loginPasswordVisible = !_loginPasswordVisible),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isBusy ? null : () => _onForgotPassword(context),
                        child: const Text('Forgot your password?'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isBusy
                          ? null
                          : () {
                              if (_loginFormKey.currentState?.validate() ?? false) {
                                context.read<AuthCubit>().loginWithEmail(
                                      _loginEmailController.text.trim(),
                                      _loginPasswordController.text.trim(),
                                    );
                              }
                            },
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      child: const Text('Log in'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: isBusy
                          ? null
                          : () {
                              _phoneController.clear();
                              _otpController.clear();
                              _page.value = _AuthPage.phone;
                            },
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      child: const Text('Use mobile OTP instead'),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: isBusy ? null : () => _page.value = _AuthPage.signup,
                        child: const Text("Don't have an account? Sign up"),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm(BuildContext context, bool isBusy) {
    final theme = Theme.of(context);
    return Padding(
      key: const ValueKey('signup-form'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackButton(onPressed: () => _page.value = _AuthPage.landing),
          const SizedBox(height: 16),
          Text('Sign up', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Create a SplitTrust account with your email address.',
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _signupFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email address', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _signupEmailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'name@email.com',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter your email address';
                        }
                        if (!value.contains('@')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Password', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _signupPasswordController,
                      obscureText: !_signupPasswordVisible,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: 'Minimum 8 characters',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_signupPasswordVisible ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _signupPasswordVisible = !_signupPasswordVisible),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Create a password';
                        }
                        if (value.trim().length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isBusy
                          ? null
                          : () {
                              if (_signupFormKey.currentState?.validate() ?? false) {
                                context.read<AuthCubit>().signUpWithEmail(
                                      _signupEmailController.text.trim(),
                                      _signupPasswordController.text.trim(),
                                    );
                              }
                            },
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      child: const Text('Next'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: isBusy
                          ? null
                          : () {
                              _phoneController.clear();
                              _otpController.clear();
                              _page.value = _AuthPage.phone;
                            },
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      child: const Text('Use mobile number'),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: isBusy ? null : () => _page.value = _AuthPage.login,
                        child: const Text('Already have an account? Log in'),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneForm(BuildContext context, AuthState state, bool isBusy) {
    final theme = Theme.of(context);
    final showOtp = state.status == AuthStatus.otpSent || state.status == AuthStatus.verifyingOtp;

    return Padding(
      key: const ValueKey('phone-form'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackButton(onPressed: () => _page.value = _AuthPage.landing),
          const SizedBox(height: 16),
          Text('Sign in with mobile', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'We’ll send a one-time password to your phone.',
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
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
                      textInputAction: TextInputAction.done,
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
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: showOtp
                          ? Column(
                              key: const ValueKey('otp-field'),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('One-time password', style: theme.textTheme.titleSmall),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _otpController,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.done,
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
                    FilledButton(
                      onPressed: isBusy
                          ? null
                          : () {
                              final formState = _phoneFormKey.currentState;
                              if (formState == null || !formState.validate()) {
                                return;
                              }
                              if (showOtp) {
                                context.read<AuthCubit>().verifyOtp(_otpController.text.trim());
                              } else {
                                context.read<AuthCubit>().sendOtp(_phoneController.text.trim());
                              }
                            },
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      child: Text(showOtp ? 'Verify & continue' : 'Send OTP'),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: isBusy ? null : () => _page.value = _AuthPage.login,
                        child: const Text('Use email instead'),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onForgotPassword(BuildContext context) async {
    final email = _loginEmailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Enter your email to reset your password')));
      return;
    }
    try {
      await context.read<AuthCubit>().sendPasswordReset(email);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Password reset email sent to $email')));
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _LandingView extends StatelessWidget {
  const _LandingView({required this.onLogin, required this.onSignup});

  final VoidCallback onLogin;
  final VoidCallback onSignup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('landing'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.surface,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.auto_awesome, color: theme.colorScheme.onPrimary, size: 32),
                      ),
                      const SizedBox(height: 24),
                      Text('SplitTrust', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      Text(
                        'Track shared expenses, settle smarter, and stay in sync with your groups.',
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: _LandingShapes(color: theme.colorScheme.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: onSignup,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('Sign up'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onLogin,
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('Log in'),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              _LinkText('Terms', onTap: () {}),
              _LinkText('Privacy Policy', onTap: () {}),
              _LinkText('Contact us', onTap: () {}),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}

class _LandingShapes extends StatelessWidget {
  const _LandingShapes({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.secondary;
    return SizedBox(
      width: 160,
      height: 120,
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            child: Transform.rotate(
              angle: -0.2,
              child: Container(
                width: 80,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 8,
            child: Transform.rotate(
              angle: 0.25,
              child: Container(
                width: 72,
                height: 36,
                decoration: BoxDecoration(
                  color: secondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 0,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkText extends StatelessWidget {
  const _LinkText(this.label, {required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
      ),
    );
  }
}
