import 'package:flutter/material.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Account & Settings', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            subtitle: const Text('Edit your name, avatar, and base currency.'),
            onTap: () {},
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Security'),
            subtitle: const Text('Enable app lock with PIN or biometrics.'),
            onTap: () {},
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Policies'),
            subtitle: const Text('Terms, privacy, and refund policy.'),
            onTap: () {},
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Delete account'),
            subtitle: const Text('Start the 7-day deletion countdown.'),
            onTap: () {},
          ),
        ),
      ],
    );
  }
}
