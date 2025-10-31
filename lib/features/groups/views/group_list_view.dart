import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../dashboard/cubit/dashboard_cubit.dart';
import '../../dashboard/cubit/dashboard_state.dart';

class GroupListView extends StatelessWidget {
  const GroupListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state.groups.isEmpty) {
          return const Center(child: Text('No groups yet. Create one to get started.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: state.groups.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final group = state.groups[index];
            return Card(
              child: ListTile(
                title: Text(group.name),
                subtitle: Text('Base currency ${group.baseCurrency}'),
                trailing: Text(
                  group.netBalance >= 0
                      ? '+${group.baseCurrency} ${group.netBalance.toStringAsFixed(2)}'
                      : '-${group.baseCurrency} ${(group.netBalance.abs()).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: group.netBalance >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
