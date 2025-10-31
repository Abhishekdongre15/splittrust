import 'package:equatable/equatable.dart';

/// Represents the available customer plans in SplitTrust.
class PlanTier extends Equatable {
  const PlanTier({
    required this.id,
    required this.displayName,
    required this.type,
    required this.priceDescription,
    required this.features,
    required this.highlight,
  });

  final String id;
  final PlanType type;
  final String displayName;
  final String priceDescription;
  final List<String> features;
  final String highlight;

  bool get isPaid => type != PlanType.silver;
  bool get isLifetime => type == PlanType.diamond;

  @override
  List<Object?> get props => [id, type, displayName, priceDescription, features, highlight];
}

enum PlanType { silver, gold, diamond }
