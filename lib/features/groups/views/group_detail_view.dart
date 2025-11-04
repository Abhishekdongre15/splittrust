import 'package:characters/characters.dart';
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
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppBar(
                elevation: 0,
                title: Text(group.name),
                flexibleSpace: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF36A876), Color(0xFF5CC499)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => _openSettings(context, group),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(88),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Material(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(24),
                      child: TabBar(
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFFFFF), Color(0xFFE8FFF4)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        labelColor: Theme.of(context).colorScheme.primary,
                        unselectedLabelColor: Colors.white.withOpacity(0.85),
                        labelStyle: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                        tabs: const [
                          Tab(icon: Icon(Icons.insights_outlined), text: 'Overview'),
                          Tab(icon: Icon(Icons.receipt_long), text: 'Expenses'),
                          Tab(icon: Icon(Icons.swap_horiz_rounded), text: 'Settlements'),
                          Tab(icon: Icon(Icons.history), text: 'History'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
              floatingActionButton: SafeArea(
                minimum: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                child: FloatingActionButton.extended(
                  onPressed: () => _showActionSheet(context, group),
                  icon: const Icon(Icons.add_circle_rounded),
                  label: const Text('Add expense'),
                ),
              ),
              body: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF4FAF6), Color(0xFFF0F7F2)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: TabBarView(
                  children: [
                    _OverviewTab(group: group),
                    _ExpensesTab(group: group),
                    _SettlementsTab(group: group),
                    _HistoryTab(group: group),
                  ],
                ),
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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<GroupCubit>(),
        child: _AddExpenseSheet(group: group),
      ),
    );
  }

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet({required this.group});

  final GroupDetail group;

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late String _selectedCategory;
  late String _paidBy;
  late DateTime _selectedDate;
  late Set<String> _selectedParticipantIds;

  static const _categories = ['Food', 'Travel', 'Rent', 'Shopping', 'Utilities', 'Activities', 'Other'];

  GroupDetail get _group => widget.group;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _amountController = TextEditingController();
    _notesController = TextEditingController();
    _selectedCategory = _categories.first;
    _paidBy = _group.members.first.id;
    _selectedDate = DateTime.now();
    _selectedParticipantIds = _group.members.map((member) => member.id).toSet();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isAllSelected => _selectedParticipantIds.length == _group.members.length;

  bool get _canSubmit {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    return _titleController.text.trim().length >= 2 && amount > 0 && _selectedParticipantIds.length >= 2;
  }

  String get _participantSummary {
    if (_isAllSelected) {
      return 'All of ${_group.name}';
    }
    final selectedNames = _group.members
        .where((member) => _selectedParticipantIds.contains(member.id))
        .map((member) => member.displayName)
        .toList();
    if (selectedNames.length == 1) {
      return selectedNames.first;
    }
    if (selectedNames.length == 2) {
      return '${selectedNames.first} & ${selectedNames.last}';
    }
    return '${selectedNames.take(2).join(', ')} + ${selectedNames.length - 2} more';
  }

  String get _paidByLabel => _group.memberById(_paidBy)?.displayName ?? 'Unknown';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: FractionallySizedBox(
        heightFactor: 0.96,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, -8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: Container(
              color: theme.colorScheme.surface,
              child: SafeArea(
                top: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Add expense', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text('With you and: $_participantSummary', style: theme.textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _canSubmit ? _submit : null,
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: theme.colorScheme.outlineVariant)),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      controller: _titleController,
                                      decoration: const InputDecoration(
                                        labelText: 'Enter a description',
                                        border: InputBorder.none,
                                      ),
                                      textCapitalization: TextCapitalization.sentences,
                                      onChanged: (_) => setState(() {}),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Container(
                                          height: 48,
                                          width: 48,
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Icon(Icons.currency_rupee, color: theme.colorScheme.primary),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: TextField(
                                            controller: _amountController,
                                            decoration: InputDecoration(
                                              labelText: '0.00',
                                              helperText: 'in ${_group.baseCurrency}',
                                            ),
                                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text('Split with', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ChoiceChip(
                                  label: Text('All of ${_group.name}'),
                                  selected: _isAllSelected,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedParticipantIds = _group.members.map((member) => member.id).toSet();
                                    });
                                  },
                                ),
                                for (final member in _group.members)
                                  FilterChip(
                                    label: Text(member.displayName),
                                    selected: _selectedParticipantIds.contains(member.id),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedParticipantIds.add(member.id);
                                        } else {
                                          if (_selectedParticipantIds.length <= 2) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Keep at least two participants to split the expense.')),
                                            );
                                            return;
                                          }
                                          _selectedParticipantIds.remove(member.id);
                                        }
                                      });
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: theme.colorScheme.outlineVariant)),
                              elevation: 0,
                              child: Column(
                                children: [
                                  _ActionTile(
                                    icon: Icons.today_outlined,
                                    title: _formatDate(_selectedDate),
                                    subtitle: 'Date',
                                    onTap: _pickDate,
                                  ),
                                  const Divider(height: 1),
                                  _ActionTile(
                                    icon: Icons.person_outline,
                                    title: _paidByLabel,
                                    subtitle: 'Paid by',
                                    onTap: _selectPayer,
                                  ),
                                  const Divider(height: 1),
                                  _ActionTile(
                                    icon: Icons.pie_chart_outline,
                                    title: 'Split equally',
                                    subtitle: 'All selected members',
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Only equal splits are supported in this preview.')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(labelText: 'Category'),
                              borderRadius: BorderRadius.circular(16),
                              value: _selectedCategory,
                              items: [
                                for (final category in _categories)
                                  DropdownMenuItem(value: category, child: Text(category)),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedCategory = value);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'Notes (optional)',
                                hintText: 'Add a comment for your friends',
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _QuickActionButton(
                                  icon: Icons.today,
                                  label: 'Today',
                                  onTap: () => setState(() => _selectedDate = DateTime.now()),
                                ),
                                _QuickActionButton(
                                  icon: Icons.group,
                                  label: _group.name,
                                  onTap: () {
                                    setState(() {
                                      _selectedParticipantIds = _group.members.map((member) => member.id).toSet();
                                    });
                                  },
                                ),
                                _QuickActionButton(
                                  icon: Icons.camera_alt_outlined,
                                  label: 'Receipt',
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Receipt uploads are coming soon.')),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _canSubmit ? _submit : null,
                                child: const Text('Add expense'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (selected != null) {
      setState(() => _selectedDate = selected);
    }
  }

  Future<void> _selectPayer() async {
    final selection = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Text('Paid by', style: Theme.of(context).textTheme.titleMedium),
              ),
              for (final member in _group.members)
                ListTile(
                  leading: CircleAvatar(child: Text(member.displayName.characters.first.toUpperCase())),
                  title: Text(member.displayName),
                  onTap: () => Navigator.of(context).pop(member.id),
                  selected: member.id == _paidBy,
                ),
            ],
          ),
        );
      },
    );
    if (selection != null) {
      setState(() => _paidBy = selection);
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a description, amount, and at least two participants.')),
      );
      return;
    }

    final cubit = context.read<GroupCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;

    await cubit.addEqualExpense(
      groupId: _group.id,
      title: _titleController.text.trim(),
      amount: amount,
      paidBy: _paidBy,
      participantIds: _selectedParticipantIds.toList(),
      category: _selectedCategory,
      notes: _notesController.text.trim(),
      expenseDate: _selectedDate,
    );

    if (!mounted) return;

    final latestState = cubit.state;
    if (latestState.status == GroupStatus.error) {
      return;
    }

    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text('Added ${_titleController.text.trim()}')),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
        foregroundColor: theme.colorScheme.primary,
        child: Icon(icon),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
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
    final members = group.members;
    final maxNet = balances.values.fold<double>(
      0,
      (previousValue, element) => element.net.abs() > previousValue ? element.net.abs() : previousValue,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
      children: [
        _GroupOverviewHero(group: group),
        const SizedBox(height: 24),
        Text(
          'Member balances',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        if (members.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 8)),
              ],
            ),
            child: const Text('Invite a friend to start splitting expenses.'),
          )
        else
          for (final member in members)
            _MemberBalanceCard(
              member: member,
              balance: balances[member.id],
              currency: group.baseCurrency,
              maxNet: maxNet == 0 ? 1 : maxNet,
            ),
      ],
    );
  }
}

