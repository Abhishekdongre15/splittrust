import 'package:equatable/equatable.dart';

import 'plan_tier.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.id,
    required this.name,
    required this.plan,
    required this.phone,
    required this.email,
    required this.baseCurrency,
    required this.avatarUrl,
    required this.isGuest,
  });

  final String id;
  final String name;
  final PlanType plan;
  final String phone;
  final String? email;
  final String baseCurrency;
  final String? avatarUrl;
  final bool isGuest;

  UserProfile copyWith({
    String? name,
    PlanType? plan,
    String? phone,
    String? email,
    String? baseCurrency,
    String? avatarUrl,
    bool? isGuest,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      plan: plan ?? this.plan,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  @override
  List<Object?> get props => [id, name, plan, phone, email, baseCurrency, avatarUrl, isGuest];
}
