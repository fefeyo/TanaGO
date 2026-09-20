import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanago/src/features/household/presentation/household_controller.dart';
import 'package:tanago/src/features/shopping_list/presentation/shopping_list_controller.dart';

void main() {
  test('records who added and purchased an item', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(shoppingListProvider.notifier);
    controller.add('牛乳');

    final added = container.read(shoppingListProvider).single;
    expect(added.addedByUid, localUserId);
    expect(added.isPurchased, isFalse);
    expect(added.purchasedByUid, isNull);

    controller.togglePurchased(added.id);

    final purchased = container.read(shoppingListProvider).single;
    expect(purchased.isPurchased, isTrue);
    expect(purchased.purchasedByUid, localUserId);
    expect(purchased.purchasedAt, isNotNull);

    controller.togglePurchased(added.id);

    final reverted = container.read(shoppingListProvider).single;
    expect(reverted.isPurchased, isFalse);
    expect(reverted.purchasedByUid, isNull);
    expect(reverted.purchasedAt, isNull);
  });
}
