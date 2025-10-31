import '../../domain/entities/plan_tier.dart';
import '../../domain/entities/user_profile.dart';

abstract class UserRepository {
  Future<UserProfile> getCurrentUser();
  Future<void> updatePlan(PlanType plan);
  Future<void> saveProfile(UserProfile profile);
}
