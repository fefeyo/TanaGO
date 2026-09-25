class Household {
  const Household({
    required this.id,
    required this.name,
    required this.createdByUid,
  });

  final String id;
  final String name;
  final String createdByUid;
}

class HouseholdMember {
  const HouseholdMember({
    required this.uid,
    required this.displayName,
    required this.role,
  });

  final String uid;
  final String displayName;
  final HouseholdRole role;
}

enum HouseholdRole {
  owner,
  member,
}

String memberName(List<HouseholdMember> members, String uid) {
  final member = members.where((m) => m.uid == uid).firstOrNull;
  final name = member?.displayName.trim();
  if (name != null && name.isNotEmpty && name != 'あなた') return name;
  final suffix = uid.length > 6 ? uid.substring(uid.length - 6) : uid;
  return 'メンバー $suffix';
}
