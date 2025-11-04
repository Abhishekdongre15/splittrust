import 'package:flutter/material.dart';

class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Reports & Exports', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Filter by group, category, or date range, then export CSV/PDF/XLSX (Gold & Diamond).'),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Download CSV'),
            subtitle: const Text('Gold and Diamond users can export detailed CSV reports.'),
            onTap: () {},
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('Generate PDF summary'),
            subtitle: const Text('Includes expenses, settlements, and summaries.'),
            onTap: () {},
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('Sync to Google Drive (.xlsx)'),
            subtitle: const Text('Diamond plan uploads multi-sheet Excel files to Drive.'),
            onTap: () {},
          ),
        ),
      ],
    );
  }
}
