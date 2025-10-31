import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/plan.dart';
import 'plan_state.dart';

class PlanCubit extends Cubit<PlanState> {
  PlanCubit() : super(const PlanState());

  Future<void> load() async {
    if (state.status == PlanStatus.loading) return;
    emit(state.copyWith(status: PlanStatus.loading));
    try {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      const plans = [
        Plan(
          tier: PlanTier.silver,
          priceLabel: 'Free',
          description: 'Track shared expenses with equal splits and ad support.',
          features: [
            'Unlimited groups',
            'Equal split mode',
            'Ad-supported experience',
          ],
          highlight: false,
        ),
        Plan(
          tier: PlanTier.gold,
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
        Plan(
          tier: PlanTier.diamond,
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
      emit(state.copyWith(status: PlanStatus.ready, plans: plans));
    } catch (error) {
      emit(state.copyWith(status: PlanStatus.error, errorMessage: error.toString()));
    }
  }
}
