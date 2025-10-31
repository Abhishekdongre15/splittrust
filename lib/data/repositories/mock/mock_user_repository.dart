import 'dart:async';

import '../../../domain/entities/plan_tier.dart';
import '../../../domain/entities/user_profile.dart';
import '../user_repository.dart';

class MockUserRepository implements UserRepository {
  MockUserRepository();

  UserProfile _profile = const UserProfile(
    id: 'user_aqua',
    name: 'AquaFire Team',
    plan: PlanType.gold,
    phone: '+911234567890',
    email: 'team@splittrust.app',
    baseCurrency: 'INR',
    avatarUrl: null,
    isGuest: false,
  );

  @override
  Future<UserProfile> getCurrentUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _profile;
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _profile = profile;
  }

  @override
  Future<void> updatePlan(PlanType plan) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _profile = _profile.copyWith(plan: plan);
  }
}
