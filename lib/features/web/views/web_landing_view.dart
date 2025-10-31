import 'package:flutter/material.dart';

class WebLandingView extends StatelessWidget {
  const WebLandingView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SplitTrust', style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  'Manage group expenses across Android and iOS. Our progressive web landing helps you discover plans and download the apps.',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.android),
                      label: const Text('Download for Android'),
                    ),
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.phone_iphone),
                      label: const Text('Download for iOS'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.support_agent),
                      label: const Text('Support'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Plans at a glance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 12),
                        Text('• Silver: Free, equal splits, ad-supported.'),
                        Text('• Gold: Subscription with Razorpay, advanced splits, receipts, exports.'),
                        Text('• Diamond: Lifetime, OCR, AI insights, smart settlements, premium themes.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
