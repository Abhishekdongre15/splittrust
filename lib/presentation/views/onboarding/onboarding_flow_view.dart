import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../viewmodels/onboarding/onboarding_state.dart';
import '../../viewmodels/onboarding/onboarding_view_model.dart';

class OnboardingFlowView extends StatelessWidget {
  const OnboardingFlowView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<OnboardingViewModel, OnboardingState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildStep(context, state)),
                  _OnboardingControls(state: state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, OnboardingState state) {
    switch (state.step) {
      case OnboardingStep.welcome:
        return _WelcomeStep(onContinue: context.read<OnboardingViewModel>().goToNext);
      case OnboardingStep.permissions:
        return _PermissionsStep(state: state);
      case OnboardingStep.auth:
        return _AuthStep(state: state);
      case OnboardingStep.profile:
        return _ProfileStep(state: state);
      case OnboardingStep.dashboard:
        return _ReadyStep(onFinish: context.read<OnboardingViewModel>().finish);
    }
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text(
          'SplitTrust',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'Automate shared expenses, settlements, and analytics across Android, iOS, and the web.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Spacer(),
        FilledButton(
          onPressed: onContinue,
          child: const Text('Get started'),
        ),
      ],
    );
  }
}

class _PermissionsStep extends StatelessWidget {
  const _PermissionsStep({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Stay notified', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Allow notifications to get reminders when settlements are due or expenses are added.'),
        const SizedBox(height: 24),
        SwitchListTile(
          value: state.notificationsAllowed,
          onChanged: context.read<OnboardingViewModel>().allowNotifications,
          title: const Text('Enable notifications'),
        ),
        const Spacer(),
        FilledButton(
          onPressed: () => context.read<OnboardingViewModel>().goToNext(),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _AuthStep extends StatelessWidget {
  const _AuthStep({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final authOptions = {
      AuthMethod.phoneOtp: 'Phone OTP',
      AuthMethod.google: 'Google Sign-In',
      AuthMethod.emailPassword: 'Email & Password',
      AuthMethod.guest: 'Try as guest',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose how to sign in', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text('Guests can explore but must link an account before joining shared groups.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        ...authOptions.entries.map(
          (entry) => RadioListTile<AuthMethod>(
            value: entry.key,
            groupValue: state.selectedAuthMethod,
            onChanged: (value) {
              if (value != null) {
                context.read<OnboardingViewModel>().selectAuth(value);
              }
            },
            title: Text(entry.value),
          ),
        ),
        const Spacer(),
        FilledButton(
          onPressed: state.selectedAuthMethod == null ? null : () => context.read<OnboardingViewModel>().goToNext(),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _ProfileStep extends StatefulWidget {
  const _ProfileStep({required this.state});

  final OnboardingState state;

  @override
  State<_ProfileStep> createState() => _ProfileStepState();
}

class _ProfileStepState extends State<_ProfileStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _currencyController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.state.name ?? '');
    _currencyController = TextEditingController(text: widget.state.baseCurrency ?? 'INR');
    _emailController = TextEditingController(text: widget.state.email ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tell us about you', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Full name'),
            validator: (value) => value != null && value.length >= 2 ? null : 'Name should be at least 2 characters',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _currencyController,
            decoration: const InputDecoration(labelText: 'Base currency (ISO-4217)'),
            validator: (value) => value != null && value.length == 3 ? null : 'Enter a valid currency code',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email (optional)'),
          ),
          const Spacer(),
          FilledButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                context.read<OnboardingViewModel>().setProfile(
                      name: _nameController.text,
                      baseCurrency: _currencyController.text.toUpperCase(),
                      email: _emailController.text.isEmpty ? null : _emailController.text,
                    );
                context.read<OnboardingViewModel>().goToNext();
              }
            },
            child: const Text('Finish setup'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currencyController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}

class _ReadyStep extends StatelessWidget {
  const _ReadyStep({required this.onFinish});

  final Future<void> Function() onFinish;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48),
        Text(
          'You are all set! 🎉',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Visit the dashboard to create groups, log expenses, and invite friends. You can upgrade plans anytime.',
        ),
        const Spacer(),
        FilledButton(
          onPressed: () async {
            await onFinish();
          },
          child: const Text('Go to dashboard'),
        ),
      ],
    );
  }
}

class _OnboardingControls extends StatelessWidget {
  const _OnboardingControls({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Step ${state.step.index + 1} of ${OnboardingStep.values.length}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        const Spacer(),
        TextButton(
          onPressed: () => context.read<OnboardingViewModel>().goToNext(),
          child: const Text('Skip'),
        ),
      ],
    );
  }
}
