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

bool hasMemberName(String name, {String? uid}) =>
    name.trim().isNotEmpty && name.trim() != 'あなた' && name.trim() != uid;

String memberName(List<HouseholdMember> members, String uid) {
  final member = members.where((m) => m.uid == uid).firstOrNull;
  if (member != null && hasMemberName(member.displayName, uid: uid)) {
    return member.displayName.trim();
  }
  final sortedUids = members.map((m) => m.uid).toList()..sort();
  final index = sortedUids.indexOf(uid);
  return index < 0 ? '名前未設定のメンバー' : 'メンバー${index + 1}（名前未設定）';
}
