import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/dashboard_models.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(const DashboardState());

  Future<void> load() async {
    emit(state.copyWith(status: DashboardStatus.loading));
    try {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      const summary = DashboardSummary(currency: 'INR', youOwe: 18650.75, youAreOwed: 21210.40);
      const groups = [
        GroupSummary(id: 'trip_goa', name: 'Goa Getaway', baseCurrency: 'INR', netBalance: 2559.65),
        GroupSummary(id: 'flat_mates', name: 'Flat 12B', baseCurrency: 'INR', netBalance: -1240.10),
        GroupSummary(id: 'office_lunch', name: 'Office Lunches', baseCurrency: 'USD', netBalance: 480.00),
      ];
      final now = DateTime.now();
      final activity = [
        ActivityItem(
          id: 'act1',
          title: 'AquaFire recorded a settlement',
          subtitle: 'You received ₹1,250 from Ben',
          timestamp: now.subtract(const Duration(hours: 2)),
        ),
        ActivityItem(
          id: 'act2',
          title: 'Anna added Scuba Diving',
          subtitle: '₹29,900 split in Goa Getaway',
          timestamp: now.subtract(const Duration(days: 1, hours: 5)),
        ),
        ActivityItem(
          id: 'act3',
          title: 'Rent July added',
          subtitle: '₹48,000 shared in Flat 12B',
          timestamp: now.subtract(const Duration(days: 4)),
        ),
      ];
      emit(state.copyWith(
        status: DashboardStatus.ready,
        summary: summary,
        groups: groups,
        activity: activity,
      ));
    } catch (error) {
      emit(state.copyWith(status: DashboardStatus.error, errorMessage: error.toString()));
    }
  }
}
