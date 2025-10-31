import 'package:flutter_bloc/flutter_bloc.dart';

class SplitTrustBlocObserver extends BlocObserver {
  const SplitTrustBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
  }
}
