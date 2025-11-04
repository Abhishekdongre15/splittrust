import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../buy_plan/cubit/buy_plan_cubit.dart';
import '../../buy_plan/views/buy_plan_sheet.dart';
import '../../contacts/cubit/contacts_cubit.dart';
import '../../contacts/cubit/contacts_state.dart';
import '../../contacts/models/contact.dart';
import '../../groups/cubit/group_cubit.dart';
import '../../groups/cubit/group_state.dart';
import '../../groups/models/group_models.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../models/dashboard_models.dart';

enum _DashboardListTab { groups, friends }

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  _DashboardListTab _tab = _DashboardListTab.groups;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ContactsCubit, ContactsState>(
      listenWhen: (previous, current) =>
          previous.lastInvited != current.lastInvited && current.lastInvited != null,
      listener: (context, state) {
        final invited = state.lastInvited;
        if (invited != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sent SplitTrust download link to ${invited.name}')),
          );
        }
      },
      child: BlocBuilder<DashboardCubit, DashboardState>(
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

              final theme = Theme.of(context);
              final groupCubit = context.watch<GroupCubit>();
              final groupState = groupCubit.state;
              final currentUserId = groupCubit.currentUserId;
              final friendBalances = _buildFriendBalances(
                groups: groupState.groups,
                currentUserId: currentUserId,
                directory: groupState.directory,
              );

              return RefreshIndicator(
                onRefresh: () async {
                  await context.read<DashboardCubit>().load();
                  await context.read<GroupCubit>().load();
                  await context.read<ContactsCubit>().load();
                },
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      sliver: SliverToBoxAdapter(child: _DiscountBanner(onTap: () => _openPlans(context))),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverToBoxAdapter(
                        child: _OverallSummaryCard(summary: summary),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      sliver: SliverToBoxAdapter(
                        child: _SuggestionCard(onTap: () => _navigateToGroups(context)),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _tab == _DashboardListTab.groups ? 'Groups' : 'Friends',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            SegmentedButton<_DashboardListTab>(
                              style: SegmentedButton.styleFrom(
                                backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                selectedBackgroundColor: theme.colorScheme.primaryContainer,
                                selectedForegroundColor: theme.colorScheme.onPrimaryContainer,
                              ),
                              segments: const [
                                ButtonSegment(
                                  value: _DashboardListTab.groups,
                                  label: Text('Groups'),
                                  icon: Icon(Icons.groups_rounded),
                                ),
                                ButtonSegment(
                                  value: _DashboardListTab.friends,
                                  label: Text('Friends'),
                                  icon: Icon(Icons.person_rounded),
                                ),
                              ],
                              selected: <_DashboardListTab>{_tab},
                              onSelectionChanged: (selection) {
                                setState(() => _tab = selection.first);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    switch (_tab) {
                      _DashboardListTab.groups => SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverToBoxAdapter(
                            child: _GroupListSection(
                              state: groupState,
                              currentUserId: currentUserId,
                              currency: summary.currency,
                            ),
                          ),
                        ),
                      _DashboardListTab.friends => SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          sliver: SliverToBoxAdapter(
                            child: _FriendListSection(
                              balances: friendBalances,
                              currency: summary.currency,
                            ),
                          ),
                        ),
                    },
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'Recent activity',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverToBoxAdapter(
                        child: _ActivitySection(activity: state.activity),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      sliver: SliverToBoxAdapter(
                        child: _PlanTeaserCard(onTap: () => _openPlans(context)),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                      sliver: SliverToBoxAdapter(
                        child: FilledButton.icon(
                          onPressed: () => _showComingSoon(context, 'Expense flow opens here'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: theme.colorScheme.primary,
                          ),
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          label: const Text('Add expense'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
          }
        },
      ),
    );
  }

  static void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openPlans(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const BuyPlanSheet(),
    );
    context.read<BuyPlanCubit>().load();
  }

  void _navigateToGroups(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Use the Groups tab to create a new group.')),
    );
  }
}

class _DiscountBanner extends StatelessWidget {
  const _DiscountBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7F5BFF), Color(0xFFA684FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.percent_rounded, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '50% off for your first month of SplitTrust Pro',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Unlock smart settlements, OCR receipts, and more premium tools.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _OverallSummaryCard extends StatelessWidget {
  const _OverallSummaryCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final netPositive = summary.net >= 0;
    final headline = netPositive ? 'you are owed' : 'you owe';
    final amount = summary.net.abs();
    final primaryColor = netPositive ? const Color(0xFF0B8A6F) : const Color(0xFFDA4949);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall, $headline',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Icon(Icons.pie_chart_rounded, color: theme.colorScheme.primary),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${summary.currency} ${amount.toStringAsFixed(2)}',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: primaryColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _BalancePill(
                label: 'You owe',
                amount: summary.youOwe,
                currency: summary.currency,
                color: const Color(0xFFDA4949).withOpacity(0.15),
                textColor: const Color(0xFFDA4949),
              ),
              const SizedBox(width: 12),
              _BalancePill(
                label: 'You\'re owed',
                amount: summary.youAreOwed,
                currency: summary.currency,
                color: const Color(0xFF0B8A6F).withOpacity(0.15),
                textColor: const Color(0xFF0B8A6F),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalancePill extends StatelessWidget {
  const _BalancePill({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
    required this.textColor,
  });

  final String label;
  final double amount;
  final String currency;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: textColor)),
            const SizedBox(height: 4),
            Text(
              '${currency} ${amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.home_work_rounded, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Try using SplitTrust with your household',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Share rent, groceries, and utilities effortlessly.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: const Text('Add group'),
          ),
        ],
      ),
    );
  }
}

