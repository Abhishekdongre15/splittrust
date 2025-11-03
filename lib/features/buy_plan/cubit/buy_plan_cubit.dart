import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/buy_plan.dart';
import 'buy_plan_state.dart';

class BuyPlanCubit extends Cubit<BuyPlanState> {
  BuyPlanCubit() : super(const BuyPlanState());

  Future<void> load() async {
    if (state.status == BuyPlanStatus.loading) return;
    emit(state.copyWith(status: BuyPlanStatus.loading));
    try {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      const plans = [
        BuyPlan(
          tier: BuyPlanTier.silver,
          priceLabel: 'Free',
          description: 'Track shared expenses with equal splits and ad support.',
          features: [
            'Unlimited groups',
            'Equal split mode',
            'Ad-supported experience',
          ],
          highlight: false,
        ),
        BuyPlan(
          tier: BuyPlanTier.gold,
          priceLabel: '₹249/month',
          description: 'Unlock advanced split modes, receipts, and exports.',
          features: [
            'Exact & percentage splits',
            'Receipts & FX snapshots',
            'CSV/PDF exports & PWA',
            'Ad-free interface',
          ],
          highlight: true,
        ),
        BuyPlan(
          tier: BuyPlanTier.diamond,
          priceLabel: '₹6,999 lifetime',
          description: 'Get OCR, AI insights, and smart settlement automation forever.',
          features: [
            'Receipt OCR with validation',
            'AI spending insights',
            'Smart settlement suggestions',
            'Premium themes',
          ],
          highlight: false,
        ),
      ];
      emit(state.copyWith(status: BuyPlanStatus.ready, plans: plans));
    } catch (error) {
      emit(state.copyWith(status: BuyPlanStatus.error, errorMessage: error.toString()));
    }
  }
}
