import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../data/models/plan.dart';
import '../../../../domain/entities/plan_tier.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({
    required this.plan,
    required this.isSelected,
    required this.onSelected,
    super.key,
  });

  final Plan plan;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: plan.highlighted ? AppColors.surface : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Icon(
                  _iconForPlan(plan.tier),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      plan.tagline,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            plan.priceText,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...plan.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: onSelected,
            style: FilledButton.styleFrom(
              backgroundColor: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.85),
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(isSelected ? 'Current Plan' : 'View ${plan.displayName}'),
          ),
        ],
      ),
    );
  }

  IconData _iconForPlan(PlanType tier) {
    switch (tier) {
      case PlanType.silver:
        return Icons.rocket_launch;
      case PlanType.gold:
        return Icons.auto_graph;
      case PlanType.diamond:
        return Icons.diamond;
    }
  }
}
