import 'package:equatable/equatable.dart';

import '../../../data/models/plan.dart';

enum PlanStatus { initial, loading, ready, failure }

class PlanState extends Equatable {
  const PlanState({
    this.status = PlanStatus.initial,
    this.plans = const <Plan>[],
    this.selectedTier,
    this.errorMessage,
  });

  final PlanStatus status;
  final List<Plan> plans;
  final PlanTier? selectedTier;
  final String? errorMessage;

  PlanState copyWith({
    PlanStatus? status,
    List<Plan>? plans,
    PlanTier? selectedTier,
    String? errorMessage,
  }) {
    return PlanState(
      status: status ?? this.status,
      plans: plans ?? this.plans,
      selectedTier: selectedTier ?? this.selectedTier,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, plans, selectedTier, errorMessage];
}
