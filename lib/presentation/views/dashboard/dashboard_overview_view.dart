import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../domain/entities/activity_event.dart';
import '../../../domain/entities/plan_tier.dart';
import '../../../domain/services/balance_engine.dart';
import '../../viewmodels/dashboard/dashboard_state.dart';
import '../../viewmodels/dashboard/dashboard_view_model.dart';
import 'plan_selection_view.dart';

class DashboardOverviewView extends StatelessWidget {
  const DashboardOverviewView({super.key, required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardViewModel, DashboardState>(
      builder: (context, state) {
        switch (state.status) {
          case DashboardStatus.initial:
          case DashboardStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case DashboardStatus.error:
            return _DashboardError(message: state.error ?? 'Failed to load dashboard');
          case DashboardStatus.ready:
            return _DashboardContent(state: state, onUpgrade: onUpgrade);
        }
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.state, required this.onUpgrade});

  final DashboardState state;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final balance = state.balanceResult;
    final selectedGroup = state.selectedGroup;
    return RefreshIndicator(
      onRefresh: () => context.read<DashboardViewModel>().refreshActivity(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${state.user?.name ?? 'SplitTrust User'}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current plan: ${state.plan.name.toUpperCase()}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onUpgrade,
                icon: const Icon(Icons.workspace_premium_rounded),
                tooltip: 'Upgrade plan',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (selectedGroup != null) ...[
            if (balance != null) _BalanceCards(balance: balance),
            const SizedBox(height: 24),
            _GroupSelector(state: state),
            const SizedBox(height: 16),
            _QuickActions(plan: state.plan, onUpgrade: onUpgrade),
            const SizedBox(height: 24),
            _RecentActivity(activity: state.activity),
            const SizedBox(height: 24),
            _SmartSettlements(suggestions: state.suggestions, plan: state.plan, onUpgrade: onUpgrade),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.group_add_outlined, size: 48, color: AppColors.primary),
                  const SizedBox(height: 12),
                  Text(
                    'No groups yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first group to start tracking shared expenses.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.group_add),
                    label: const Text('Create group'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BalanceCards extends StatelessWidget {
  const _BalanceCards({required this.balance});

  final BalanceEngineResult balance;

  @override
  Widget build(BuildContext context) {
    final entries = [
      _BalanceEntry(
        title: 'You owe',
        value: balance.totalOwe.value,
        currency: balance.totalOwe.currency,
        icon: Icons.call_made,
        color: Colors.deepOrange,
      ),
      _BalanceEntry(
        title: 'You are owed',
        value: balance.totalOwed.value,
        currency: balance.totalOwed.currency,
        icon: Icons.call_received,
        color: Colors.teal,
      ),
      _BalanceEntry(
        title: 'Net position',
        value: balance.totalOwed.value - balance.totalOwe.value,
        currency: balance.totalOwed.currency,
        icon: Icons.balance,
        color: AppColors.primary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        if (isWide) {
          return Row(
            children: [
              for (var i = 0; i < entries.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == entries.length - 1 ? 0 : 12),
                    child: _BalanceCard(entry: entries[i]),
                  ),
                ),
            ],
          );
        }
        return Column(
          children: [
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BalanceCard(entry: entry),
              ),
          ],
        );
      },
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.entry});

  final _BalanceEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(entry.icon, color: entry.color),
          const SizedBox(height: 8),
          Text(
            entry.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            '${entry.currency} ${entry.value.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _BalanceEntry {
  const _BalanceEntry({
    required this.title,
    required this.value,
    required this.currency,
    required this.icon,
    required this.color,
  });

  final String title;
  final double value;
  final String currency;
  final IconData icon;
  final Color color;
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.plan, required this.onUpgrade});

  final PlanType plan;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickActionButton(
        label: 'Add expense',
        icon: Icons.add_circle_outline,
        onTap: () {},
      ),
      _QuickActionButton(
        label: 'Create group',
        icon: Icons.group_add_outlined,
        onTap: () {},
      ),
      _QuickActionButton(
        label: 'Settle up',
        icon: Icons.currency_rupee,
        onTap: () {},
      ),
      _QuickActionButton(
        label: plan == PlanType.diamond ? 'Premium themes' : 'Upgrade plan',
        icon: Icons.workspace_premium,
        onTap: onUpgrade,
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items,
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.activity});

  final List<ActivityEvent> activity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.read<DashboardViewModel>().refreshActivity(),
              child: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (activity.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text('No activity yet.'),
          )
        else
          ...activity.take(10).map(
                (event) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(_activityIcon(event.type), color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              event.subtitle,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (event.amountText != null)
                        Text(
                          event.amountText!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              ),
      ],
    );
  }

  IconData _activityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.expenseAdded:
        return Icons.receipt_long;
      case ActivityType.expenseEdited:
        return Icons.edit_note;
      case ActivityType.expenseDeleted:
        return Icons.delete_outline;
      case ActivityType.settlementAdded:
        return Icons.currency_rupee;
      case ActivityType.settlementReverted:
        return Icons.undo;
      case ActivityType.planChanged:
        return Icons.workspace_premium;
    }
  }
}

class _SmartSettlements extends StatelessWidget {
  const _SmartSettlements({required this.suggestions, required this.plan, required this.onUpgrade});

  final List<SmartSettlementSuggestion> suggestions;
  final PlanType plan;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final isDiamond = plan == PlanType.diamond;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Smart settlement suggestions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              if (!isDiamond)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Diamond'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!isDiamond)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upgrade to Diamond to unlock AI-powered settlement optimisation.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onUpgrade,
                  icon: const Icon(Icons.workspace_premium_outlined),
                  label: const Text('View Diamond benefits'),
                ),
              ],
            )
          else if (suggestions.isEmpty)
            Text(
              'You are already settled. 🎉',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            Column(
              children: suggestions
                  .map(
                    (suggestion) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.swap_horiz, color: AppColors.primary),
                      title: Text('Transfer ₹${suggestion.amount.toStringAsFixed(2)}'),
                      subtitle: Text('${suggestion.fromUid} → ${suggestion.toUid}'),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _GroupSelector extends StatelessWidget {
  const _GroupSelector({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final groups = state.groups;
    return Row(
      children: [
        const Text('Group:'),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: state.selectedGroup?.id,
            items: groups
                .map(
                  (group) => DropdownMenuItem(
                    value: group.id,
                    child: Text(group.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                context.read<DashboardViewModel>().selectGroup(value);
              }
            },
            decoration: const InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
          //    borderRadius: BorderRadius.all(Radius.circular(14)),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.read<DashboardViewModel>().load(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
