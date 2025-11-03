import 'dart:math';

import 'package:equatable/equatable.dart';

enum GroupRole { admin, member }

enum GroupHistoryType {
  groupCreated,
  memberAdded,
  expenseAdded,
  settlementRecorded,
  note,
}

class MemberProfile extends Equatable {
  const MemberProfile({required this.id, required this.displayName});

  final String id;
  final String displayName;

  MemberProfile copyWith({String? id, String? displayName}) {
    return MemberProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
    );
  }

  @override
  List<Object?> get props => [id, displayName];
}

class GroupMember extends Equatable {
  const GroupMember({required this.id, required this.displayName, this.role = GroupRole.member});

  factory GroupMember.fromProfile(MemberProfile profile, {GroupRole role = GroupRole.member}) {
    return GroupMember(id: profile.id, displayName: profile.displayName, role: role);
  }

  final String id;
  final String displayName;
  final GroupRole role;

  GroupMember copyWith({String? id, String? displayName, GroupRole? role}) {
    return GroupMember(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
    );
  }

  @override
  List<Object?> get props => [id, displayName, role];
}

class ExpenseShare extends Equatable {
  const ExpenseShare({required this.memberId, required this.shareAmount});

  final String memberId;
  final double shareAmount;

  @override
  List<Object?> get props => [memberId, shareAmount];
}

class GroupExpense extends Equatable {
  const GroupExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.currency,
    required this.amountBase,
    required this.paidBy,
    required this.participantIds,
    required this.shares,
    required this.category,
    required this.createdAt,
    this.notes,
  });

  final String id;
  final String title;
  final double amount;
  final String currency;
  final double amountBase;
  final String paidBy;
  final List<String> participantIds;
  final List<ExpenseShare> shares;
  final String category;
  final DateTime createdAt;
  final String? notes;

  @override
  List<Object?> get props => [
        id,
        title,
        amount,
        currency,
        amountBase,
        paidBy,
        participantIds,
        shares,
        category,
        createdAt,
        notes,
      ];
}

class GroupSettlement extends Equatable {
  const GroupSettlement({
    required this.id,
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
    required this.method,
    required this.recordedAt,
    this.reference,
  });

  final String id;
  final String fromMemberId;
  final String toMemberId;
  final double amount;
  final String method;
  final DateTime recordedAt;
  final String? reference;

  @override
  List<Object?> get props => [id, fromMemberId, toMemberId, amount, method, recordedAt, reference];
}

class GroupHistoryEntry extends Equatable {
  const GroupHistoryEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });

  final String id;
  final GroupHistoryType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;

  @override
  List<Object?> get props => [id, type, title, subtitle, timestamp];
}

class MemberBalance extends Equatable {
  const MemberBalance({
    required this.memberId,
    required this.paid,
    required this.owed,
    required this.settlementsIn,
    required this.settlementsOut,
  });

  final String memberId;
  final double paid;
  final double owed;
  final double settlementsIn;
  final double settlementsOut;

  double get net => roundBankers(paid + settlementsIn - owed - settlementsOut);

  MemberBalance copyWith({
    double? paid,
    double? owed,
    double? settlementsIn,
    double? settlementsOut,
  }) {
    return MemberBalance(
      memberId: memberId,
      paid: paid ?? this.paid,
      owed: owed ?? this.owed,
      settlementsIn: settlementsIn ?? this.settlementsIn,
      settlementsOut: settlementsOut ?? this.settlementsOut,
    );
  }

  @override
  List<Object?> get props => [memberId, paid, owed, settlementsIn, settlementsOut];
}

double roundBankers(double value, [int fractionDigits = 2]) {
  final factor = pow(10, fractionDigits).toDouble();
  final scaled = value * factor;
  final floorValue = scaled.floorToDouble();
  final diff = scaled - floorValue;
  if (diff < 0.5) {
    return floorValue / factor;
  }
  if (diff > 0.5) {
    return (floorValue + 1) / factor;
  }
  final isEven = floorValue % 2 == 0;
  return (isEven ? floorValue : floorValue + 1) / factor;
}

class GroupDetail extends Equatable {
  const GroupDetail({
    required this.id,
    required this.name,
    required this.baseCurrency,
    required List<GroupMember> members,
    required List<GroupExpense> expenses,
    required List<GroupSettlement> settlements,
    required List<GroupHistoryEntry> history,
    this.note,
  })  : members = List.unmodifiable(members),
        expenses = List.unmodifiable(expenses),
        settlements = List.unmodifiable(settlements),
        history = List.unmodifiable(history);

  final String id;
  final String name;
  final String baseCurrency;
  final List<GroupMember> members;
  final List<GroupExpense> expenses;
  final List<GroupSettlement> settlements;
  final List<GroupHistoryEntry> history;
  final String? note;

  GroupDetail copyWith({
    String? id,
    String? name,
    String? baseCurrency,
    List<GroupMember>? members,
    List<GroupExpense>? expenses,
    List<GroupSettlement>? settlements,
    List<GroupHistoryEntry>? history,
    String? note,
  }) {
    return GroupDetail(
      id: id ?? this.id,
      name: name ?? this.name,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      members: members ?? this.members,
      expenses: expenses ?? this.expenses,
      settlements: settlements ?? this.settlements,
      history: history ?? this.history,
      note: note ?? this.note,
    );
  }

  GroupMember? memberById(String memberId) {
    for (final member in members) {
      if (member.id == memberId) {
        return member;
      }
    }
    return null;
  }

  Map<String, MemberBalance> get balances {
    final result = <String, MemberBalance>{};
    for (final member in members) {
      result[member.id] = MemberBalance(
        memberId: member.id,
        paid: 0,
        owed: 0,
        settlementsIn: 0,
        settlementsOut: 0,
      );
    }

    for (final expense in expenses) {
      final payerBalance = result[expense.paidBy];
      if (payerBalance != null) {
        result[expense.paidBy] = payerBalance.copyWith(
          paid: roundBankers(payerBalance.paid + expense.amountBase),
        );
      }
      for (final share in expense.shares) {
        final balance = result[share.memberId];
        if (balance != null) {
          result[share.memberId] = balance.copyWith(
            owed: roundBankers(balance.owed + share.shareAmount),
          );
        }
      }
    }

    for (final settlement in settlements) {
      final fromBalance = result[settlement.fromMemberId];
      if (fromBalance != null) {
        result[settlement.fromMemberId] = fromBalance.copyWith(
          settlementsOut: roundBankers(fromBalance.settlementsOut + settlement.amount),
        );
      }
      final toBalance = result[settlement.toMemberId];
      if (toBalance != null) {
        result[settlement.toMemberId] = toBalance.copyWith(
          settlementsIn: roundBankers(toBalance.settlementsIn + settlement.amount),
        );
      }
    }

    return result;
  }

  List<GroupHistoryEntry> get orderedHistory {
    final copy = List<GroupHistoryEntry>.from(history);
    copy.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return copy;
  }

  double get totalExpenses => expenses.fold<double>(0, (value, e) => value + e.amountBase);

  double get totalSettlements => settlements.fold<double>(0, (value, s) => value + s.amount);

  @override
  List<Object?> get props => [id, name, baseCurrency, members, expenses, settlements, history, note];
}
