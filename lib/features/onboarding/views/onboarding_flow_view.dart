import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';

class OnboardingFlowView extends StatelessWidget {
  const OnboardingFlowView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: BlocBuilder<OnboardingCubit, OnboardingState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _StepContent(state: state),
                    ),
                  ),
                  _Controls(state: state),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StepContent extends StatelessWidget {
  const _StepContent({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    switch (state.step) {
      case OnboardingStep.welcome:
        return _WelcomeStep(onNext: context.read<OnboardingCubit>().next);
      case OnboardingStep.permissions:
        return _PermissionsStep(state: state);
      case OnboardingStep.auth:
        return _AuthStep(state: state);
      case OnboardingStep.profile:
        return _ProfileStep(state: state);
      case OnboardingStep.done:
        return _ReadyStep(onFinish: context.read<OnboardingCubit>().finish);
    }
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return Row(
      children: [
        if (state.step != OnboardingStep.done)
          FilledButton(
            onPressed: () {
              if (state.step == OnboardingStep.profile) {
                cubit.finish();
              } else {
                cubit.next();
              }
            },
            child: Text(state.step == OnboardingStep.profile ? 'Finish' : 'Continue'),
          ),
        if (state.step == OnboardingStep.done)
          FilledButton(
            onPressed: cubit.finish,
            child: const Text('Go to dashboard'),
          ),
      ],
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome to SplitTrust', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(
          'Track shared expenses, settle up faster, and understand your spending with AI-powered insights.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 28),
        FilledButton(onPressed: onNext, child: const Text('Get started')),
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
        Text('Stay in sync', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Enable notifications to get reminders about due settlements and new expenses.'),
        const SizedBox(height: 24),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: state.notificationsAllowed,
          onChanged: context.read<OnboardingCubit>().allowNotifications,
          title: const Text('Allow notifications'),
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
    final options = {
      AuthMethod.phoneOtp: 'Phone OTP',
      AuthMethod.google: 'Google Sign-In',
      AuthMethod.emailPassword: 'Email & Password',
      AuthMethod.guest: 'Try as guest',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose how to continue', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Guests can explore the product but must link an account before joining shared groups.'),
        const SizedBox(height: 12),
        ...options.entries.map(
          (entry) => RadioListTile<AuthMethod>(
            contentPadding: EdgeInsets.zero,
            value: entry.key,
            groupValue: state.selectedAuthMethod,
            onChanged: (value) {
              if (value != null) {
                context.read<OnboardingCubit>().selectAuth(value);
              }
            },
            title: Text(entry.value),
          ),
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
  late final TextEditingController _name;
  late final TextEditingController _currency;
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.state.name);
    _currency = TextEditingController(text: widget.state.baseCurrency);
    _email = TextEditingController(text: widget.state.email);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Set up your profile', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (value) => value != null && value.trim().length >= 2 ? null : 'Enter at least 2 characters',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _currency,
            decoration: const InputDecoration(labelText: 'Base currency (ISO-4217)'),
            validator: (value) => value != null && value.trim().length == 3 ? null : 'Enter a valid currency code',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email (optional)'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                context.read<OnboardingCubit>().updateProfile(
                      name: _name.text.trim(),
                      currency: _currency.text.trim().toUpperCase(),
                      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
                    );
                context.read<OnboardingCubit>().next();
              }
            },
            child: const Text('Save profile'),
          ),
        ],
      ),
    );
  }
}

class _ReadyStep extends StatelessWidget {
  const _ReadyStep({required this.onFinish});

  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('You are all set!', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Jump into your dashboard to add expenses, invite friends, and explore premium plans.'),
        const SizedBox(height: 24),
        FilledButton(onPressed: onFinish, child: const Text('Go to dashboard')),
      ],
    );
  }
}
