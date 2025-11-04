import 'package:equatable/equatable.dart';

import '../models/group_models.dart';

enum GroupStatus { initial, loading, ready, mutating, error }

class GroupState extends Equatable {
  const GroupState({
    this.status = GroupStatus.initial,
    this.groups = const [],
    this.directory = const [],
    this.errorMessage,
  });

  final GroupStatus status;
  final List<GroupDetail> groups;
  final List<MemberProfile> directory;
  final String? errorMessage;

  bool get isBusy => status == GroupStatus.loading || status == GroupStatus.mutating;

  GroupDetail? groupById(String id) {
    for (final group in groups) {
      if (group.id == id) {
        return group;
      }
    }
    return null;
  }

  GroupState copyWith({
    GroupStatus? status,
    List<GroupDetail>? groups,
    List<MemberProfile>? directory,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GroupState(
      status: status ?? this.status,
      groups: groups ?? this.groups,
      directory: directory ?? this.directory,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, groups, directory, errorMessage];
}
