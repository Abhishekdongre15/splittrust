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
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Shared groups',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 16),
              if (groups.isEmpty)
                Expanded(
                  child: _EmptyGroupsView(onCreateTap: () => _showCreateGroupSheet(context)),
                )
              else ...[
                Expanded(
                  child: ListView.separated(
                    itemCount: groups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      return _GroupCard(group: group, onTap: () => _openGroup(context, group.id));
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () => _showCreateGroupSheet(context),
                    icon: const Icon(Icons.group_add),
                    label: const Text('Create group'),
                  ),
                ),
              ],
            ],
          ),
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
                            if (value.length < 2) {
                              return;
                            }
                            final member = cubit.ensureMember(value);
                            setState(() {
                              selectedMembers.add(member);
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
                                final group = await cubit.createGroup(
                                  name: nameController.text,
                                  baseCurrency: baseCurrency,
                                  members: selectedMembers.toList(),
                                  note: noteController.text,
                                );
                                if (group != null && context.mounted) {
                                  navigator.pop();
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Created ${group.name}')), 
                                  );
                                  _openGroup(context, group.id);
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

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.onTap});

  final GroupDetail group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final balances = group.balances.values.toList();
    final outstanding = balances.fold<double>(0, (value, balance) => balance.net > 0 ? value + balance.net : value);
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      group.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${group.baseCurrency} ${outstanding.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Outstanding'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('${group.members.length} members • Total expenses ${group.baseCurrency} ${group.totalExpenses.toStringAsFixed(2)}'),
              const SizedBox(height: 4),
              Text('Settlements ${group.baseCurrency} ${group.totalSettlements.toStringAsFixed(2)}'),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.groups_outlined, size: 72, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No groups yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a group to start tracking shared expenses and settlements.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreateTap,
            icon: const Icon(Icons.group_add),
            label: const Text('Create your first group'),
          ),
        ],
      ),
    );
  }
}
