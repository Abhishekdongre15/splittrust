import 'dart:math';

import '../entities/currency_amount.dart';
import '../entities/expense.dart';
import '../entities/group.dart';
import '../entities/settlement.dart';

class BalanceEngineResult {
  BalanceEngineResult({
    required this.netByUser,
    required this.totalOwed,
    required this.totalOwe,
  });

  final Map<String, CurrencyAmount> netByUser;
  final CurrencyAmount totalOwed;
  final CurrencyAmount totalOwe;
}

class SmartSettlementSuggestion {
  SmartSettlementSuggestion({
    required this.fromUid,
    required this.toUid,
    required this.amount,
  });

  final String fromUid;
  final String toUid;
  final double amount;
}

class BalanceEngine {
  BalanceEngine({required this.baseCurrency});

  final String baseCurrency;

  BalanceEngineResult calculate(Group group) {
    final net = <String, double>{};

    double owedTotal = 0;
    double oweTotal = 0;

    for (final member in group.members) {
      net[member.uid] = 0;
    }

    for (final expense in group.expenses.where((e) => !e.isDeleted)) {
      net.update(expense.payerUid, (value) => value + expense.amountBase,
          ifAbsent: () => expense.amountBase);
      for (final participant in expense.participants) {
        net.update(participant.uid, (value) => value - participant.shareBase,
            ifAbsent: () => -participant.shareBase);
      }
    }

    for (final settlement in group.settlements) {
      if (settlement.isReversal) {
        net.update(settlement.fromUid, (value) => value + settlement.amount,
            ifAbsent: () => settlement.amount);
        net.update(settlement.toUid, (value) => value - settlement.amount,
            ifAbsent: () => -settlement.amount);
      } else {
        net.update(settlement.fromUid, (value) => value + settlement.amount,
            ifAbsent: () => settlement.amount);
        net.update(settlement.toUid, (value) => value - settlement.amount,
            ifAbsent: () => -settlement.amount);
      }
    }

    final map = net.map((key, value) => MapEntry(
          key,
          CurrencyAmount(currency: baseCurrency, value: _bankersRound(value)),
        ));

    for (final amount in map.values) {
      if (amount.value > 0) {
        owedTotal += amount.value;
      } else if (amount.value < 0) {
        oweTotal += amount.value.abs();
      }
    }

    return BalanceEngineResult(
      netByUser: map,
      totalOwed: CurrencyAmount(currency: baseCurrency, value: _bankersRound(owedTotal)),
      totalOwe: CurrencyAmount(currency: baseCurrency, value: _bankersRound(oweTotal)),
    );
  }

  List<SmartSettlementSuggestion> suggest(Set<GroupMember> members, Map<String, CurrencyAmount> net) {
    final normalised = Map<String, CurrencyAmount>.from(net);
    for (final member in members) {
      normalised.putIfAbsent(member.uid, () => CurrencyAmount(currency: baseCurrency, value: 0));
    }

    final creditors = <_BalanceNode>[];
    final debtors = <_BalanceNode>[];

    for (final entry in normalised.entries) {
      final value = entry.value.value;
      if (value > 0.01) {
        creditors.add(_BalanceNode(uid: entry.key, amount: value));
      } else if (value < -0.01) {
        debtors.add(_BalanceNode(uid: entry.key, amount: value.abs()));
      }
    }

    creditors.sort((a, b) => b.amount.compareTo(a.amount));
    debtors.sort((a, b) => b.amount.compareTo(a.amount));

    final suggestions = <SmartSettlementSuggestion>[];

    var i = 0;
    var j = 0;

    while (i < creditors.length && j < debtors.length) {
      final creditor = creditors[i];
      final debtor = debtors[j];
      final amount = min(creditor.amount, debtor.amount);

      suggestions.add(SmartSettlementSuggestion(
        fromUid: debtor.uid,
        toUid: creditor.uid,
        amount: _bankersRound(amount),
      ));

      creditor.amount -= amount;
      debtor.amount -= amount;

      if (creditor.amount < 0.01) {
        i++;
      }
      if (debtor.amount < 0.01) {
        j++;
      }
    }

    return suggestions;
  }

  double _bankersRound(double value) {
    final scaled = value * 100;
    final floor = scaled.floor();
    final fraction = scaled - floor;
    if (fraction > 0.5) {
      return (floor + 1) / 100;
    }
    if (fraction < 0.5) {
      return floor / 100;
    }
    return (floor.isEven ? floor : floor + 1) / 100;
  }
}

class _BalanceNode {
  _BalanceNode({required this.uid, required this.amount});

  final String uid;
  double amount;
}
