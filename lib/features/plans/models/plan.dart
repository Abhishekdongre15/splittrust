import 'package:equatable/equatable.dart';

enum PlanTier { silver, gold, diamond }

extension PlanTierDisplay on PlanTier {
  String get displayName {
    switch (this) {
      case PlanTier.silver:
        return 'Silver';
      case PlanTier.gold:
        return 'Gold';
      case PlanTier.diamond:
        return 'Diamond';
    }
  }

  String get subtitle {
    switch (this) {
      case PlanTier.silver:
        return 'Free · Equal splits · Ads';
      case PlanTier.gold:
        return 'Subscription · Advanced splits · Multi-currency';
      case PlanTier.diamond:
        return 'Lifetime · OCR · AI insights · Smart settlements';
    }
  }
}

class Plan extends Equatable {
  const Plan({
    required this.tier,
    required this.priceLabel,
    required this.description,
    required this.features,
    required this.highlight,
  });

  final PlanTier tier;
  final String priceLabel;
  final String description;
  final List<String> features;
  final bool highlight;

  @override
  List<Object?> get props => [tier, priceLabel, description, features, highlight];
}