class _GroupOverviewHero extends StatelessWidget {
  const _GroupOverviewHero({required this.group});

  final GroupDetail group;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3FB888), Color(0xFF5FCEA1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 18, offset: const Offset(0, 12)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                child: const Icon(Icons.groups_rounded),
              ),
              const SizedBox(width: 12),
              Text(
                group.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _OverviewStatChip(
                icon: Icons.currency_exchange,
                label: 'Base currency',
                value: group.baseCurrency,
              ),
              _OverviewStatChip(
                icon: Icons.receipt_long,
                label: 'Total expenses',
                value: '${group.baseCurrency} ${group.totalExpenses.toStringAsFixed(2)}',
              ),
              _OverviewStatChip(
                icon: Icons.handshake,
                label: 'Settlements',
                value: '${group.baseCurrency} ${group.totalSettlements.toStringAsFixed(2)}',
              ),
              if (group.note != null && group.note!.isNotEmpty)
                _OverviewStatChip(
                  icon: Icons.sticky_note_2_outlined,
                  label: 'Notes',
                  value: group.note!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewStatChip extends StatelessWidget {
  const _OverviewStatChip({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70)),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberBalanceCard extends StatelessWidget {
  const _MemberBalanceCard({
    required this.member,
    required this.balance,
    required this.currency,
    required this.maxNet,
  });

  final GroupMember member;
  final MemberBalance? balance;
  final String currency;
  final double maxNet;

  @override
  Widget build(BuildContext context) {
    final net = balance?.net ?? 0;
    final positive = net >= 0;
    final progress = (net.abs() / maxNet).clamp(0, 1);
    final accent = positive ? Colors.green.shade600 : Colors.red.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: accent.withOpacity(0.12),
                foregroundColor: accent,
                child: Text(member.displayName.characters.first.toUpperCase()),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      positive ? 'Friends owe ${member.displayName.split(' ').first}' : '${member.displayName.split(' ').first} owes friends',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Net', style: Theme.of(context).textTheme.labelLarge),
                  Text(
                    '$currency ${net.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: accent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _BalanceStatChip(
                icon: Icons.payments,
                label: 'Paid',
                value: balance?.paid ?? 0,
                currency: currency,
                color: Colors.blueGrey,
              ),
              _BalanceStatChip(
                icon: Icons.shopping_cart_checkout,
                label: 'Owes',
                value: balance?.owed ?? 0,
                currency: currency,
                color: Colors.deepOrange,
              ),
              _BalanceStatChip(
                icon: Icons.south_east,
                label: 'Sent',
                value: balance?.settlementsOut ?? 0,
                currency: currency,
                color: Colors.redAccent,
              ),
              _BalanceStatChip(
                icon: Icons.north_east,
                label: 'Received',
                value: balance?.settlementsIn ?? 0,
                currency: currency,
                color: Colors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceStatChip extends StatelessWidget {
  const _BalanceStatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.currency,
    required this.color,
  });

  final IconData icon;
  final String label;
  final double value;
  final String currency;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            '$label • $currency ${value.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w600),
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
      case GroupHistoryType.memberRemoved:
        return Icons.person_remove_alt_1;
      case GroupHistoryType.expenseAdded:
        return Icons.receipt_long;
      case GroupHistoryType.settlementRecorded:
        return Icons.payments_outlined;
      case GroupHistoryType.currencyChanged:
        return Icons.currency_exchange;
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
