import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/group_cubit.dart';
import '../cubit/group_state.dart';
import '../models/group_models.dart';
import 'group_settings_view.dart';

class GroupDetailPage extends StatelessWidget {
  const GroupDetailPage({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return BlocListener<GroupCubit, GroupState>(
      listenWhen: (previous, current) => previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        final error = state.errorMessage;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
          context.read<GroupCubit>().clearError();
        }
      },
      child: BlocBuilder<GroupCubit, GroupState>(
        builder: (context, state) {
          final group = state.groupById(groupId);
          if (group == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Group details')),
              body: const Center(child: Text('Group not found')), 
            );
          }
          return DefaultTabController(
            length: 4,
            child: Scaffold(
              appBar: AppBar(
                title: Text(group.name),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => _openSettings(context, group),
                  ),
                ],
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Overview'),
                    Tab(text: 'Expenses'),
                    Tab(text: 'Settlements'),
                    Tab(text: 'History'),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => _showActionSheet(context, group),
                child: const Icon(Icons.add),
              ),
              body: TabBarView(
                children: [
                  _OverviewTab(group: group),
                  _ExpensesTab(group: group),
                  _SettlementsTab(group: group),
                  _HistoryTab(group: group),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showActionSheet(BuildContext context, GroupDetail group) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('Add equal expense'),
                subtitle: const Text('Split an amount equally across selected members'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showAddExpenseSheet(context, group);
                },
              ),
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: const Text('Record settlement'),
                subtitle: const Text('Log a payment between two members'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showAddSettlementSheet(context, group);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openSettings(BuildContext context, GroupDetail group) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GroupSettingsPage(groupId: group.id),
      ),
    );
  }

  Future<void> _showAddExpenseSheet(BuildContext context, GroupDetail group) async {
    final cubit = context.read<GroupCubit>();
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    const categories = ['Food', 'Travel', 'Rent', 'Shopping', 'Utilities', 'Activities', 'Other'];
    var selectedCategory = categories.first;
    var paidBy = group.members.first.id;
    final selectedParticipants = group.members.map((member) => member.id).toSet();
    final messenger = ScaffoldMessenger.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setState) {
            final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
            final canSubmit = titleController.text.trim().length >= 2 &&
                (double.tryParse(amountController.text.trim()) ?? 0) > 0 &&
                selectedParticipants.length >= 2;
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
                            'Add expense',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(onPressed: () => Navigator.of(sheetContext).pop(), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Team dinner'),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      decoration: InputDecoration(labelText: 'Amount (${group.baseCurrency})'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Category'),
                      value: selectedCategory,
                      items: [
                        for (final category in categories)
                          DropdownMenuItem(value: category, child: Text(category)),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedCategory = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Paid by'),
                      value: paidBy,
                      items: [
                        for (final member in group.members)
                          DropdownMenuItem(value: member.id, child: Text(member.displayName)),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => paidBy = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Participants', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final member in group.members)
                          FilterChip(
                            label: Text(member.displayName),
                            selected: selectedParticipants.contains(member.id),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedParticipants.add(member.id);
                                } else {
                                  selectedParticipants.remove(member.id);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notes (optional)'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: canSubmit
                            ? () async {
                                final amount = double.tryParse(amountController.text.trim()) ?? 0;
                                FocusScope.of(sheetContext).unfocus();
                                await cubit.addEqualExpense(
                                  groupId: group.id,
                                  title: titleController.text,
                                  amount: amount,
                                  paidBy: paidBy,
                                  participantIds: selectedParticipants.toList(),
                                  category: selectedCategory,
                                  notes: notesController.text,
                                );
                                if (!context.mounted) {
                                  return;
                                }
                                final latestState = cubit.state;
                                if (latestState.status != GroupStatus.error) {
                                  Navigator.of(sheetContext).pop();
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Added ${titleController.text.trim()}')),
                                  );
                                }
                              }
                            : null,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Save expense'),
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

  Future<void> _showAddSettlementSheet(BuildContext context, GroupDetail group) async {
    final cubit = context.read<GroupCubit>();
    final amountController = TextEditingController();
    final referenceController = TextEditingController();
    const methods = ['cash', 'upi_note', 'upi_intent', 'razorpay_link'];
    var fromMember = group.members.first.id;
    var toMember = group.members.last.id;
    if (fromMember == toMember && group.members.length > 1) {
      toMember = group.members.firstWhere((member) => member.id != fromMember).id;
    }
    var method = methods.first;
    final messenger = ScaffoldMessenger.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setState) {
            final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
            final amountValue = double.tryParse(amountController.text.trim()) ?? 0;
            final canSubmit = amountValue > 0 && fromMember != toMember;
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
                            'Record settlement',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(onPressed: () => Navigator.of(sheetContext).pop(), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Paid by'),
                      value: fromMember,
                      items: [
                        for (final member in group.members)
                          DropdownMenuItem(value: member.id, child: Text(member.displayName)),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            fromMember = value;
                            if (fromMember == toMember && group.members.length > 1) {
                              final alternative = group.members.firstWhere(
                                (member) => member.id != fromMember,
                                orElse: () => group.members.first,
                              );
                              toMember = alternative.id;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Paid to'),
                      value: toMember,
                      items: [
                        for (final member in group.members)
                          DropdownMenuItem(value: member.id, child: Text(member.displayName)),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => toMember = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      decoration: InputDecoration(labelText: 'Amount (${group.baseCurrency})'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Method'),
                      value: method,
                      items: [
                        for (final entry in methods)
                          DropdownMenuItem(value: entry, child: Text(entry)),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => method = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: referenceController,
                      decoration: const InputDecoration(labelText: 'Reference (optional)'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: canSubmit
                            ? () async {
                                FocusScope.of(sheetContext).unfocus();
                                await cubit.recordSettlement(
                                  groupId: group.id,
                                  fromMemberId: fromMember,
                                  toMemberId: toMember,
                                  amount: amountValue,
                                  method: method,
                                  reference: referenceController.text,
                                );
                                if (!context.mounted) {
                                  return;
                                }
                                final latestState = cubit.state;
                                if (latestState.status != GroupStatus.error) {
                                  Navigator.of(sheetContext).pop();
                                  messenger.showSnackBar(
                                    SnackBar(content: const Text('Settlement recorded')),
                                  );
                                }
                              }
                            : null,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Save settlement'),
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

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.group});

  final GroupDetail group;

  @override
  Widget build(BuildContext context) {
    final balances = group.balances;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Base currency: ${group.baseCurrency}'),
                if (group.note != null) ...[
                  const SizedBox(height: 8),
                  Text(group.note!),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Member balances', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        for (final member in group.members)
          _MemberBalanceTile(
            member: member,
            balance: balances[member.id],
            currency: group.baseCurrency,
          ),
      ],
    );
  }
}

class _MemberBalanceTile extends StatelessWidget {
  const _MemberBalanceTile({required this.member, required this.balance, required this.currency});

  final GroupMember member;
  final MemberBalance? balance;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final amount = balance?.net ?? 0;
    final theme = Theme.of(context);
    final color = amount >= 0 ? Colors.green : Colors.red;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    member.displayName,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  '$currency ${amount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _BalanceBreakdownRow(label: 'Paid', value: balance?.paid ?? 0, currency: currency),
            _BalanceBreakdownRow(label: 'Owes', value: balance?.owed ?? 0, currency: currency),
            _BalanceBreakdownRow(label: 'Received', value: balance?.settlementsIn ?? 0, currency: currency),
            _BalanceBreakdownRow(label: 'Sent', value: balance?.settlementsOut ?? 0, currency: currency),
          ],
        ),
      ),
    );
  }
}

class _BalanceBreakdownRow extends StatelessWidget {
  const _BalanceBreakdownRow({required this.label, required this.value, required this.currency});

  final String label;
  final double value;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label)),
          Expanded(
            child: Text('$currency ${value.toStringAsFixed(2)}'),
          ),
        ],
      ),
    );
  }
}

