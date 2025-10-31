import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../home/home_view.dart';
import '../web/web_landing_view.dart';

class RootView extends StatelessWidget {
  const RootView({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const WebLandingView();
    }
    return const HomeView();
  }
}
