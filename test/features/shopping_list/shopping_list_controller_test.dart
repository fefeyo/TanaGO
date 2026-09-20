import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanago/src/features/shopping_list/presentation/shopping_list_controller.dart';

void main() {
  test('adds, toggles, and removes shopping items', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(shoppingListProvider.notifier);

    controller.add('牛乳');
    expect(container.read(shoppingListProvider), hasLength(1));
    expect(container.read(shoppingListProvider).single.name, '牛乳');
    expect(container.read(shoppingListProvider).single.categoryId, 'dairy');

    final id = container.read(shoppingListProvider).single.id;
    controller.updateCategory(id, 'beverages');
    expect(
      container.read(shoppingListProvider).single.categoryId,
      'beverages',
    );

    controller.togglePurchased(id);
    expect(container.read(shoppingListProvider).single.isPurchased, isTrue);

    controller.remove(id);
    expect(container.read(shoppingListProvider), isEmpty);
  });

  test('keeps category empty when it cannot classify an item', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(shoppingListProvider.notifier).add('いつものやつ');

    expect(container.read(shoppingListProvider).single.categoryId, isNull);
  });

  test('explicit category overrides automatic classification', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(shoppingListProvider.notifier)
        .add('牛乳', categoryId: 'beverages');

    expect(
      container.read(shoppingListProvider).single.categoryId,
      'beverages',
    );
  });
}
