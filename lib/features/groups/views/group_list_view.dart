import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/group_cubit.dart';
import '../cubit/group_state.dart';
import '../models/group_models.dart';
import 'group_detail_view.dart';

class GroupListView extends StatelessWidget {
  const GroupListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GroupCubit, GroupState>(
      listenWhen: (previous, current) => previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        final error = state.errorMessage;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
          context.read<GroupCubit>().clearError();
        }
      },
      builder: (context, state) {
        if (state.status == GroupStatus.loading && state.groups.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final groups = state.groups;
        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: context.read<GroupCubit>().load,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    sliver: SliverToBoxAdapter(
                      child: _GroupsHeader(totalGroups: groups.length),
                    ),
                  ),
                  if (groups.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyGroupsView(onCreateTap: () => _showCreateGroupSheet(context)),
                    )
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final group = groups[index];
                            return Padding(
                              padding: EdgeInsets.only(bottom: index == groups.length - 1 ? 160 : 16),
                              child: _GroupCard(
                                group: group,
                                onTap: () => _openGroup(context, group.id),
                              ),
                            );
                          },
                          childCount: groups.length,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (groups.isNotEmpty)
              Positioned(
                right: 24,
                bottom: MediaQuery.of(context).padding.bottom + 96,
                child: FloatingActionButton.extended(
                  onPressed: () => _showCreateGroupSheet(context),
                  icon: const Icon(Icons.group_add_rounded),
                  label: const Text('New group'),
                ),
              ),
          ],
        );
      },
    );
  }

  void _openGroup(BuildContext context, String groupId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<GroupCubit>(),
          child: GroupDetailPage(groupId: groupId),
        ),
      ),
    );
  }

  Future<void> _showCreateGroupSheet(BuildContext context) async {
    final cubit = context.read<GroupCubit>();
    final nameController = TextEditingController();
    final noteController = TextEditingController();
    final newMemberController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    const currencies = ['INR', 'USD', 'EUR', 'GBP', 'AED'];
    var baseCurrency = currencies.first;
    final selectedMembers = <MemberProfile>{};

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setState) {
            final availableMembers = cubit.state.directory;
            final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
            final canSubmit =
                nameController.text.trim().length >= 2 && selectedMembers.length >= 2;
            return Padding(
              padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: bottomInset + 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Create group',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: () => navigator.pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Organise a trip, flat, or office pot in seconds.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Group name',
                        hintText: 'e.g. Goa Getaway',
                      ),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Base currency'),
                      value: baseCurrency,
                      items: [
                        for (final currency in currencies)
                          DropdownMenuItem(value: currency, child: Text(currency)),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => baseCurrency = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Group note (optional)',
                        hintText: 'Add context for members',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    Text('Members', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (availableMembers.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final member in availableMembers)
                            FilterChip(
                              label: Text(member.displayName),
                              selected: selectedMembers.any((selected) => selected.id == member.id),
                              onSelected: (value) {
                                setState(() {
                                  if (value) {
                                    selectedMembers.add(member);
                                  } else {
                                    selectedMembers.removeWhere((selected) => selected.id == member.id);
                                  }
                                });
                              },
                            ),
                        ],
                      )
                    else
                      const Text('Add teammates, friends, or family to start splitting.'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: newMemberController,
                            decoration: const InputDecoration(
                              labelText: 'Invite by name',
                              hintText: 'Enter a new member',
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () {
                            final value = newMemberController.text.trim();
                            if (value.isEmpty) {
                              return;
                            }
                            setState(() {
                              final profile = MemberProfile(id: value.toLowerCase(), displayName: value);
                              selectedMembers.add(profile);
                              newMemberController.clear();
                            });
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: canSubmit
                            ? () async {
                                FocusScope.of(sheetContext).unfocus();
                                await cubit.createGroup(
                                  name: nameController.text,
                                  baseCurrency: baseCurrency,
                                  note: noteController.text,
                                  members: selectedMembers.toList(),
                                );
                                if (!context.mounted) {
                                  return;
                                }
                                final latestState = cubit.state;
                                if (latestState.status != GroupStatus.error) {
                                  Navigator.of(sheetContext).pop();
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Created ${nameController.text.trim()}')), 
                                  );
                                }
                              }
                            : null,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Create group'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _GroupsHeader extends StatelessWidget {
  const _GroupsHeader({required this.totalGroups});

  final int totalGroups;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3FB888), Color(0xFF69D2A5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shared groups',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep every trip, home, and office expense organised with SplitTrust.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white.withOpacity(0.85)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Text(
                  '$totalGroups',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  totalGroups == 1 ? 'group' : 'groups',
                  style:
                      Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.onTap});

  final GroupDetail group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<GroupCubit>().currentUserId;
    final net = group.balances[currentUserId]?.net ?? 0;
    final positive = net >= 0;
    final balanceColor = positive ? Colors.green.shade600 : Colors.red.shade600;
    final chipColor = positive ? Colors.green.shade50 : Colors.red.shade50;

    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.06),
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(group.name.characters.first.toUpperCase()),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Base currency • ${group.baseCurrency}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade500),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: chipColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      positive ? 'Friends owe you' : 'You owe friends',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: balanceColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Net balance', style: Theme.of(context).textTheme.labelLarge),
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
        ),
      ),
    );
  }
}

class _EmptyGroupsView extends StatelessWidget {
  const _EmptyGroupsView({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 160,
              width: 160,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.groups_outlined, size: 72, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'No groups yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first group to start splitting bills, trips, and team spends in seconds.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.group_add),
              label: const Text('Create your first group'),
            ),
          ],
        ),
      ),
    );
  }
}
