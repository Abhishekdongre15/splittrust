import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../buy_plan/cubit/buy_plan_cubit.dart';
import '../../buy_plan/cubit/buy_plan_state.dart';
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

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

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

            final quickActions = [
              _QuickAction(
                icon: Icons.receipt_long_rounded,
                label: 'Add expense',
                color: Theme.of(context).colorScheme.primary,
                onTap: () => _showComingSoon(context, 'Expense flow opens here'),
              ),
              _QuickAction(
                icon: Icons.groups_3_outlined,
                label: 'Create group',
                color: Theme.of(context).colorScheme.tertiary,
                onTap: () => _showComingSoon(context, 'Use Groups tab to invite friends'),
              ),
              _QuickAction(
                icon: Icons.currency_rupee,
                label: 'Settle up',
                color: Theme.of(context).colorScheme.secondary,
                onTap: () => _showComingSoon(context, 'Settlement sheet launches from a group'),
              ),
              _QuickAction(
                icon: Icons.workspace_premium_outlined,
                label: 'Buy plan',
                color: Theme.of(context).colorScheme.primary,
                onTap: () => _showPlans(context),
              ),
            ];

            return RefreshIndicator(
              onRefresh: context.read<DashboardCubit>().load,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    sliver: SliverToBoxAdapter(
                      child: _DashboardHeader(summary: summary),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverToBoxAdapter(
                      child: _QuickActionGrid(actions: quickActions),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    sliver: SliverToBoxAdapter(
                      child: _GroupSection(),
                    ),
                  ),
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
                    sliver: SliverToBoxAdapter(
                      child: _ContactsInviteSection(),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    sliver: SliverToBoxAdapter(
                      child: _ActivityTimeline(activity: state.activity),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    sliver: SliverToBoxAdapter(
                      child: _BuyPlanShowcase(onTap: () => _showPlans(context)),
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

  void _showPlans(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const BuyPlanSheet(),
    );
    context.read<BuyPlanCubit>().load();
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cards = [
      (
        title: 'You owe',
        amount: summary.youOwe,
        icon: Icons.arrow_outward_rounded,
        color: colorScheme.errorContainer,
        textColor: colorScheme.onErrorContainer,
      ),
      (
        title: 'You are owed',
        amount: summary.youAreOwed,
        icon: Icons.arrow_downward_rounded,
        color: colorScheme.primaryContainer,
        textColor: colorScheme.onPrimaryContainer,
      ),
      (
        title: 'Net balance',
        amount: summary.net,
        icon: Icons.stacked_bar_chart_rounded,
        color: colorScheme.secondaryContainer,
        textColor: colorScheme.onSecondaryContainer,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3AAB81), Color(0xFF6AD0A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.white.withOpacity(0.9)),
          ),
          const SizedBox(height: 8),
          Text(
            'Your shared expenses at a glance',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final card in cards)
                _SummaryPill(
                  title: card.title,
                  amount: card.amount,
                  currency: summary.currency,
                  color: card.color.withOpacity(0.85),
                  textColor: card.textColor,
                  icon: card.icon,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.title,
    required this.amount,
    required this.currency,
    required this.color,
    required this.textColor,
    required this.icon,
  });

  final String title;
  final double amount;
  final String currency;
  final Color color;
  final Color textColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: textColor.withOpacity(0.9), fontWeight: FontWeight.w600),
              ),
              Icon(icon, color: textColor.withOpacity(0.9)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$currency ${amount.toStringAsFixed(2)}',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: textColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({required this.actions});

  final List<_QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: actions
              .map(
                (action) => _QuickActionChip(action: action),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: action.color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, color: action.color),
              const SizedBox(width: 12),
              Text(
                action.label,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: action.color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupSection extends StatelessWidget {
  const _GroupSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupCubit, GroupState>(
      builder: (context, state) {
        if (state.status == GroupStatus.loading && state.groups.isEmpty) {
          return Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state.errorMessage != null && state.groups.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'We couldn\'t load your groups. Pull to refresh to try again.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        }

        final groups = state.groups;
        final currentUserId = context.read<GroupCubit>().currentUserId;
        return _GroupCarousel(groups: groups, currentUserId: currentUserId);
      },
    );
  }
}

class _GroupCarousel extends StatelessWidget {
  const _GroupCarousel({required this.groups, required this.currentUserId});

  final List<GroupDetail> groups;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(Icons.group_add, color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Create your first group to start splitting expenses with friends.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your groups',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text('${groups.length} total', style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final group = groups[index];
              final balances = group.balances;
              final net = balances[currentUserId]?.net ?? 0;
              final positive = net >= 0;
              final balanceColor = positive ? Colors.green.shade600 : Colors.red.shade600;
              return Container(
                width: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(group.name.characters.first.toUpperCase()),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            group.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Chip(
                          label: Text(group.baseCurrency),
                          avatar: const Icon(Icons.currency_exchange, size: 18),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Balance', style: Theme.of(context).textTheme.labelLarge),
                            const SizedBox(height: 4),
                            Text(
                              '${group.baseCurrency} ${net.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: balanceColor, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActivityTimeline extends StatelessWidget {
  const _ActivityTimeline({required this.activity});

  final List<ActivityItem> activity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent activity', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        if (activity.isEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(Icons.celebration_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('All settled! Add a new expense to keep things moving.',
                      style: Theme.of(context).textTheme.bodyLarge),
                ),
              ],
            ),
          )
        else
          ...activity.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (item != activity.last)
                        Container(
                          width: 2,
                          height: 36,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              Text(timeAgo(item.timestamp), style: Theme.of(context).textTheme.labelMedium),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(item.subtitle, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
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

class _ContactsInviteSection extends StatelessWidget {
  const _ContactsInviteSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ContactsCubit, ContactsState>(
      builder: (context, state) {
        switch (state.status) {
          case ContactsStatus.idle:
            return const SizedBox.shrink();
          case ContactsStatus.loading:
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(child: CircularProgressIndicator()),
            );
          case ContactsStatus.failure:
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                state.errorMessage ?? 'Unable to load contacts right now',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onErrorContainer),
              ),
            );
          case ContactsStatus.ready:
            final onApp = state.contacts.where((c) => c.isUser).toList();
            final needsInvite = state.contacts.where((c) => !c.isUser).toList();
            if (onApp.isEmpty && needsInvite.isEmpty) {
              return const SizedBox.shrink();
            }

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bring your friends',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sync existing groups instantly or invite friends who have not joined SplitTrust yet.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  if (onApp.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Already on SplitTrust',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final contact in onApp)
                          _FriendChip(contact: contact),
                      ],
                    ),
                  ],
                  if (needsInvite.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Invite from your contacts',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 150,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final contact = needsInvite[index];
                          return _InviteCard(contact: contact);
                        },
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemCount: needsInvite.length,
                      ),
                    ),
                  ],
                ],
              ),
            );
        }
      },
    );
  }
}

