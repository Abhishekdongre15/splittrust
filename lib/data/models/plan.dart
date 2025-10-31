import 'package:equatable/equatable.dart';

enum PlanTier { silver, gold, diamond }

enum BillingType { free, subscription, lifetime }

class Plan extends Equatable {
  const Plan({
    required this.tier,
    required this.displayName,
    required this.tagline,
    required this.billingType,
    required this.priceText,
    required this.highlighted,
    required this.features,
  });

  final PlanTier tier;
  final String displayName;
  final String tagline;
  final BillingType billingType;
  final String priceText;
  final bool highlighted;
  final List<String> features;

  @override
  List<Object?> get props => [
        tier,
        displayName,
        tagline,
        billingType,
        priceText,
        highlighted,
        features,
      ];
}
