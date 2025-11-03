import 'package:flutter_bloc/flutter_bloc.dart';

import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit() : super(const OnboardingState());

  void start() => emit(state.copyWith(step: OnboardingStep.welcome, isComplete: false));

  void startProfileCapture() =>
      emit(state.copyWith(step: OnboardingStep.profile, isComplete: false));

  void allowNotifications(bool allowed) =>
      emit(state.copyWith(notificationsAllowed: allowed));

  void selectAuth(AuthMethod method) =>
      emit(state.copyWith(selectedAuthMethod: method));

  void updateProfile({required String name, required String currency, String? email}) {
    emit(state.copyWith(name: name, baseCurrency: currency, email: email ?? ''));
  }

  void next() {
    switch (state.step) {
      case OnboardingStep.welcome:
        emit(state.copyWith(step: OnboardingStep.permissions));
        break;
      case OnboardingStep.permissions:
        emit(state.copyWith(step: OnboardingStep.auth));
        break;
      case OnboardingStep.auth:
        emit(state.copyWith(step: OnboardingStep.profile));
        break;
      case OnboardingStep.profile:
        emit(state.copyWith(step: OnboardingStep.done, isComplete: true));
        break;
      case OnboardingStep.done:
        break;
    }
  }

  void finish() => emit(state.copyWith(isComplete: true, step: OnboardingStep.done));
}
