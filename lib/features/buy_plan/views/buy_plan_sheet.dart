import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../shared/widgets/buy_plan_card.dart';
import '../cubit/buy_plan_cubit.dart';
import '../cubit/buy_plan_state.dart';
import '../models/buy_plan.dart';

class BuyPlanSheet extends StatefulWidget {
  const BuyPlanSheet({super.key});

  @override
  State<BuyPlanSheet> createState() => _BuyPlanSheetState();
}

class _BuyPlanSheetState extends State<BuyPlanSheet> {
  Razorpay? _razorpay;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _razorpay = Razorpay()
        ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess)
        ..on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError)
        ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

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
                    Text(
                      'Choose the BuyPlan that fits you',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gold unlocks subscriptions with Razorpay billing, Diamond gives you lifetime access with OCR and AI.',
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
                                onSelect: () => _onPlanSelected(plan),
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

  void _onPlanSelected(BuyPlan plan) {
    final messenger = ScaffoldMessenger.of(context);
    if (plan.amountPaise == null || plan.amountPaise == 0) {
      messenger.showSnackBar(
        SnackBar(content: Text('${plan.tier.displayName} is free – you already have access.')),
      );
      return;
    }
    if (kIsWeb) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Razorpay checkout is available on Android and iOS devices. Select ${plan.tier.displayName} there.'),
        ),
      );
      return;
    }
    final razorpay = _razorpay;
    if (razorpay == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Razorpay is not initialised on this platform.')),
      );
      return;
    }

    final options = {
      'key': 'rzp_test_EeSbik6brgd3Ma',
      'amount': plan.amountPaise,
      'currency': 'INR',
      'name': 'SplitTrust',
      'description': '${plan.tier.displayName} plan purchase',
      'notes': {'plan_tier': plan.tier.displayName.toLowerCase()},
      'theme': {'color': '#2B8A60'},
    };

    try {
      razorpay.open(options);
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Unable to launch Razorpay: $error')),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).maybePop();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Payment successful (${response.paymentId ?? 'Razorpay'})! Enjoy your new plan.'),
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message ?? response.code.toString()}'),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text('External wallet selected: ${response.walletName ?? 'wallet'}'),
      ),
    );
  }
}
