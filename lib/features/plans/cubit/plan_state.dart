import 'package:equatable/equatable.dart';

import '../models/plan.dart';

enum PlanStatus { idle, loading, ready, error }

class PlanState extends Equatable {
  const PlanState({
    this.status = PlanStatus.idle,
    this.plans = const <Plan>[],
    this.errorMessage,
  });

  final PlanStatus status;
  final List<Plan> plans;
  final String? errorMessage;

  PlanState copyWith({
    PlanStatus? status,
    List<Plan>? plans,
    String? errorMessage,
  }) {
    return PlanState(
      status: status ?? this.status,
      plans: plans ?? this.plans,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, plans, errorMessage];
}
