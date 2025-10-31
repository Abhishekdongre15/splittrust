import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/plan.dart';
import '../../../domain/entities/plan_tier.dart';
import 'plan_state.dart';

class PlanViewModel extends Cubit<PlanState> {
  PlanViewModel() : super(const PlanState());

  void loadPlans() {
    emit(state.copyWith(status: PlanStatus.loading));
    try {
      const plans = <Plan>[
        Plan(
          tier: PlanType.silver,
          displayName: 'Silver Plan',
          tagline: 'Start splitting for free',
          billingType: BillingType.free,
          priceText: '₹0 forever',
          highlighted: false,
          features: [
            'Equal split expenses',
            'Core dashboard cards',
            'Ad-supported experience',
          ],
        ),
        Plan(
          tier: PlanType.gold,
          displayName: 'Gold Subscription',
          tagline: 'Advanced tools for power users',
          billingType: BillingType.subscription,
          priceText: '₹199/month via Razorpay',
          highlighted: true,
          features: [
            'Smart split modes & receipts',
            'Exports & multi-currency',
            'Ad-free experience + PWA',
          ],
        ),
        Plan(
          tier: PlanType.diamond,
          displayName: 'Diamond Lifetime',
          tagline: 'Lifetime premium intelligence',
          billingType: BillingType.lifetime,
          priceText: '₹4,999 one-time via Razorpay',
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
          selectedTier: PlanType.gold,
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

  void selectPlan(PlanType tier) {
    emit(state.copyWith(selectedTier: tier));
  }
}
