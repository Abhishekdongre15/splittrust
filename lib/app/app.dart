import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/group_repository.dart';
import '../data/repositories/mock/mock_group_repository.dart';
import '../data/repositories/mock/mock_user_repository.dart';
import '../data/repositories/user_repository.dart';
import '../presentation/viewmodels/dashboard/dashboard_view_model.dart';
import '../presentation/viewmodels/onboarding/onboarding_view_model.dart';
import '../presentation/viewmodels/plan/plan_view_model.dart';
import '../presentation/viewmodels/reports/reports_view_model.dart';
import '../presentation/viewmodels/settings/settings_view_model.dart';
import '../presentation/views/root/root_view.dart';
import 'theme/app_theme.dart';

class SplitTrustApp extends StatelessWidget {
  const SplitTrustApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<UserRepository>(create: (_) => MockUserRepository()),
        RepositoryProvider<GroupRepository>(create: (_) => MockGroupRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => PlanViewModel()..loadPlans()),
          BlocProvider(create: (context) => OnboardingViewModel(userRepository: context.read<UserRepository>())..start()),
          BlocProvider(
            create: (context) => DashboardViewModel(
              userRepository: context.read<UserRepository>(),
              groupRepository: context.read<GroupRepository>(),
            )..load(),
          ),
          BlocProvider(create: (_) => ReportsViewModel()),
          BlocProvider(create: (_) => SettingsViewModel()),
        ],
        child: MaterialApp(
          title: 'SplitTrust',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const RootView(),
        ),
      ),
    );
  }
}
