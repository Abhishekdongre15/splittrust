import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/group_repository.dart';
import '../models/group_models.dart';
import 'group_state.dart';

class GroupCubit extends Cubit<GroupState> {
  GroupCubit({required GroupRepository repository})
      : _repository = repository,
        super(const GroupState());

  final GroupRepository _repository;

  String get currentUserId => _repository.currentUserId;

  Future<void> load() async {
    emit(state.copyWith(status: GroupStatus.loading, clearError: true));
    try {
      final snapshot = await _repository.load();
      emit(
        state.copyWith(
          status: GroupStatus.ready,
          groups: snapshot.groups,
          directory: snapshot.directory,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: GroupStatus.error, errorMessage: error.toString()));
    }
  }

  Future<GroupDetail?> createGroup({
    required String name,
    required String baseCurrency,
    required List<MemberProfile> members,
    String? note,
  }) async {
    emit(state.copyWith(status: GroupStatus.mutating, clearError: true));
    try {
      final group = await _repository.createGroup(
        name: name,
        baseCurrency: baseCurrency,
        members: members,
        note: note,
      );
      final updatedGroups = List<GroupDetail>.from(state.groups)..add(group);
      final updatedDirectory = _mergeDirectoryWithGroup(state.directory, group);
      emit(
        state.copyWith(
          status: GroupStatus.ready,
          groups: updatedGroups,
          directory: updatedDirectory,
          clearError: true,
        ),
      );
      return group;
    } catch (error) {
      emit(state.copyWith(status: GroupStatus.error, errorMessage: error.toString()));
      return null;
    }
  }

  Future<void> addEqualExpense({
    required String groupId,
    required String title,
    required double amount,
    required String paidBy,
    required List<String> participantIds,
    required String category,
    String? notes,
  }) async {
    emit(state.copyWith(status: GroupStatus.mutating, clearError: true));
    try {
      final updated = await _repository.addEqualExpense(
        groupId: groupId,
        title: title,
        amount: amount,
        paidBy: paidBy,
        participantIds: participantIds,
        category: category,
        notes: notes,
      );
      final updatedGroups = _replaceGroup(updated);
      emit(
        state.copyWith(
          status: GroupStatus.ready,
          groups: updatedGroups,
          directory: _mergeDirectoryWithGroup(state.directory, updated),
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: GroupStatus.error, errorMessage: error.toString()));
    }
  }

  Future<void> recordSettlement({
    required String groupId,
    required String fromMemberId,
    required String toMemberId,
    required double amount,
    required String method,
    String? reference,
  }) async {
    emit(state.copyWith(status: GroupStatus.mutating, clearError: true));
    try {
      final updated = await _repository.recordSettlement(
        groupId: groupId,
        fromMemberId: fromMemberId,
        toMemberId: toMemberId,
        amount: amount,
        method: method,
        reference: reference,
      );
      final updatedGroups = _replaceGroup(updated);
      emit(
        state.copyWith(
          status: GroupStatus.ready,
          groups: updatedGroups,
          directory: _mergeDirectoryWithGroup(state.directory, updated),
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: GroupStatus.error, errorMessage: error.toString()));
    }
  }

  Future<void> updateSimplifyDebts({required String groupId, required bool simplify}) async {
    emit(state.copyWith(status: GroupStatus.mutating, clearError: true));
    try {
      final updated = await _repository.updateSimplifyDebts(groupId: groupId, simplify: simplify);
      final updatedGroups = _replaceGroup(updated);
      emit(
        state.copyWith(
          status: GroupStatus.ready,
          groups: updatedGroups,
          directory: _mergeDirectoryWithGroup(state.directory, updated),
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: GroupStatus.error, errorMessage: error.toString()));
    }
  }

  Future<void> updateDefaultSplit({
    required String groupId,
    required GroupDefaultSplitStrategy strategy,
  }) async {
    emit(state.copyWith(status: GroupStatus.mutating, clearError: true));
    try {
      final updated = await _repository.updateDefaultSplit(groupId: groupId, strategy: strategy);
      final updatedGroups = _replaceGroup(updated);
      emit(
        state.copyWith(
          status: GroupStatus.ready,
          groups: updatedGroups,
          directory: _mergeDirectoryWithGroup(state.directory, updated),
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: GroupStatus.error, errorMessage: error.toString()));
    }
  }

