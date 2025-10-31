import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../data/repositories/group_repository.dart';
import '../../viewmodels/dashboard/dashboard_state.dart';
import '../../viewmodels/dashboard/dashboard_view_model.dart';
import '../../viewmodels/group/group_view_model.dart';
import 'group_view.dart';

class GroupListView extends StatelessWidget {
  const GroupListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardViewModel, DashboardState>(
      builder: (context, state) {
        if (state.status != DashboardStatus.ready) {
          return const Center(child: CircularProgressIndicator());
        }

        final groups = state.groups;
        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.groups_outlined, size: 60, color: AppColors.primary),
                const SizedBox(height: 12),
                Text(
                  'No groups yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + icon to create your first group.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final group = groups[index];
            return ListTile(
              tileColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(group.name.isNotEmpty ? group.name[0].toUpperCase() : '?'),
              ),
              title: Text(group.name),
              subtitle: Text('${group.members.length} members • Base ${group.baseCurrency}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final repository = context.read<GroupRepository>();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RepositoryProvider.value(
                      value: repository,
                      child: BlocProvider(
                        create: (_) => GroupViewModel(repository: repository)..load(group.id),
                        child: GroupView(groupId: group.id),
                      ),
                    ),
                  ),
                );
              },
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: groups.length,
        );
      },
    );
  }
}
