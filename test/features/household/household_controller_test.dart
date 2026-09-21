import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanago/src/features/auth/data/in_memory_auth_repository.dart';
import 'package:tanago/src/features/auth/presentation/auth_controller.dart';
import 'package:tanago/src/features/household/data/in_memory_household_repository.dart';
import 'package:tanago/src/features/household/presentation/household_controller.dart';

ProviderContainer createContainer() {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(InMemoryAuthRepository()),
      householdRepositoryProvider.overrideWithValue(
        InMemoryHouseholdRepository(),
      ),
    ],
  );
}

void main() {
  test('starts without a household and creates one', () async {
    final container = createContainer();
    addTearDown(container.dispose);

    final controller = container.read(householdControllerProvider);
    final household = await controller.create('わが家');

    expect(household.name, 'わが家');

    final repository = container.read(householdRepositoryProvider);
    final user = container.read(authRepositoryProvider).currentUser!;
    final current = await repository
        .watchCurrentHousehold(user.uid)
        .first;
    expect(current?.id, household.id);

    final members = await repository.watchMembers(household.id).first;
    expect(members, hasLength(1));
    expect(members.single.uid, user.uid);
  });

  test('rejects blank household name and invite code', () async {
    final container = createContainer();
    addTearDown(container.dispose);

    final controller = container.read(householdControllerProvider);

    expect(
      () => controller.create('   '),
      throwsA(isA<HouseholdValidationException>()),
    );
    expect(
      () => controller.join(''),
      throwsA(isA<HouseholdValidationException>()),
    );
  });

  test('creates an invite code for the household', () async {
    final container = createContainer();
    addTearDown(container.dispose);

    final controller = container.read(householdControllerProvider);
    final household = await controller.create('わが家');
    final code = await controller.getInviteCode(household.id);

    expect(code, startsWith('TANA-'));
  });
}
