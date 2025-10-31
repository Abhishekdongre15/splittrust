import 'package:equatable/equatable.dart';

class ReportsState extends Equatable {
  const ReportsState({
    this.includeGroups = const [],
    this.dateRange = const Duration(days: 30),
    this.includeReceipts = true,
    this.format = ExportFormat.pdf,
    this.status = ReportStatus.idle,
    this.link,
  });

  final List<String> includeGroups;
  final Duration dateRange;
  final bool includeReceipts;
  final ExportFormat format;
  final ReportStatus status;
  final String? link;

  ReportsState copyWith({
    List<String>? includeGroups,
    Duration? dateRange,
    bool? includeReceipts,
    ExportFormat? format,
    ReportStatus? status,
    String? link,
  }) {
    return ReportsState(
      includeGroups: includeGroups ?? this.includeGroups,
      dateRange: dateRange ?? this.dateRange,
      includeReceipts: includeReceipts ?? this.includeReceipts,
      format: format ?? this.format,
      status: status ?? this.status,
      link: link,
    );
  }

  @override
  List<Object?> get props => [includeGroups, dateRange, includeReceipts, format, status, link];
}

enum ExportFormat { csv, pdf, xlsx }

enum ReportStatus { idle, generating, ready }
