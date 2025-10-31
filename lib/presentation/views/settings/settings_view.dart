import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../viewmodels/settings/settings_state.dart';
import '../../viewmodels/settings/settings_view_model.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: BlocBuilder<SettingsViewModel, SettingsState>(
        builder: (context, state) {
          return ListView(
            children: [
              ListTile(
                title: const Text('Biometric / PIN lock'),
                subtitle: const Text('Protect sensitive balances on shared devices'),
                trailing: Switch(
                  value: state.lockEnabled,
                  onChanged: (value) => context.read<SettingsViewModel>().toggleLock(value),
                ),
              ),
              const Divider(),
              ListTile(
                title: const Text('Language'),
                subtitle: Text(state.language == 'en' ? 'English' : 'Hindi'),
                onTap: () => _showLanguageSheet(context, state.language),
              ),
              ListTile(
                title: const Text('Theme'),
                subtitle: Text(state.theme.name),
                onTap: () => _showThemeSheet(context, state.theme),
              ),
              const Divider(),
              ListTile(
                title: const Text('Data export'),
                subtitle: const Text('Download your personal data archive (.zip)'),
                leading: const Icon(Icons.archive_outlined, color: AppColors.primary),
                onTap: () {},
              ),
              ListTile(
                title: const Text('Delete account'),
                subtitle: const Text('Account will be removed after 7-day grace period'),
                leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                onTap: () {},
              ),
              const Divider(),
              ListTile(
                title: const Text('Support'),
                subtitle: const Text('Email support@splittrust.app or raise a ticket'),
                leading: const Icon(Icons.support_agent, color: AppColors.primary),
                onTap: () {},
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, String current) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<String>(
            value: 'en',
            groupValue: current,
            onChanged: (value) {
              if (value != null) {
                context.read<SettingsViewModel>().changeLanguage(value);
                Navigator.pop(context);
              }
            },
            title: const Text('English'),
          ),
          RadioListTile<String>(
            value: 'hi',
            groupValue: current,
            onChanged: (value) {
              if (value != null) {
                context.read<SettingsViewModel>().changeLanguage(value);
                Navigator.pop(context);
              }
            },
            title: const Text('हिन्दी'),
          ),
        ],
      ),
    );
  }

  void _showThemeSheet(BuildContext context, AppThemePreference current) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: AppThemePreference.values
            .map(
              (preference) => RadioListTile<AppThemePreference>(
                value: preference,
                groupValue: current,
                onChanged: (value) {
                  if (value != null) {
                    context.read<SettingsViewModel>().changeTheme(value);
                    Navigator.pop(context);
                  }
                },
                title: Text(preference.name),
              ),
            )
            .toList(),
      ),
    );
  }
}
