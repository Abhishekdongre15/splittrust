import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splittrust/features/buy_plan/cubit/buy_plan_cubit.dart';
import 'package:splittrust/features/buy_plan/cubit/buy_plan_state.dart';
import 'package:splittrust/features/buy_plan/models/buy_plan.dart';
import 'package:splittrust/features/buy_plan/views/buy_plan_sheet.dart';
import 'package:splittrust/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:splittrust/features/dashboard/cubit/dashboard_state.dart';
import 'package:splittrust/features/dashboard/models/dashboard_models.dart';


class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        switch (state.status) {
          case DashboardStatus.idle:
          case DashboardStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case DashboardStatus.error:
            return Center(child: Text(state.errorMessage ?? 'Something went wrong'));
          case DashboardStatus.ready:
            final summary = state.summary;
            if (summary == null) {
              return const Center(child: Text('No data yet. Add your first expense!'));
            }
            return RefreshIndicator(
              onRefresh: context.read<DashboardCubit>().load,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _SummaryCards(summary: summary),
                  const SizedBox(height: 24),
                  _GroupSection(groups: state.groups),
                  const SizedBox(height: 24),
                  _ActivitySection(activity: state.activity),
                  const SizedBox(height: 24),
                  _BuyPlanSection(onTap: () => _showPlans(context)),
                ],
              ),
            );
        }
      },
    );
  }

  void _showPlans(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const BuyPlanSheet(),
    );
    context.read<BuyPlanCubit>().load();
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'You Owe',
            amount: summary.youOwe,
            currency: summary.currency,
            color: colorScheme.errorContainer,
            textColor: colorScheme.onErrorContainer,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'You are Owed',
            amount: summary.youAreOwed,
            currency: summary.currency,
            color: colorScheme.primaryContainer,
            textColor: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'Net',
            amount: summary.net,
            currency: summary.currency,
            color: colorScheme.secondaryContainer,
            textColor: colorScheme.onSecondaryContainer,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.currency,
    required this.color,
    required this.textColor,
  });

  final String title;
  final double amount;
  final String currency;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: textColor)),
          Text(
            '$currency ${amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
          ),
        ],
      ),
    );
  }
}

class _GroupSection extends StatelessWidget {
  const _GroupSection({required this.groups});

  final List<GroupSummary> groups;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Groups', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.group_add),
              label: const Text('New group'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (groups.isEmpty)
          const Text('Create your first group to start splitting expenses!')
        else
          ...groups.map(
            (group) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(group.name),
                subtitle: Text('Base currency • ${group.baseCurrency}'),
                trailing: Text(
                  '${group.baseCurrency} ${group.netBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: group.netBalance >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({required this.activity});

  final List<ActivityItem> activity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent activity', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (activity.isEmpty)
          const Text('All quiet! Add an expense to see it here.')
        else
          ...activity.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(item.title),
                subtitle: Text(item.subtitle),
                trailing: Text(
                  timeAgo(item.timestamp),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BuyPlanSection extends StatelessWidget {
  const _BuyPlanSection({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Buy plans', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        BlocBuilder<BuyPlanCubit, BuyPlanState>(
          builder: (context, state) {
            final plans = state.plans;
            if (state.status == BuyPlanStatus.loading && plans.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (plans.isEmpty) {
              return Card(
                child: ListTile(
                  title: const Text('Explore BuyPlan options'),
                  subtitle: const Text('See how Gold and Diamond unlock advanced features.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onTap,
                ),
              );
            }
            return Column(
              children: plans
                  .map(
                    (plan) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: ListTile(
                          title: Text(plan.tier.displayName),
                          subtitle: Text(plan.description),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(plan.priceLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: onTap,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

String timeAgo(DateTime timestamp) {
  final difference = DateTime.now().difference(timestamp);
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  }
  return '${difference.inDays}d ago';
}
