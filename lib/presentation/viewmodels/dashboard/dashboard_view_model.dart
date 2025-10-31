import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/group_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../domain/services/balance_engine.dart';
import 'dashboard_state.dart';

class DashboardViewModel extends Cubit<DashboardState> {
  DashboardViewModel({
    required UserRepository userRepository,
    required GroupRepository groupRepository,
  })  : _userRepository = userRepository,
        _groupRepository = groupRepository,
        super(const DashboardState());

  final UserRepository _userRepository;
  final GroupRepository _groupRepository;

  Future<void> load() async {
    emit(state.copyWith(status: DashboardStatus.loading));
    try {
      final user = await _userRepository.getCurrentUser();
      final groups = await _groupRepository.getGroupsForUser(user.id);
      final activity = await _groupRepository.recentActivity(user.id);

      BalanceEngineResult? balance;
      List<SmartSettlementSuggestion> suggestions = const [];
      if (groups.isNotEmpty) {
        final group = groups.first;
        final engine = BalanceEngine(baseCurrency: group.baseCurrency);
        balance = engine.calculate(group);
        suggestions = engine.suggest(group.members.toSet(), balance.netByUser);
      }

      emit(state.copyWith(
        status: DashboardStatus.ready,
        user: user,
        groups: groups,
        activity: activity,
        selectedGroupId: groups.isEmpty ? null : groups.first.id,
        balanceResult: balance,
        suggestions: suggestions,
      ));
    } catch (error) {
      emit(state.copyWith(status: DashboardStatus.error, error: error.toString()));
    }
  }

  Future<void> selectGroup(String id) async {
    if (state.status != DashboardStatus.ready) return;
    emit(state.copyWith(status: DashboardStatus.loading));
    try {
      final group = await _groupRepository.getGroupById(id);
      final engine = BalanceEngine(baseCurrency: group.baseCurrency);
      final balance = engine.calculate(group);
      final suggestions = engine.suggest(group.members.toSet(), balance.netByUser);

      final updatedGroups = state.groups.map((g) => g.id == id ? group : g).toList();

      emit(state.copyWith(
        status: DashboardStatus.ready,
        groups: updatedGroups,
        selectedGroupId: id,
        balanceResult: balance,
        suggestions: suggestions,
      ));
    } catch (error) {
      emit(state.copyWith(status: DashboardStatus.error, error: error.toString()));
    }
  }

  Future<void> refreshActivity() async {
    if (state.user == null) return;
    final activity = await _groupRepository.recentActivity(state.user!.id);
    emit(state.copyWith(activity: activity));
  }
}
