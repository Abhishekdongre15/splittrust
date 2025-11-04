import 'package:equatable/equatable.dart';

class DashboardSummary extends Equatable {
  const DashboardSummary({
    required this.currency,
    required this.youOwe,
    required this.youAreOwed,
  });

  final String currency;
  final double youOwe;
  final double youAreOwed;

  double get net => youAreOwed - youOwe;

  @override
  List<Object?> get props => [currency, youOwe, youAreOwed];
}

class ActivityItem extends Equatable {
  const ActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });

  final String id;
  final String title;
  final String subtitle;
  final DateTime timestamp;

  @override
  List<Object?> get props => [id, title, subtitle, timestamp];
}

