import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../viewmodels/dashboard/dashboard_state.dart';
import '../../viewmodels/dashboard/dashboard_view_model.dart';
import '../../viewmodels/reports/reports_state.dart';
import '../../viewmodels/reports/reports_view_model.dart';

class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: BlocBuilder<ReportsViewModel, ReportsState>(
        builder: (context, reports) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exports & analytics',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Gold unlocks CSV/PDF while Diamond adds Excel and Drive sync.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              _GroupPicker(selected: reports.includeGroups),
              const SizedBox(height: 16),
              _DateRangeSelector(selected: reports.dateRange),
              const SizedBox(height: 16),
              _FormatSelector(format: reports.format),
              SwitchListTile(
                value: reports.includeReceipts,
                onChanged: (value) => context.read<ReportsViewModel>().toggleReceipts(value),
                title: const Text('Include receipt links'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: reports.status == ReportStatus.generating
                        ? null
                        : () => context.read<ReportsViewModel>().generate(),
                    icon: const Icon(Icons.download),
                    label: Text(reports.status == ReportStatus.generating ? 'Generating…' : 'Generate report'),
                  ),
                  const SizedBox(width: 12),
                  if (reports.status == ReportStatus.ready && reports.link != null)
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.link),
                        label: Text(reports.link!),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GroupPicker extends StatelessWidget {
  const _GroupPicker({required this.selected});

  final List<String> selected;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardViewModel, DashboardState>(
      builder: (context, state) {
        final groups = state.groups;
        return Wrap(
          spacing: 8,
          children: groups
              .map(
                (group) => FilterChip(
                  label: Text(group.name),
                  selected: selected.contains(group.id),
                  onSelected: (value) {
                    final updated = List<String>.from(selected);
                    if (value) {
                      updated.add(group.id);
                    } else {
                      updated.remove(group.id);
                    }
                    context.read<ReportsViewModel>().setGroups(updated);
                  },
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _DateRangeSelector extends StatelessWidget {
  const _DateRangeSelector({required this.selected});

  final Duration selected;

  @override
  Widget build(BuildContext context) {
    const options = [
      Duration(days: 30),
      Duration(days: 90),
      Duration(days: 180),
    ];
    const labels = ['Last 30 days', 'Last 90 days', 'Last 6 months'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date range', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(options.length, (index) {
            final option = options[index];
            final label = labels[index];
            final isSelected = option == selected;
            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => context.read<ReportsViewModel>().setDateRange(option),
            );
          }),
        ),
      ],
    );
  }
}

class _FormatSelector extends StatelessWidget {
  const _FormatSelector({required this.format});

  final ExportFormat format;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Format', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ExportFormat.values
              .map(
                (value) => ChoiceChip(
                  label: Text(value.name.toUpperCase()),
                  selected: value == format,
                  onSelected: (_) => context.read<ReportsViewModel>().setFormat(value),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
