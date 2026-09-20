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
