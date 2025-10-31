import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../viewmodels/dashboard/dashboard_view_model.dart';
import '../../viewmodels/reports/reports_view_model.dart';
import '../dashboard/dashboard_overview_view.dart';
import '../dashboard/plan_selection_view.dart';
import '../groups/group_list_view.dart';
import '../reports/reports_view.dart';
import '../settings/settings_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardOverviewView(onUpgrade: _showPlans),
      const GroupListView(),
      const ReportsView(),
      const SettingsView(),
    ];

    final titles = ['Dashboard', 'Groups', 'Reports', 'Settings'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          if (index == 2) {
            context.read<ReportsViewModel>().setGroups(
                  context.read<DashboardViewModel>().state.groups.map((group) => group.id).toList(),
                );
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Groups'),
          NavigationDestination(icon: Icon(Icons.insert_drive_file_outlined), selectedIcon: Icon(Icons.insert_drive_file), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {},
              icon: const Icon(Icons.group_add),
              label: const Text('Create group'),
            )
          : null,
    );
  }

  void _showPlans() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const FractionallySizedBox(heightFactor: 0.9, child: PlanSelectionView()),
    );
  }
}
