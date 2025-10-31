import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../viewmodels/onboarding/onboarding_state.dart';
import '../../viewmodels/onboarding/onboarding_view_model.dart';
import '../home/home_view.dart';
import '../onboarding/onboarding_flow_view.dart';
import '../web/web_landing_view.dart';

class RootView extends StatelessWidget {
  const RootView({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const WebLandingView();
    }
    return BlocBuilder<OnboardingViewModel, OnboardingState>(
      builder: (context, state) {
        if (!state.isComplete) {
          return const OnboardingFlowView();
        }
        return const HomeView();
      },
    );
  }
}
