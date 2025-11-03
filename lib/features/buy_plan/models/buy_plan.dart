import 'package:equatable/equatable.dart';

enum BuyPlanTier { silver, gold, diamond }

extension BuyPlanTierDisplay on BuyPlanTier {
  String get displayName {
    switch (this) {
      case BuyPlanTier.silver:
        return 'Silver';
      case BuyPlanTier.gold:
        return 'Gold';
      case BuyPlanTier.diamond:
        return 'Diamond';
    }
  }

  String get subtitle {
    switch (this) {
      case BuyPlanTier.silver:
        return 'Free · Equal splits · Ads';
      case BuyPlanTier.gold:
        return 'Subscription · Advanced splits · Multi-currency';
      case BuyPlanTier.diamond:
        return 'Lifetime · OCR · AI insights · Smart settlements';
    }
  }
}

class BuyPlan extends Equatable {
  const BuyPlan({
    required this.tier,
    required this.priceLabel,
    required this.description,
    required this.features,
    required this.highlight,
  });

  final BuyPlanTier tier;
  final String priceLabel;
  final String description;
  final List<String> features;
  final bool highlight;

  @override
  List<Object?> get props => [tier, priceLabel, description, features, highlight];
}
