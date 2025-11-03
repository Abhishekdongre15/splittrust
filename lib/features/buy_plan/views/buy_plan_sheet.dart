import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/widgets/buy_plan_card.dart';
import '../cubit/buy_plan_cubit.dart';
import '../cubit/buy_plan_state.dart';
import '../models/buy_plan.dart';

class BuyPlanSheet extends StatelessWidget {
  const BuyPlanSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      builder: (context, controller) {
        return BlocBuilder<BuyPlanCubit, BuyPlanState>(
          builder: (context, state) {
            final plans = state.plans;
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Choose the BuyPlan that fits you',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Gold unlocks subscriptions with Razorpay, Diamond gives you lifetime access with OCR and AI.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    if (state.status == BuyPlanStatus.loading && plans.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else
                      Expanded(
                        child: ListView.separated(
                          controller: controller,
                          itemCount: plans.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final plan = plans[index];
                            return SizedBox(
                              height: 280,
                              child: BuyPlanCard(
                                plan: plan,
                                onSelect: () => _onPlanSelected(context, plan),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onPlanSelected(BuildContext context, BuyPlan plan) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected ${plan.tier.displayName}. Razorpay flow goes here.')),
    );
  }
}
