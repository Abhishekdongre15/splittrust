import 'package:flutter_bloc/flutter_bloc.dart';

import 'reports_state.dart';

class ReportsViewModel extends Cubit<ReportsState> {
  ReportsViewModel() : super(const ReportsState());

  void setGroups(List<String> groups) {
    emit(state.copyWith(includeGroups: groups));
  }

  void setDateRange(Duration range) {
    emit(state.copyWith(dateRange: range));
  }

  void setFormat(ExportFormat format) {
    emit(state.copyWith(format: format));
  }

  void toggleReceipts(bool include) {
    emit(state.copyWith(includeReceipts: include));
  }

  Future<void> generate() async {
    emit(state.copyWith(status: ReportStatus.generating));
    await Future<void>.delayed(const Duration(seconds: 1));
    emit(state.copyWith(
      status: ReportStatus.ready,
      link: 'https://storage.splittrust.app/exports/mock_report.pdf',
    ));
  }
}