class _GroupListSection extends StatelessWidget {
  const _GroupListSection({
    required this.state,
    required this.currentUserId,
    required this.currency,
  });

  final GroupState state;
  final String currentUserId;
  final String currency;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case GroupStatus.loading:
      case GroupStatus.mutating:
        return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
      case GroupStatus.error:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Text(state.errorMessage ?? 'Unable to load groups right now'),
        );
      case GroupStatus.ready:
      case GroupStatus.idle:
        if (state.groups.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No groups yet. Start one to keep track of shared expenses.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        final items = state.groups
            .map((group) => _GroupListItemData.fromGroup(group, currentUserId: currentUserId))
            .toList()
          ..sort((a, b) => b.absNet.compareTo(a.absNet));

        return Column(
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _GroupTile(item: item, currency: currency),
              ),
            TextButton(
              onPressed: () => _DashboardViewState._showComingSoon(
                context,
                'Show settled groups will be available soon.',
              ),
              child: const Text('Show settled-up groups'),
            ),
          ],
        );
    }
  }
}

class _GroupListItemData {
  _GroupListItemData({
    required this.group,
    required this.primaryMember,
    required this.statusLine,
    required this.net,
  });

  factory _GroupListItemData.fromGroup(GroupDetail group, {required String currentUserId}) {
    final balances = group.balances;
    final you = balances[currentUserId];
    double net = 0;
    String statusLine = 'All settled here';
    GroupMember? primaryMember;

    if (you != null) {
      net = you.net;
      if (net > 0) {
        final debtors = balances.entries
            .where((entry) => entry.key != currentUserId && entry.value.net < -0.009)
            .toList()
          ..sort((a, b) => a.value.net.compareTo(b.value.net));
        if (debtors.isNotEmpty) {
          final top = debtors.first;
          primaryMember = group.memberById(top.key);
          final amount = top.value.net.abs();
          statusLine = '${primaryMember?.displayName ?? 'Someone'} owes you ${group.baseCurrency} ${amount.toStringAsFixed(2)}';
        } else {
          statusLine = 'Others owe you ${group.baseCurrency} ${net.toStringAsFixed(2)}';
        }
      } else if (net < 0) {
        final creditors = balances.entries
            .where((entry) => entry.key != currentUserId && entry.value.net > 0.009)
            .toList()
          ..sort((a, b) => b.value.net.compareTo(a.value.net));
        if (creditors.isNotEmpty) {
          final top = creditors.first;
          primaryMember = group.memberById(top.key);
          final amount = top.value.net.abs();
          statusLine = 'You owe ${primaryMember?.displayName ?? 'someone'} ${group.baseCurrency} ${amount.toStringAsFixed(2)}';
        } else {
          statusLine = 'You owe others ${group.baseCurrency} ${net.abs().toStringAsFixed(2)}';
        }
      }
    }

    return _GroupListItemData(
      group: group,
      primaryMember: primaryMember,
      statusLine: statusLine,
      net: net,
    );
  }

  final GroupDetail group;
  final GroupMember? primaryMember;
  final String statusLine;
  final double net;

  double get absNet => net.abs();
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.item, required this.currency});

  final _GroupListItemData item;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final netPositive = item.net >= 0;
    final amountColor = netPositive ? const Color(0xFF0B8A6F) : const Color(0xFFDA4949);
    final initials = item.group.name.characters.first.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
            child: Text(
              initials,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.group.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  item.statusLine,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                netPositive ? 'You\'re owed' : 'You owe',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '$currency ${item.net.abs().toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: amountColor,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FriendListSection extends StatelessWidget {
  const _FriendListSection({required this.balances, required this.currency});

  final List<_FriendBalanceData> balances;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (balances.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Invite friends to SplitTrust to keep things even.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Column(
      children: [
        for (final entry in balances)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FriendTile(entry: entry, currency: currency),
          ),
        BlocBuilder<ContactsCubit, ContactsState>(
          builder: (context, state) {
            if (state.status != ContactsStatus.ready) {
              return const SizedBox.shrink();
            }
            final needsInvite = state.contacts.where((c) => !c.isUser).toList();
            if (needsInvite.isEmpty) {
              return const SizedBox.shrink();
            }
            return Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _showInviteSheet(context, needsInvite),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Invite friends to SplitTrust'),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showInviteSheet(BuildContext context, List<Contact> contacts) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(24),
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(contact.name.characters.first.toUpperCase()),
                ),
                title: Text(contact.name),
                subtitle: Text(contact.phone ?? contact.email ?? 'No contact info'),
                trailing: TextButton(
                  onPressed: () => context.read<ContactsCubit>().invite(contact),
                  child: const Text('Send link'),
                ),
              );
            },
            separatorBuilder: (_, __) => const Divider(),
            itemCount: contacts.length,
          ),
        );
      },
    );
  }
}

