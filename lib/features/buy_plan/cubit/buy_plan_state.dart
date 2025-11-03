import 'package:equatable/equatable.dart';

import '../models/buy_plan.dart';

enum BuyPlanStatus { idle, loading, ready, error }

class BuyPlanState extends Equatable {
  const BuyPlanState({
    this.status = BuyPlanStatus.idle,
    this.plans = const <BuyPlan>[],
    this.errorMessage,
  });

  final BuyPlanStatus status;
  final List<BuyPlan> plans;
  final String? errorMessage;

  BuyPlanState copyWith({
    BuyPlanStatus? status,
    List<BuyPlan>? plans,
    String? errorMessage,
  }) {
    return BuyPlanState(
      status: status ?? this.status,
      plans: plans ?? this.plans,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, plans, errorMessage];
}
