import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanago/src/features/auth/data/in_memory_auth_repository.dart';
import 'package:tanago/src/features/auth/presentation/auth_controller.dart';
import 'package:tanago/src/features/shopping_list/data/in_memory_shopping_list_repository.dart';
import 'package:tanago/src/features/shopping_list/presentation/shopping_list_controller.dart';

void main() {
  test('records who added and purchased an item', () async {
    final repository = InMemoryShoppingListRepository();
    final auth = InMemoryAuthRepository();
    final localUserId = auth.currentUser!.uid;
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        shoppingListRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(shoppingListControllerProvider('home'));
    await controller.add('牛乳');

    final added = (await repository.getItems('home')).single;
    expect(added.addedByUid, localUserId);
    expect(added.isPurchased, isFalse);
    expect(added.purchasedByUid, isNull);

    await controller.togglePurchased(added.id);

    final purchased = (await repository.getItems('home')).single;
    expect(purchased.isPurchased, isTrue);
    expect(purchased.purchasedByUid, localUserId);
    expect(purchased.purchasedAt, isNotNull);

    await controller.togglePurchased(added.id);

    final reverted = (await repository.getItems('home')).single;
    expect(reverted.isPurchased, isFalse);
    expect(reverted.purchasedByUid, isNull);
    expect(reverted.purchasedAt, isNull);
  });
}
