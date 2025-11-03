import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/group_cubit.dart';
import '../cubit/group_state.dart';
import '../models/group_models.dart';

class GroupSettingsPage extends StatefulWidget {
  const GroupSettingsPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<GroupSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupCubit, GroupState>(
      builder: (context, state) {
        final group = state.groupById(widget.groupId);
        if (group == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Group settings')),
            body: const Center(child: Text('Group not found')),
          );
        }
        final cubit = context.read<GroupCubit>();
        final balances = group.balances;
        final currentMemberId = cubit.currentUserId;
        final isAdmin = group.memberById(currentMemberId)?.role == GroupRole.admin;
        final youBalance = balances[currentMemberId];
        final canLeave = (youBalance?.net ?? 0).abs() <= 0.01;
        final theme = Theme.of(context);
        final directory = state.directory;
        final currencyOptions = (<String>{
          'INR',
          'USD',
          'EUR',
          'GBP',
          'AED',
          'SGD',
          'AUD',
        }
              ..add(group.baseCurrency))
            .toList()
          ..sort();

        return Scaffold(
          appBar: AppBar(title: const Text('Group settings')),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Members',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isAdmin)
                    FilledButton.tonalIcon(
                      onPressed: state.isBusy
                          ? null
                          : () => _showAddMemberSheet(cubit, group, directory),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Add member'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ...group.members.map(
                (member) {
                  final balance = balances[member.id]?.net ?? 0;
                  final statusText = _memberStatus(balance, group.baseCurrency);
                  final color = balance < -0.01
                      ? theme.colorScheme.error
                      : balance > 0.01
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant;
                  final amountText = '${group.baseCurrency} ${balance.abs().toStringAsFixed(2)}';
                  final showRemove = isAdmin && member.role != GroupRole.admin && member.id != currentMemberId;
                  final roleLabel = member.role == GroupRole.admin ? 'Admin' : 'Member';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?'),
                      ),
                      title: Text(member.displayName),
                      subtitle: Text('$roleLabel • $statusText'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            amountText,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (showRemove) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              tooltip: 'Remove member',
                              icon: const Icon(Icons.person_remove_alt_1),
                              color: theme.colorScheme.error,
                              onPressed: state.isBusy
                                  ? null
                                  : () => _confirmRemoveMember(cubit, group, member),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Advanced settings',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Group currency',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Balances, expenses and settlements display in ${group.baseCurrency}.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: group.baseCurrency,
                          items: currencyOptions
                              .map(
                                (currency) => DropdownMenuItem<String>(
                                  value: currency,
                                  child: Text(currency),
                                ),
                              )
                              .toList(),
                          onChanged: state.isBusy
                              ? null
                              : (value) {
                                  if (value != null) {
                                    cubit.updateBaseCurrency(groupId: group.id, currency: value);
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: SwitchListTile.adaptive(
                  value: group.simplifyDebts,
                  onChanged: state.isBusy
                      ? null
                      : (value) => cubit.updateSimplifyDebts(groupId: widget.groupId, simplify: value),
                  title: const Text('Simplify group debts'),
                  subtitle: const Text(
                    'Automatically combines debts to reduce the total number of repayments between group members.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  onTap: state.isBusy ? null : () => _showSplitPicker(group),
                  title: Row(
                    children: [
                      const Expanded(child: Text('Default split')),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          'PRO',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    '${group.defaultSplitStrategy.title}\nNew expenses you add to this group will default to this setting, which is personal, not group-wide.',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  title: Text(
                    'Leave group',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    canLeave
                        ? 'Leave this group once you confirm. You will stop seeing its balances.'
                        : 'You can\'t leave this group because you have outstanding debts with other group members.',
                  ),
                  onTap: !canLeave || state.isBusy ? null : () => _confirmLeave(currentMemberId),
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    title: Text(
                      'Delete group',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text('Permanently remove this group and its history for everyone.'),
                    onTap: state.isBusy ? null : _confirmDelete,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static String _memberStatus(double balance, String currency) {
    if (balance.abs() <= 0.01) {
      return 'All settled';
    }
    if (balance < 0) {
      return 'Owes $currency ${balance.abs().toStringAsFixed(2)}';
    }
    return 'Is owed $currency ${balance.abs().toStringAsFixed(2)}';
  }

  Future<void> _showAddMemberSheet(
    GroupCubit cubit,
    GroupDetail group,
    List<MemberProfile> directory,
  ) async {
    final existingIds = group.members.map((member) => member.id).toSet();
    final suggestions = directory
        .where((profile) => !existingIds.contains(profile.id))
        .toList()
      ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    final controller = TextEditingController();

    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setState) {
            final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
            final query = controller.text.trim().toLowerCase();
            final filtered = query.isEmpty
                ? suggestions
                : suggestions
                    .where((profile) => profile.displayName.toLowerCase().contains(query))
                    .toList();

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Add member',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'e.g. Priya Rao',
                    ),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  if (filtered.isNotEmpty) ...[
                    Text(
                      'Suggestions',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final profile in filtered.take(6))
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              profile.displayName.isNotEmpty
                                  ? profile.displayName[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(profile.displayName),
                          onTap: () => Navigator.of(sheetContext).pop(profile.displayName),
                        ),
                      ),
                  ] else
                    Text(
                      'No saved contacts yet. Enter a name to invite a new member.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: controller.text.trim().length >= 2
                        ? () => Navigator.of(sheetContext).pop(controller.text.trim())
                        : null,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Add to group'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    controller.dispose();

    if (name == null || name.trim().length < 2) {
      return;
    }

    await cubit.addMember(groupId: group.id, displayName: name.trim());
  }

  Future<void> _confirmRemoveMember(
    GroupCubit cubit,
    GroupDetail group,
    GroupMember member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove member'),
          content: Text('Remove ${member.displayName} from ${group.name}? Make sure they\'re settled first.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await cubit.removeMember(groupId: group.id, memberId: member.id);
    }
  }

  Future<void> _showSplitPicker(GroupDetail group) async {
    final selected = await showModalBottomSheet<GroupDefaultSplitStrategy>(
      context: context,
      builder: (sheetContext) {
        var tempSelection = group.defaultSplitStrategy;
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Text(
                      'Choose default split',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  for (final strategy in GroupDefaultSplitStrategy.values)
                    RadioListTile<GroupDefaultSplitStrategy>(
                      title: Text(strategy.title),
                      subtitle: Text(strategy.description),
                      value: strategy,
                      groupValue: tempSelection,
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() => tempSelection = value);
                        Navigator.of(sheetContext).pop(value);
                      },
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );

    if (selected == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    if (selected.requiresPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selected.title} is available on Gold and Diamond plans. Upgrade to unlock.')),
      );
      return;
    }

    if (selected != group.defaultSplitStrategy) {
      await context.read<GroupCubit>().updateDefaultSplit(groupId: group.id, strategy: selected);
    }
  }

  Future<void> _confirmLeave(String memberId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Leave group?'),
          content: const Text('Once you leave, you will lose access to this group history unless re-invited.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final success = await context.read<GroupCubit>().leaveGroup(groupId: widget.groupId, memberId: memberId);
    if (success) {
      navigator
        ..pop()
        ..pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('You left the group.')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete group?'),
          content: const Text('This permanently removes the group for everyone. This action cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final success = await context.read<GroupCubit>().deleteGroup(groupId: widget.groupId);
    if (success) {
      navigator
        ..pop()
        ..pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Group deleted.')),
      );
    }
  }
}
