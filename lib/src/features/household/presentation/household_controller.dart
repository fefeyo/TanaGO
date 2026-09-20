import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/in_memory_household_repository.dart';
import '../domain/household.dart';
import '../domain/household_repository.dart';

const localUserId = 'local-user';
const localUserDisplayName = 'あなた';

final householdRepositoryProvider = Provider<HouseholdRepository>(
  (ref) => InMemoryHouseholdRepository(),
);

final householdProvider = StreamProvider<Household?>(
  (ref) => ref.watch(householdRepositoryProvider).watchCurrentHousehold(localUserId),
);

final householdMembersProvider = StreamProvider.family<List<HouseholdMember>, String>(
  (ref, householdId) => ref.watch(householdRepositoryProvider).watchMembers(householdId),
);

final householdControllerProvider = Provider<HouseholdController>(
  (ref) => HouseholdController(repository: ref.watch(householdRepositoryProvider)),
);

class HouseholdController {
  HouseholdController({required HouseholdRepository repository}) : _repository = repository;
  final HouseholdRepository _repository;

  Future<Household> create(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const HouseholdValidationException('世帯名を入力してください');
    }
    return _repository.createHousehold(
      name: trimmed,
      ownerUid: localUserId,
      ownerDisplayName: localUserDisplayName,
    );
  }

  Future<Household> join(String inviteCode) {
    final trimmed = inviteCode.trim();
    if (trimmed.isEmpty) {
      throw const HouseholdValidationException('招待コードを入力してください');
    }
    return _repository.joinHousehold(
      inviteCode: trimmed,
      uid: localUserId,
      displayName: localUserDisplayName,
    );
  }

  Future<String> getInviteCode(String householdId) {
    return _repository.getInviteCode(householdId);
  }
}

class HouseholdValidationException implements Exception {
  const HouseholdValidationException(this.message);
  final String message;
  @override
  String toString() => message;
}
