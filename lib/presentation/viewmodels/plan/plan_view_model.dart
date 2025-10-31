import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/plan.dart';
import 'plan_state.dart';

class PlanViewModel extends Cubit<PlanState> {
  PlanViewModel() : super(const PlanState());

  void loadPlans() {
    emit(state.copyWith(status: PlanStatus.loading));
    try {
      const plans = <Plan>[
        Plan(
          tier: PlanTier.silver,
          displayName: 'Silver',
          tagline: 'Start splitting for free',
          billingType: BillingType.free,
          priceText: 'Free forever',
          highlighted: false,
          features: [
            'Equal split expenses',
            'Core dashboard cards',
            'Ad-supported experience',
          ],
        ),
        Plan(
          tier: PlanTier.gold,
          displayName: 'Gold',
          tagline: 'Advanced tools for power users',
          billingType: BillingType.subscription,
          priceText: '₹199/month subscription',
          highlighted: true,
          features: [
            'Smart split modes & receipts',
            'Exports & multi-currency',
            'Ad-free experience + PWA',
          ],
        ),
        Plan(
          tier: PlanTier.diamond,
          displayName: 'Diamond',
          tagline: 'Lifetime premium intelligence',
          billingType: BillingType.lifetime,
          priceText: '₹4,999 one-time payment',
          highlighted: false,
          features: [
            'OCR & AI insights',
            'Smart settlements suggestions',
            'Premium themes & Excel exports',
          ],
        ),
      ];

      emit(
        state.copyWith(
          status: PlanStatus.ready,
          plans: plans,
          selectedTier: PlanTier.gold,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PlanStatus.failure,
          errorMessage: 'Unable to load plans. Please try again later.',
        ),
      );
    }
  }

  void selectPlan(PlanTier tier) {
    emit(state.copyWith(selectedTier: tier));
  }
}
