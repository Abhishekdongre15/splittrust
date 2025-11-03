import 'package:equatable/equatable.dart';

enum OnboardingStep { welcome, permissions, auth, profile, done }

enum AuthMethod { phoneOtp, google, emailPassword, guest }

class OnboardingState extends Equatable {
  const OnboardingState({
    this.step = OnboardingStep.welcome,
    this.notificationsAllowed = false,
    this.selectedAuthMethod,
    this.name = '',
    this.baseCurrency = 'INR',
    this.email = '',
    this.isComplete = false,
  });

  final OnboardingStep step;
  final bool notificationsAllowed;
  final AuthMethod? selectedAuthMethod;
  final String name;
  final String baseCurrency;
  final String email;
  final bool isComplete;

  OnboardingState copyWith({
    OnboardingStep? step,
    bool? notificationsAllowed,
    AuthMethod? selectedAuthMethod,
    String? name,
    String? baseCurrency,
    String? email,
    bool? isComplete,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      notificationsAllowed: notificationsAllowed ?? this.notificationsAllowed,
      selectedAuthMethod: selectedAuthMethod ?? this.selectedAuthMethod,
      name: name ?? this.name,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      email: email ?? this.email,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  @override
  List<Object?> get props => [
        step,
        notificationsAllowed,
        selectedAuthMethod,
        name,
        baseCurrency,
        email,
        isComplete,
      ];
}