  Future<void> addMember({
    required String groupId,
    required String displayName,
    GroupRole role = GroupRole.member,
  }) async {
    final profile = ensureMember(displayName);
    emit(state.copyWith(status: GroupStatus.mutating, clearError: true));
    try {
      final updated = await _repository.addMember(groupId: groupId, member: profile, role: role);
      final updatedGroups = _replaceGroup(updated);
      emit(
        state.copyWith(
          status: GroupStatus.ready,
          groups: updatedGroups,
          directory: _mergeDirectoryWithGroup(state.directory, updated),
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: GroupStatus.error, errorMessage: error.toString()));
    }
  }

  Future<void> removeMember({
    required String groupId,
    required String memberId,
  }) async {
    emit(state.copyWith(status: GroupStatus.mutating, clearError: true));
    try {
      final updated = await _repository.removeMember(groupId: groupId, memberId: memberId);
      final updatedGroups = _replaceGroup(updated);
      emit(
        state.copyWith(
          status: GroupStatus.ready,
          groups: updatedGroups,
          directory: _mergeDirectoryWithGroup(state.directory, updated),
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: GroupStatus.error, errorMessage: error.toString()));
    }
  }

  Future<void> updateBaseCurrency({
    required String groupId,
    required String currency,
  }) async {
    emit(state.copyWith(status: GroupStatus.mutating, clearError: true));
    try {
      final updated = await _repository.updateBaseCurrency(groupId: groupId, baseCurrency: currency);
      final updatedGroups = _replaceGroup(updated);
      emit(
        state.copyWith(
          status: GroupStatus.ready,
          groups: updatedGroups,
          directory: _mergeDirectoryWithGroup(state.directory, updated),
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: GroupStatus.error, errorMessage: error.toString()));
    }
  }

  Future<bool> leaveGroup({required String groupId, required String memberId}) async {
    emit(state.copyWith(status: GroupStatus.mutating, clearError: true));
    try {
      final updated = await _repository.leaveGroup(groupId: groupId, memberId: memberId);
      final updatedGroups = List<GroupDetail>.from(state.groups);
      if (updated == null) {
        updatedGroups.removeWhere((group) => group.id == groupId);
      } else {
        final index = updatedGroups.indexWhere((group) => group.id == updated.id);
        if (index >= 0) {
          updatedGroups[index] = updated;
        } else {
          updatedGroups.add(updated);
        }
      }
      emit(
        state.copyWith(
          status: GroupStatus.ready,
          groups: updatedGroups,
          directory: updated == null
              ? state.directory
              : _mergeDirectoryWithGroup(state.directory, updated),
          clearError: true,
        ),
      );
      return true;
    } catch (error) {
      emit(state.copyWith(status: GroupStatus.error, errorMessage: error.toString()));
      return false;
    }
  }

  Future<bool> deleteGroup({required String groupId}) async {
    emit(state.copyWith(status: GroupStatus.mutating, clearError: true));
    try {
      await _repository.deleteGroup(groupId: groupId);
      final updatedGroups = List<GroupDetail>.from(state.groups)
        ..removeWhere((group) => group.id == groupId);
      emit(
        state.copyWith(
          status: GroupStatus.ready,
          groups: updatedGroups,
          clearError: true,
        ),
      );
      return true;
    } catch (error) {
      emit(state.copyWith(status: GroupStatus.error, errorMessage: error.toString()));
      return false;
    }
  }

  MemberProfile ensureMember(String displayName) {
    final member = _repository.ensureMember(displayName);
    final exists = state.directory.any((entry) => entry.id == member.id);
    if (!exists) {
      final updatedDirectory = List<MemberProfile>.from(state.directory)..add(member);
      emit(state.copyWith(directory: updatedDirectory));
    }
    return member;
  }

  void clearError() {
    if (state.errorMessage != null) {
      emit(state.copyWith(clearError: true));
    }
  }

  List<GroupDetail> _replaceGroup(GroupDetail updated) {
    final updatedGroups = List<GroupDetail>.from(state.groups);
    final index = updatedGroups.indexWhere((group) => group.id == updated.id);
    if (index >= 0) {
      updatedGroups[index] = updated;
    } else {
      updatedGroups.add(updated);
    }
    return updatedGroups;
  }

  List<MemberProfile> _mergeDirectoryWithGroup(List<MemberProfile> directory, GroupDetail group) {
    final map = {for (final member in directory) member.id: member};
    for (final member in group.members) {
      map[member.id] = MemberProfile(id: member.id, displayName: member.displayName);
    }
    return map.values.toList();
  }
}
