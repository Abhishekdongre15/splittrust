import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splittrust/presentation/views/home/widgets/plan_card.dart';

import '../../../app/theme/app_colors.dart';
import '../../viewmodels/plan/plan_state.dart';
import '../../viewmodels/plan/plan_view_model.dart';

class PlanSelectionView extends StatelessWidget {
  const PlanSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: BlocBuilder<PlanViewModel, PlanState>(
        builder: (context, state) {
          if (state.status == PlanStatus.loading || state.status == PlanStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == PlanStatus.failure) {
            return Center(
              child: Text(
                state.errorMessage ?? 'Something went wrong',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plans tailored for every team',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Razorpay handles Gold subscriptions monthly while Diamond is a one-time unlock.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 700;
                    return GridView.count(
                      crossAxisCount: isWide ? 3 : 1,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: isWide ? 0.9 : 1.1,
                      children: state.plans
                          .map(
                            (plan) => PlanCard(
                              plan: plan,
                              isSelected: state.selectedTier == plan.tier,
                              onSelected: () => context.read<PlanViewModel>().selectPlan(plan.tier),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
