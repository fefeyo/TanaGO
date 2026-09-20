import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/household.dart';

const localUserId = 'local-user';

final householdProvider = Provider<Household>(
  (ref) => const Household(
    id: 'local-household',
    name: 'わが家',
    createdByUid: localUserId,
  ),
);

final householdMembersProvider = Provider<List<HouseholdMember>>(
  (ref) => const [
    HouseholdMember(
      uid: localUserId,
      displayName: 'あなた',
      role: HouseholdRole.owner,
    ),
  ],
);
