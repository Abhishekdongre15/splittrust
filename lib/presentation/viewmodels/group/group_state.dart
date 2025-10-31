import 'package:equatable/equatable.dart';

import '../../../domain/entities/expense.dart';
import '../../../domain/entities/group.dart';

const _sentinel = Object();

class GroupState extends Equatable {
  const GroupState({
    this.status = GroupStatus.initial,
    this.group,
    this.filterCategory,
    this.filterPayer,
    this.hasReceiptOnly = false,
    this.searchQuery = '',
  });

  final GroupStatus status;
  final Group? group;
  final ExpenseCategory? filterCategory;
  final String? filterPayer;
  final bool hasReceiptOnly;
  final String searchQuery;

  GroupState copyWith({
    GroupStatus? status,
    Group? group,
    Object? filterCategory = _sentinel,
    Object? filterPayer = _sentinel,
    bool? hasReceiptOnly,
    String? searchQuery,
  }) {
    return GroupState(
      status: status ?? this.status,
      group: group ?? this.group,
      filterCategory: filterCategory == _sentinel ? this.filterCategory : filterCategory as ExpenseCategory?,
      filterPayer: filterPayer == _sentinel ? this.filterPayer : filterPayer as String?,
      hasReceiptOnly: hasReceiptOnly ?? this.hasReceiptOnly,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<Expense> get filteredExpenses {
    final data = group?.expenses ?? [];
    return data.where((expense) {
      if (filterCategory != null && expense.category != filterCategory) {
        return false;
      }
      if (filterPayer != null && expense.payerUid != filterPayer) {
        return false;
      }
      if (hasReceiptOnly && expense.receiptUrl == null) {
        return false;
      }
      if (searchQuery.isNotEmpty &&
          !expense.title.toLowerCase().contains(searchQuery.toLowerCase()) &&
          !(expense.notes ?? '').toLowerCase().contains(searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  List<Object?> get props => [status, group, filterCategory, filterPayer, hasReceiptOnly, searchQuery];
}

enum GroupStatus { initial, loading, ready, error }
