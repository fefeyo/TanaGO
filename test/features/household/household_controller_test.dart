import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanago/src/features/household/presentation/household_controller.dart';

void main() {
  test('starts without a household and creates one', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(householdControllerProvider);
    final household = await controller.create('わが家');

    expect(household.name, 'わが家');

    final repository = container.read(householdRepositoryProvider);
    final current = await repository
        .watchCurrentHousehold(localUserId)
        .first;
    expect(current?.id, household.id);

    final members = await repository.watchMembers(household.id).first;
    expect(members, hasLength(1));
    expect(members.single.uid, localUserId);
  });

  test('rejects blank household name and invite code', () async {
    final container = ProviderContainer();
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
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(householdControllerProvider);
    final household = await controller.create('わが家');
    final code = await controller.getInviteCode(household.id);

    expect(code, startsWith('TANA-'));
  });
}