class _FriendChip extends StatelessWidget {
  const _FriendChip({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final initials = contact.name.characters.take(2).toString().toUpperCase();
    final colorScheme = Theme.of(context).colorScheme;
    final planLabel = contact.plan.isEmpty ? 'SplitTrust friend' : '${contact.plan} plan';
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: colorScheme.primary,
        child: Text(
          initials,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(planLabel, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      backgroundColor: colorScheme.surface,
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              contact.name.characters.first.toUpperCase(),
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(contact.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(contact.phone, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const Spacer(),
          FilledButton.icon(
            onPressed: contact.invited
                ? null
                : () => context.read<ContactsCubit>().invite(contact),
            icon: Icon(contact.invited ? Icons.check_rounded : Icons.sms_rounded),
            label: Text(contact.invited ? 'Invited' : 'Invite'),
          ),
        ],
      ),
    );
  }
}

class _BuyPlanShowcase extends StatelessWidget {
  const _BuyPlanShowcase({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upgrade to unlock more',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        BlocBuilder<BuyPlanCubit, BuyPlanState>(
          builder: (context, state) {
            final plans = state.plans;
            if (state.status == BuyPlanStatus.loading && plans.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (plans.isEmpty) {
              return _BuyPlanHero(
                title: 'Explore SplitTrust plans',
                subtitle: 'See how Gold and Diamond add OCR, exports, and smart settlements.',
                onTap: onTap,
              );
            }
            return Column(
              children: plans
                  .map(
                    (plan) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _BuyPlanHero(
                        title: plan.tier.displayName,
                        subtitle: plan.description,
                        price: plan.priceLabel,
                        highlight: plan.highlight,
                        onTap: onTap,
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

class _BuyPlanHero extends StatelessWidget {
  const _BuyPlanHero({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.price,
    this.highlight = false,
  });

  final String title;
  final String subtitle;
  final String? price;
  final bool highlight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gradientColors = highlight
        ? const [Color(0xFF46C295), Color(0xFF2DA683)]
        : const [Color(0xFFE9F6F0), Color(0xFFD7EEE4)];
    final textColor = highlight ? Colors.white : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (highlight)
            BoxShadow(
              color: gradientColors.last.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: textColor, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: textColor.withOpacity(0.9)),
                    ),
                  ],
                ),
              ),
              if (price != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: highlight ? Colors.white.withOpacity(0.2) : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    price!,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: textColor, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              backgroundColor: highlight ? Colors.white : Theme.of(context).colorScheme.primary,
              foregroundColor: highlight
                  ? gradientColors.last
                  : Theme.of(context).colorScheme.onPrimary,
            ),
            icon: const Icon(Icons.chevron_right_rounded),
            label: Text(highlight ? 'Buy now' : 'See details'),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
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
