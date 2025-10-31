import 'package:equatable/equatable.dart';

import '../models/dashboard_models.dart';

enum DashboardStatus { idle, loading, ready, error }

class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.idle,
    this.summary,
    this.groups = const <GroupSummary>[],
    this.activity = const <ActivityItem>[],
    this.errorMessage,
  });

  final DashboardStatus status;
  final DashboardSummary? summary;
  final List<GroupSummary> groups;
  final List<ActivityItem> activity;
  final String? errorMessage;

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardSummary? summary,
    List<GroupSummary>? groups,
    List<ActivityItem>? activity,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      groups: groups ?? this.groups,
      activity: activity ?? this.activity,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, summary, groups, activity, errorMessage];
}
