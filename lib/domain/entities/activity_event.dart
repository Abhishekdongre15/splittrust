import 'package:equatable/equatable.dart';

enum ActivityType { expenseAdded, expenseEdited, expenseDeleted, settlementAdded, settlementReverted, planChanged }

class ActivityEvent extends Equatable {
  const ActivityEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amountText,
    required this.timestamp,
    required this.actor,
  });

  final String id;
  final ActivityType type;
  final String title;
  final String subtitle;
  final String? amountText;
  final DateTime timestamp;
  final String actor;

  @override
  List<Object?> get props => [id, type, title, subtitle, amountText, timestamp, actor];
}