class _FriendBalanceData {
  _FriendBalanceData({
    required this.id,
    required this.displayName,
    required this.net,
    required Set<String> groups,
  }) : groups = List.unmodifiable((groups.toList()..sort()));

  final String id;
  final String displayName;
  final double net;
  final List<String> groups;
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.entry, required this.currency});

  final _FriendBalanceData entry;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final owesYou = entry.net < 0;
    final amount = entry.net.abs();
    final status = owesYou ? 'owes you' : 'you owe';
    final color = owesYou ? const Color(0xFF0B8A6F) : const Color(0xFFDA4949);
    final initials = entry.displayName.characters.take(2).toString().toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.12),
            child: Text(initials, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${status.capitalizeFirst()} ${currency} ${amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
                ),
                if (entry.groups.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.groups.join(', '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                owesYou ? 'You are owed' : 'You owe',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '$currency ${amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({required this.activity});

  final List<ActivityItem> activity;

  @override
  Widget build(BuildContext context) {
    if (activity.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.celebration_rounded, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'All settled! Add a new expense to keep things moving.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final item in activity)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.receipt_long_rounded),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _timeAgo(item.timestamp),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PlanTeaserCard extends StatelessWidget {
  const _PlanTeaserCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF39AF78), Color(0xFF79D4A5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Do more with SplitTrust Pro',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock smart settlements, OCR, exports, and premium themes for your groups.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF1D7A56)),
            child: const Text('Get SplitTrust Pro'),
          ),
        ],
      ),
    );
  }
}

List<_FriendBalanceData> _buildFriendBalances({
  required List<GroupDetail> groups,
  required String currentUserId,
  required List<MemberProfile> directory,
}) {
  final entries = <String, _FriendBalanceData>{};
  final displayNames = {
    for (final member in directory) member.id: member.displayName,
  };

  for (final group in groups) {
    final members = {
      for (final member in group.members) member.id: member,
    };
    if (!members.containsKey(currentUserId)) {
      continue;
    }

    final pairwiseBalances = <String, double>{};

    for (final expense in group.expenses) {
      final payerId = expense.paidBy;
      if (payerId == currentUserId) {
        for (final share in expense.shares) {
          final memberId = share.memberId;
          if (memberId == currentUserId) continue;
          if (!members.containsKey(memberId)) continue;
          final updated = (pairwiseBalances[memberId] ?? 0) - share.shareAmount;
          pairwiseBalances[memberId] = roundBankers(updated);
        }
      } else {
        for (final share in expense.shares) {
          if (share.memberId != currentUserId) continue;
          if (!members.containsKey(payerId)) break;
          final updated = (pairwiseBalances[payerId] ?? 0) + share.shareAmount;
          pairwiseBalances[payerId] = roundBankers(updated);
          break;
        }
      }
    }

    for (final settlement in group.settlements) {
      if (settlement.fromMemberId == currentUserId) {
        final toMemberId = settlement.toMemberId;
        if (!members.containsKey(toMemberId)) continue;
        final updated = (pairwiseBalances[toMemberId] ?? 0) - settlement.amount;
        pairwiseBalances[toMemberId] = roundBankers(updated);
      } else if (settlement.toMemberId == currentUserId) {
        final fromMemberId = settlement.fromMemberId;
        if (!members.containsKey(fromMemberId)) continue;
        final updated = (pairwiseBalances[fromMemberId] ?? 0) + settlement.amount;
        pairwiseBalances[fromMemberId] = roundBankers(updated);
      }
    }

    for (final entry in pairwiseBalances.entries) {
      final memberId = entry.key;
      if (memberId == currentUserId) continue;
      if (!members.containsKey(memberId)) continue;
      if (entry.value == 0) continue;

      final existing = entries[memberId];
      final updatedGroups = <String>{};
      if (existing != null) {
        updatedGroups.addAll(existing.groups);
      }
      updatedGroups.add(group.name);
      entries[memberId] = _FriendBalanceData(
        id: memberId,
        displayName: displayNames[memberId] ?? members[memberId]!.displayName,
        net: roundBankers((existing?.net ?? 0) + entry.value),
        groups: updatedGroups,
      );
    }
  }

  final list = entries.values.toList()
    ..sort((a, b) {
      final diff = a.net.compareTo(b.net);
      if (diff != 0) return diff;
      return a.displayName.compareTo(b.displayName);
    });
  return list;
}

String _timeAgo(DateTime dateTime) {
  final duration = DateTime.now().difference(dateTime);
  if (duration.inDays >= 1) {
    return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'} ago';
  }
  if (duration.inHours >= 1) {
    return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'} ago';
  }
  if (duration.inMinutes >= 1) {
    return '${duration.inMinutes} minute${duration.inMinutes == 1 ? '' : 's'} ago';
  }
  return 'Just now';
}

extension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    final first = this[0].toUpperCase();
    return first + substring(1);
  }
}