class _ExpensesTab extends StatelessWidget {
  const _ExpensesTab({required this.group});

  final GroupDetail group;

  @override
  Widget build(BuildContext context) {
    final expenses = List<GroupExpense>.from(group.expenses)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (expenses.isEmpty) {
      return const _EmptyTabMessage(
        icon: Icons.receipt_long,
        message: 'No expenses yet. Log one to start tracking splits.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: expenses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final expense = expenses[index];
        final payer = group.memberById(expense.paidBy)?.displayName ?? 'Unknown';
        final initial = expense.title.isNotEmpty ? expense.title[0].toUpperCase() : '?';
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(initial)),
            title: Text(expense.title),
            subtitle: Text('$payer • ${_formatDate(expense.createdAt)}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${group.baseCurrency} ${expense.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(expense.category),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SettlementsTab extends StatelessWidget {
  const _SettlementsTab({required this.group});

  final GroupDetail group;

  @override
  Widget build(BuildContext context) {
    final settlements = List<GroupSettlement>.from(group.settlements)
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    if (settlements.isEmpty) {
      return const _EmptyTabMessage(
        icon: Icons.payments_outlined,
        message: 'No settlements recorded yet.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: settlements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final settlement = settlements[index];
        final from = group.memberById(settlement.fromMemberId)?.displayName ?? 'Unknown';
        final to = group.memberById(settlement.toMemberId)?.displayName ?? 'Unknown';
        return Card(
          child: ListTile(
            leading: const Icon(Icons.compare_arrows),
            title: Text('$from → $to'),
            subtitle: Text('${settlement.method} • ${_formatDate(settlement.recordedAt)}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${group.baseCurrency} ${settlement.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (settlement.reference != null) ...[
                  const SizedBox(height: 4),
                  Text(settlement.reference!, style: const TextStyle(fontSize: 12)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.group});

  final GroupDetail group;

  @override
  Widget build(BuildContext context) {
    final history = group.orderedHistory;
    if (history.isEmpty) {
      return const _EmptyTabMessage(
        icon: Icons.history,
        message: 'No history available yet.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = history[index];
        final icon = _iconForHistory(entry.type);
        return Card(
          child: ListTile(
            leading: Icon(icon),
            title: Text(entry.title),
            subtitle: Text('${entry.subtitle}\n${_formatDate(entry.timestamp)}'),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  IconData _iconForHistory(GroupHistoryType type) {
    switch (type) {
      case GroupHistoryType.groupCreated:
        return Icons.group_work_outlined;
      case GroupHistoryType.memberAdded:
        return Icons.person_add_alt;
      case GroupHistoryType.expenseAdded:
        return Icons.receipt_long;
      case GroupHistoryType.settlementRecorded:
        return Icons.payments_outlined;
      case GroupHistoryType.note:
        return Icons.sticky_note_2_outlined;
    }
  }
}

class _EmptyTabMessage extends StatelessWidget {
  const _EmptyTabMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime timestamp) {
  final months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final month = months[timestamp.month - 1];
  final day = timestamp.day.toString().padLeft(2, '0');
  final year = timestamp.year;
  final hour = timestamp.hour.toString().padLeft(2, '0');
  final minute = timestamp.minute.toString().padLeft(2, '0');
  return '$month $day, $year • $hour:$minute';
}
