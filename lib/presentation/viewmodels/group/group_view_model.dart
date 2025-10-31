import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/group_repository.dart';
import '../../../domain/entities/expense.dart';
import 'group_state.dart';

class GroupViewModel extends Cubit<GroupState> {
  GroupViewModel({required GroupRepository repository})
      : _repository = repository,
        super(const GroupState());

  final GroupRepository _repository;

  Future<void> load(String id) async {
    emit(state.copyWith(status: GroupStatus.loading));
    try {
      final group = await _repository.getGroupById(id);
      emit(state.copyWith(status: GroupStatus.ready, group: group));
    } catch (error) {
      emit(state.copyWith(status: GroupStatus.error));
    }
  }

  void updateCategory(ExpenseCategory? category) {
    emit(state.copyWith(filterCategory: category));
  }

  void updatePayer(String? payer) {
    emit(state.copyWith(filterPayer: payer));
  }

  void toggleReceiptOnly(bool value) {
    emit(state.copyWith(hasReceiptOnly: value));
  }

  void search(String query) {
    emit(state.copyWith(searchQuery: query));
  }
}
