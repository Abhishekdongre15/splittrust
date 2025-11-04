import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'theme/app_theme.dart';
import '../features/auth/cubit/auth_cubit.dart';
import '../features/auth/cubit/auth_state.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/views/login_view.dart';
import '../features/auth/views/splash_view.dart';
import '../features/buy_plan/cubit/buy_plan_cubit.dart';
import '../features/buy_plan/views/buy_plan_sheet.dart';
import '../features/contacts/cubit/contacts_cubit.dart';
import '../features/dashboard/cubit/dashboard_cubit.dart';
import '../features/dashboard/views/dashboard_view.dart';
import '../features/groups/cubit/group_cubit.dart';
import '../features/groups/data/firebase_group_repository.dart';
import '../features/groups/views/group_list_view.dart';
import '../features/onboarding/cubit/onboarding_cubit.dart';
import '../features/onboarding/views/onboarding_flow_view.dart';
import '../features/reports/views/reports_view.dart';
import '../features/settings/views/settings_view.dart';
import '../features/web/views/web_landing_view.dart';
import '../features/contacts/data/contact_repository.dart';

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
        BlocProvider(create: (_) => AuthCubit(repository: AuthRepository())..initialize()),
        BlocProvider(create: (_) => OnboardingCubit()),
        BlocProvider(create: (_) => DashboardCubit()..load()),
        BlocProvider(create: (_) => BuyPlanCubit()..load()),
        BlocProvider(
          create: (_) => GroupCubit(repository: FirebaseGroupRepository())..load(),
        ),
        BlocProvider(create: (_) => ContactsCubit(repository: ContactRepository())),
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
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          if (state.isNewUser) {
            context.read<OnboardingCubit>().startProfileCapture();
          } else {
            context.read<OnboardingCubit>().finish();
          }
          context.read<ContactsCubit>().load();
          context.read<GroupCubit>().load();
        }
        if (state.status == AuthStatus.unauthenticated) {
          context.read<OnboardingCubit>().start();
        }
      },
      builder: (context, state) {
        if (state.isSplash) {
          return const SplashView();
        }

        switch (state.status) {
          case AuthStatus.splash:
          case AuthStatus.unauthenticated:
          case AuthStatus.sendingOtp:
          case AuthStatus.otpSent:
          case AuthStatus.authenticating:
          case AuthStatus.verifyingOtp:
          case AuthStatus.failure:
            return const LoginView();
          case AuthStatus.authenticated:
            final onboarding = context.watch<OnboardingCubit>().state;
            if (!onboarding.isComplete) {
              return const OnboardingFlowView();
            }
            return const _HomeView();
        }
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
    final navigationBar = NavigationBar(
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      selectedIndex: _index,
      onDestinationSelected: (value) => setState(() => _index = value),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Groups'),
        NavigationDestination(icon: Icon(Icons.insert_drive_file_outlined), selectedIcon: Icon(Icons.insert_drive_file), label: 'Reports'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
      ],
    );

    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          if (_index == 0)
            IconButton(
              tooltip: 'Buy plans',
              icon: const Icon(Icons.workspace_premium_outlined),
              onPressed: () => _openBuyPlans(context),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: IndexedStack(index: _index, children: pages)),
          SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                navigationBar,
                if (_index == 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                    child: FilledButton.icon(
                      onPressed: () => showComingSoonSnackBar(
                        context,
                        'Expense flow opens here',
                      ),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('Add expense'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openBuyPlans(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const BuyPlanSheet(),
    );
    context.read<BuyPlanCubit>().load();
  }
}
