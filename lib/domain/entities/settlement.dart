import 'package:equatable/equatable.dart';

class Settlement extends Equatable {
  const Settlement({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.amount,
    required this.currency,
    required this.method,
    required this.createdBy,
    required this.createdAt,
    this.reference,
    this.reversedBy,
  });

  final String id;
  final String fromUid;
  final String toUid;
  final double amount;
  final String currency;
  final SettlementMethod method;
  final String createdBy;
  final DateTime createdAt;
  final String? reference;
  final String? reversedBy;

  bool get isReversal => reversedBy != null;

  @override
  List<Object?> get props => [
        id,
        fromUid,
        toUid,
        amount,
        currency,
        method,
        createdBy,
        createdAt,
        reference,
        reversedBy,
      ];
}

enum SettlementMethod { cash, upiNote, upiIntent, razorpayLink }
