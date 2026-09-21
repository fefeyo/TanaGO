import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanago/src/features/auth/data/in_memory_auth_repository.dart';
import 'package:tanago/src/features/auth/presentation/auth_controller.dart';
import 'package:tanago/src/features/shopping_list/data/in_memory_shopping_list_repository.dart';
import 'package:tanago/src/features/shopping_list/presentation/shopping_list_controller.dart';

ProviderContainer createContainer() {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(InMemoryAuthRepository()),
      shoppingListRepositoryProvider.overrideWithValue(
        InMemoryShoppingListRepository(),
      ),
    ],
  );
}

void main() {
  test('adds, categorizes, toggles, and removes shopping items', () async {
    final container = createContainer();
    addTearDown(container.dispose);

    final controller =
        container.read(shoppingListControllerProvider('household-a'));
    final repository = container.read(shoppingListRepositoryProvider);

    await controller.add('牛乳');
    var items = await repository.getItems('household-a');
    expect(items.single.name, '牛乳');
    expect(items.single.categoryId, 'dairy');

    final id = items.single.id;
    await controller.updateCategory(id, 'beverages');
    await controller.togglePurchased(id);

    items = await repository.getItems('household-a');
    expect(items.single.categoryId, 'beverages');
    expect(items.single.isPurchased, isTrue);

    await controller.remove(id);
    expect(await repository.getItems('household-a'), isEmpty);
  });

  test('keeps unknown category empty and explicit category wins', () async {
    final container = createContainer();
    addTearDown(container.dispose);

    final controller =
        container.read(shoppingListControllerProvider('household-a'));
    final repository = container.read(shoppingListRepositoryProvider);

    await controller.add('いつものやつ');
    await controller.add('牛乳', categoryId: 'beverages');

    final items = await repository.getItems('household-a');
    expect(items[0].categoryId, isNull);
    expect(items[1].categoryId, 'beverages');
  });

  test('keeps shopping items isolated per household', () async {
    final container = createContainer();
    addTearDown(container.dispose);

    await container
        .read(shoppingListControllerProvider('household-a'))
        .add('牛乳');
    await container
        .read(shoppingListControllerProvider('household-b'))
        .add('しょうゆ');

    final repository = container.read(shoppingListRepositoryProvider);
    expect((await repository.getItems('household-a')).single.name, '牛乳');
    expect((await repository.getItems('household-b')).single.name, 'しょうゆ');
  });
}
