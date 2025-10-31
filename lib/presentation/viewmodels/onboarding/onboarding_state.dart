import 'package:equatable/equatable.dart';

import '../../../domain/entities/plan_tier.dart';

enum OnboardingStep { welcome, permissions, auth, profile, dashboard }

enum AuthMethod { phoneOtp, google, emailPassword, guest }

class OnboardingState extends Equatable {
  const OnboardingState({
    this.step = OnboardingStep.welcome,
    this.notificationsAllowed = false,
    this.selectedAuthMethod,
    this.phoneNumber,
    this.name,
    this.baseCurrency,
    this.avatarUrl,
    this.email,
    this.isComplete = false,
    this.plan = PlanType.silver,
  });

  final OnboardingStep step;
  final bool notificationsAllowed;
  final AuthMethod? selectedAuthMethod;
  final String? phoneNumber;
  final String? name;
  final String? baseCurrency;
  final String? avatarUrl;
  final String? email;
  final bool isComplete;
  final PlanType plan;

  OnboardingState copyWith({
    OnboardingStep? step,
    bool? notificationsAllowed,
    AuthMethod? selectedAuthMethod,
    String? phoneNumber,
    String? name,
    String? baseCurrency,
    String? avatarUrl,
    String? email,
    bool? isComplete,
    PlanType? plan,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      notificationsAllowed: notificationsAllowed ?? this.notificationsAllowed,
      selectedAuthMethod: selectedAuthMethod ?? this.selectedAuthMethod,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email ?? this.email,
      isComplete: isComplete ?? this.isComplete,
      plan: plan ?? this.plan,
    );
  }

  @override
  List<Object?> get props => [
        step,
        notificationsAllowed,
        selectedAuthMethod,
        phoneNumber,
        name,
        baseCurrency,
        avatarUrl,
        email,
        isComplete,
        plan,
      ];
}
