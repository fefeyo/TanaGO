import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/in_memory_household_repository.dart';
import '../domain/household.dart';
import '../domain/household_repository.dart';

final householdRepositoryProvider = Provider<HouseholdRepository>(
  (ref) => InMemoryHouseholdRepository(),
);

final householdProvider = StreamProvider<Household?>((ref) async* {
  final user = await ref.watch(authUserProvider.future);
  if (user == null) {
    yield null;
    return;
  }

  yield* ref
      .watch(householdRepositoryProvider)
      .watchCurrentHousehold(user.uid);
});

final householdMembersProvider =
    StreamProvider.family<List<HouseholdMember>, String>(
  (ref, householdId) => ref
      .watch(householdRepositoryProvider)
      .watchMembers(householdId),
);

final householdControllerProvider = Provider<HouseholdController>(
  (ref) => HouseholdController(
    repository: ref.watch(householdRepositoryProvider),
    authRepository: ref.watch(authRepositoryProvider),
  ),
);

class HouseholdController {
  HouseholdController({
    required HouseholdRepository repository,
    required AuthRepository authRepository,
  })  : _repository = repository,
        _authRepository = authRepository;

  final HouseholdRepository _repository;
  final AuthRepository _authRepository;

  Future<Household> create(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const HouseholdValidationException('世帯名を入力してください');
    }

    final user = _authRepository.currentUser ?? await _authRepository.signIn();
    return _repository.createHousehold(
      name: trimmed,
      ownerUid: user.uid,
      ownerDisplayName: user.displayName,
    );
  }

  Future<Household> join(String inviteCode) async {
    final trimmed = inviteCode.trim();
    if (trimmed.isEmpty) {
      throw const HouseholdValidationException('招待コードを入力してください');
    }

    final user = _authRepository.currentUser ?? await _authRepository.signIn();
    return _repository.joinHousehold(
      inviteCode: trimmed,
      uid: user.uid,
      displayName: user.displayName,
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
