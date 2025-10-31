import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/group.dart';
import '../../../domain/services/balance_engine.dart';
import '../../viewmodels/group/group_state.dart';
import '../../viewmodels/group/group_view_model.dart';

class GroupView extends StatefulWidget {
  const GroupView({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupView> createState() => _GroupViewState();
}

class _GroupViewState extends State<GroupView> with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group details'),
        bottom: TabBar(
          controller: _controller,
          tabs: const [
            Tab(text: 'Activity'),
            Tab(text: 'Balances'),
            Tab(text: 'Expenses'),
          ],
        ),
      ),
      body: BlocBuilder<GroupViewModel, GroupState>(
        builder: (context, state) {
          switch (state.status) {
            case GroupStatus.initial:
            case GroupStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case GroupStatus.error:
              return const Center(child: Text('Unable to load group'));
            case GroupStatus.ready:
              final group = state.group!;
              return TabBarView(
                controller: _controller,
                children: [
                  _ActivityTab(group: group),
                  _BalancesTab(group: group),
                  _ExpensesTab(state: state),
                ],
              );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Last updated ${group.updatedAt.toLocal()}'),
        const SizedBox(height: 12),
        ...group.expenses.take(10).map(
          (expense) => ListTile(
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Text('${expense.title} · ${expense.category.name.toUpperCase()}'),
            subtitle: Text('Paid by ${expense.payerUid} • ${expense.createdAt.toLocal()}'),
            trailing: Text('${group.baseCurrency} ${expense.amountBase.toStringAsFixed(2)}'),
          ),
        ),
        const SizedBox(height: 16),
        ...group.settlements.map(
          (settlement) => ListTile(
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Text('Settlement: ${settlement.fromUid} → ${settlement.toUid}'),
            subtitle: Text('${settlement.method.name} • ${settlement.createdAt.toLocal()}'),
            trailing: Text('${settlement.currency} ${settlement.amount.toStringAsFixed(2)}'),
          ),
        ),
      ],
    );
  }
}

class _BalancesTab extends StatelessWidget {
  const _BalancesTab({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    final engine = BalanceEngine(baseCurrency: group.baseCurrency);
    final balance = engine.calculate(group);
    final suggestions = engine.suggest(group.members.toSet(), balance.netByUser);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Net balances', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...balance.netByUser.entries.map(
            (entry) => ListTile(
              tileColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(entry.key),
              trailing: Text('${entry.value.currency} ${entry.value.value.toStringAsFixed(2)}'),
            ),
          ),
          const SizedBox(height: 24),
          Text('Smart settlement suggestions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (suggestions.isEmpty)
            const Text('All settled. 🎉')
          else
            ...suggestions.map(
              (suggestion) => ListTile(
                tileColor: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.swap_horiz, color: AppColors.primary),
                title: Text('₹${suggestion.amount.toStringAsFixed(2)} from ${suggestion.fromUid} to ${suggestion.toUid}'),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExpensesTab extends StatelessWidget {
  const _ExpensesTab({required this.state});

  final GroupState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search title or notes',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
                  ),
                  onChanged: context.read<GroupViewModel>().search,
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<ExpenseCategory?>(
                value: state.filterCategory,
                hint: const Text('Category'),
                onChanged: (value) => context.read<GroupViewModel>().updateCategory(value),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...ExpenseCategory.values.map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category.name),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SwitchListTile(
          value: state.hasReceiptOnly,
          onChanged: (value) => context.read<GroupViewModel>().toggleReceiptOnly(value),
          title: const Text('Only show expenses with receipts'),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemBuilder: (context, index) {
              final expense = state.filteredExpenses[index];
              return ListTile(
                tileColor: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                title: Text(expense.title),
                subtitle: Text('${expense.category.name} • Paid by ${expense.payerUid}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${expense.amountBase.toStringAsFixed(2)} ${state.group?.baseCurrency ?? ''}'),
                    if (expense.receiptUrl != null)
                      const Text('Receipt attached', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: state.filteredExpenses.length,
          ),
        ),
      ],
    );
  }
}
