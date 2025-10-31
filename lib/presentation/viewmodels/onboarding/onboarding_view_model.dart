import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/user_repository.dart';
import '../../../domain/entities/plan_tier.dart';
import 'onboarding_state.dart';

class OnboardingViewModel extends Cubit<OnboardingState> {
  OnboardingViewModel({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(const OnboardingState());

  final UserRepository _userRepository;

  Future<void> start() async {
    emit(state.copyWith(step: OnboardingStep.welcome));
  }

  void allowNotifications(bool allowed) {
    emit(state.copyWith(notificationsAllowed: allowed));
  }

  void selectAuth(AuthMethod method) {
    emit(state.copyWith(selectedAuthMethod: method));
  }

  void setPhone(String phone) {
    emit(state.copyWith(phoneNumber: phone));
  }

  void setProfile({required String name, required String baseCurrency, String? email}) {
    emit(state.copyWith(name: name, baseCurrency: baseCurrency, email: email));
  }

  void goToNext() {
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
        emit(state.copyWith(step: OnboardingStep.dashboard, isComplete: true));
        break;
      case OnboardingStep.dashboard:
        break;
    }
  }

  Future<void> upgradePlan(PlanType plan) async {
    await _userRepository.updatePlan(plan);
    emit(state.copyWith(plan: plan));
  }

  Future<void> finish() async {
    if (!state.isComplete) {
      emit(state.copyWith(isComplete: true));
    }
  }
}
