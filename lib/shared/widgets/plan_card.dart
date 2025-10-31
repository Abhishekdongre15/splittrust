import 'package:flutter/material.dart';

import '../../features/plans/models/plan.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({super.key, required this.plan, required this.onSelect});

  final Plan plan;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = plan.highlight ? colorScheme.primary : colorScheme.outlineVariant;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: plan.highlight ? 2 : 1),
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                plan.tier.displayName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (plan.highlight)
                Container(
                  margin: const EdgeInsets.only(left: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Popular',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: colorScheme.onPrimaryContainer),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(plan.priceLabel, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(plan.description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          ...plan.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(feature)),
                ],
              ),
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: onSelect,
            child: Text('Choose ${plan.tier.displayName}'),
          ),
        ],
      ),
    );
  }
}
