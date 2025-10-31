import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'theme/app_theme.dart';
import '../features/dashboard/cubit/dashboard_cubit.dart';
import '../features/dashboard/views/dashboard_view.dart';
import '../features/groups/views/group_list_view.dart';
import '../features/onboarding/cubit/onboarding_cubit.dart';
import '../features/onboarding/cubit/onboarding_state.dart';
import '../features/onboarding/views/onboarding_flow_view.dart';
import '../features/plans/cubit/plan_cubit.dart';
import '../features/reports/views/reports_view.dart';
import '../features/settings/views/settings_view.dart';
import '../features/web/views/web_landing_view.dart';

class SplitTrustApp extends StatelessWidget {
  const SplitTrustApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return MaterialApp(
        title: 'SplitTrust',
        theme: SplitTrustTheme.light(),
        debugShowCheckedModeBanner: false,
        home: const WebLandingView(),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => OnboardingCubit()..start()),
        BlocProvider(create: (_) => DashboardCubit()..load()),
        BlocProvider(create: (_) => PlanCubit()..load()),
      ],
      child: MaterialApp(
        title: 'SplitTrust',
        theme: SplitTrustTheme.light(),
        debugShowCheckedModeBanner: false,
        home: const _RootMobileView(),
      ),
    );
  }
}

class _RootMobileView extends StatelessWidget {
  const _RootMobileView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        if (!state.isComplete) {
          return const OnboardingFlowView();
        }
        return const _HomeView();
      },
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardView(),
      const GroupListView(),
      const ReportsView(),
      const SettingsView(),
    ];
    final titles = ['Dashboard', 'Groups', 'Reports', 'Settings'];
    return Scaffold(
      appBar: AppBar(title: Text(titles[_index])),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Groups'),
          NavigationDestination(icon: Icon(Icons.insert_drive_file_outlined), selectedIcon: Icon(Icons.insert_drive_file), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
