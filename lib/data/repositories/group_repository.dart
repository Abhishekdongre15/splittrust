import '../../domain/entities/activity_event.dart';
import '../../domain/entities/group.dart';

abstract class GroupRepository {
  Future<List<Group>> getGroupsForUser(String uid);
  Future<Group> getGroupById(String id);
  Future<List<ActivityEvent>> recentActivity(String uid);
}
