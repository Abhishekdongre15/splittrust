import 'package:equatable/equatable.dart';

import '../../../domain/entities/activity_event.dart';
import '../../../domain/entities/group.dart';
import '../../../domain/entities/plan_tier.dart';
import '../../../domain/entities/user_profile.dart';
import '../../../domain/services/balance_engine.dart';

class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.user,
    this.groups = const [],
    this.activity = const [],
    this.selectedGroupId,
    this.balanceResult,
    this.suggestions = const [],
    this.error,
  });

  final DashboardStatus status;
  final UserProfile? user;
  final List<Group> groups;
  final List<ActivityEvent> activity;
  final String? selectedGroupId;
  final BalanceEngineResult? balanceResult;
  final List<SmartSettlementSuggestion> suggestions;
  final String? error;

  DashboardState copyWith({
    DashboardStatus? status,
    UserProfile? user,
    List<Group>? groups,
    List<ActivityEvent>? activity,
    String? selectedGroupId,
    BalanceEngineResult? balanceResult,
    List<SmartSettlementSuggestion>? suggestions,
    String? error,
  }) {
    return DashboardState(
      status: status ?? this.status,
      user: user ?? this.user,
      groups: groups ?? this.groups,
      activity: activity ?? this.activity,
      selectedGroupId: selectedGroupId ?? this.selectedGroupId,
      balanceResult: balanceResult ?? this.balanceResult,
      suggestions: suggestions ?? this.suggestions,
      error: error ?? this.error,
    );
  }

  Group? get selectedGroup {
    if (groups.isEmpty) {
      return null;
    }
    if (selectedGroupId == null) {
      return groups.first;
    }
    for (final group in groups) {
      if (group.id == selectedGroupId) {
        return group;
      }
    }
    return groups.first;
  }

  PlanType get plan => user?.plan ?? PlanType.silver;

  @override
  List<Object?> get props => [
        status,
        user,
        groups,
        activity,
        selectedGroupId,
        balanceResult,
        suggestions,
        error,
      ];
}

enum DashboardStatus { initial, loading, ready, error }
