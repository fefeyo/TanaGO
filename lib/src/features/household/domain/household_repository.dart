import 'household.dart';

abstract interface class HouseholdRepository {
  Stream<Household?> watchCurrentHousehold(String uid);
  Stream<List<HouseholdMember>> watchMembers(String householdId);

  Future<Household> createHousehold({
    required String name,
    required String ownerUid,
    required String ownerDisplayName,
  });

  Future<Household> joinHousehold({
    required String inviteCode,
    required String uid,
    required String displayName,
  });

  Future<void> updateMemberName(String householdId, String uid, String name);

  Future<String> getInviteCode(String householdId);
}
