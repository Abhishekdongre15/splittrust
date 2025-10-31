import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../presentation/viewmodels/plan/plan_view_model.dart';
import '../presentation/views/root/root_view.dart';
import 'theme/app_theme.dart';

class SplitTrustApp extends StatelessWidget {
  const SplitTrustApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlanViewModel()..loadPlans(),
      child: MaterialApp(
        title: 'SplitTrust',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const RootView(),
      ),
    );
  }
}
