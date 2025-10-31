import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.currency,
    required this.amountBase,
    required this.payerUid,
    required this.participants,
    required this.splitMode,
    required this.category,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.fx,
    this.notes,
    this.receiptUrl,
    this.ocr,
    this.deleted,
  });

  final String id;
  final String title;
  final double amount;
  final String currency;
  final double amountBase;
  final String payerUid;
  final List<ExpenseParticipant> participants;
  final SplitMode splitMode;
  final ExpenseCategory category;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final FxSnapshot? fx;
  final String? notes;
  final String? receiptUrl;
  final ExpenseOcr? ocr;
  final bool? deleted;

  bool get isDeleted => deleted ?? false;

  @override
  List<Object?> get props => [
        id,
        title,
        amount,
        currency,
        amountBase,
        payerUid,
        participants,
        splitMode,
        category,
        createdBy,
        createdAt,
        updatedAt,
        fx,
        notes,
        receiptUrl,
        ocr,
        deleted,
      ];
}

class ExpenseParticipant extends Equatable {
  const ExpenseParticipant({
    required this.uid,
    required this.shareBase,
    required this.shareOriginal,
  });

  final String uid;
  final double shareBase;
  final double shareOriginal;

  @override
  List<Object?> get props => [uid, shareBase, shareOriginal];
}

enum SplitMode { equal, exact, percent, adjustment }

enum ExpenseCategory { food, travel, rent, shopping, utilities, other }

class FxSnapshot extends Equatable {
  const FxSnapshot({
    required this.from,
    required this.to,
    required this.rate,
    required this.capturedAt,
  });

  final String from;
  final String to;
  final double rate;
  final DateTime capturedAt;

  @override
  List<Object?> get props => [from, to, rate, capturedAt];
}

class ExpenseOcr extends Equatable {
  const ExpenseOcr({
    required this.merchant,
    required this.date,
    required this.total,
    required this.currency,
    required this.confidence,
  });

  final String? merchant;
  final DateTime? date;
  final double? total;
  final String? currency;
  final double confidence;

  @override
  List<Object?> get props => [merchant, date, total, currency, confidence];
}
