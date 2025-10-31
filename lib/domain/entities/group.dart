import 'package:equatable/equatable.dart';

import 'currency_amount.dart';
import 'expense.dart';
import 'settlement.dart';

class Group extends Equatable {
  const Group({
    required this.id,
    required this.name,
    required this.type,
    required this.baseCurrency,
    required this.members,
    required this.expenses,
    required this.settlements,
    required this.createdAt,
    required this.updatedAt,
    this.note,
  });

  final String id;
  final String name;
  final GroupType type;
  final String baseCurrency;
  final List<GroupMember> members;
  final List<Expense> expenses;
  final List<Settlement> settlements;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? note;

  bool get hasMultiCurrency => expenses.any((e) => e.currency != baseCurrency);

  GroupMember? get admin {
    for (final member in members) {
      if (member.role == GroupRole.admin) {
        return member;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        baseCurrency,
        members,
        expenses,
        settlements,
        createdAt,
        updatedAt,
        note,
      ];
}

enum GroupType { trip, house, office, event, other }

enum GroupRole { admin, member }

class GroupMember extends Equatable {
  const GroupMember({
    required this.uid,
    required this.displayName,
    required this.role,
    required this.joinedAt,
    this.avatarUrl,
  });

  final String uid;
  final String displayName;
  final GroupRole role;
  final DateTime joinedAt;
  final String? avatarUrl;

  @override
  List<Object?> get props => [uid, displayName, role, joinedAt, avatarUrl];
}

class BalanceSummary extends Equatable {
  const BalanceSummary({
    required this.userId,
    required this.amount,
  });

  final String userId;
  final CurrencyAmount amount;

  @override
  List<Object?> get props => [userId, amount];
}
