import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanago/src/features/shopping_list/presentation/shopping_list_controller.dart';

void main() {
  test('adds, toggles, and removes shopping items', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(shoppingListProvider('household-a').notifier);

    controller.add('牛乳');
    expect(container.read(shoppingListProvider('household-a')), hasLength(1));
    expect(container.read(shoppingListProvider('household-a')).single.name, '牛乳');
    expect(container.read(shoppingListProvider('household-a')).single.categoryId, 'dairy');

    final id = container.read(shoppingListProvider('household-a')).single.id;
    controller.updateCategory(id, 'beverages');
    expect(
      container.read(shoppingListProvider('household-a')).single.categoryId,
      'beverages',
    );

    controller.togglePurchased(id);
    expect(container.read(shoppingListProvider('household-a')).single.isPurchased, isTrue);

    controller.remove(id);
    expect(container.read(shoppingListProvider('household-a')), isEmpty);
  });

  test('keeps category empty when it cannot classify an item', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(shoppingListProvider('household-a').notifier).add('いつものやつ');

    expect(container.read(shoppingListProvider('household-a')).single.categoryId, isNull);
  });

  test('explicit category overrides automatic classification', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(shoppingListProvider('household-a').notifier)
        .add('牛乳', categoryId: 'beverages');

    expect(
      container.read(shoppingListProvider('household-a')).single.categoryId,
      'beverages',
    );
  });

  test('keeps shopping items isolated per household', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(shoppingListProvider('household-a').notifier)
        .add('牛乳');
    container
        .read(shoppingListProvider('household-b').notifier)
        .add('しょうゆ');

    expect(
      container.read(shoppingListProvider('household-a')).single.name,
      '牛乳',
    );
    expect(
      container.read(shoppingListProvider('household-b')).single.name,
      'しょうゆ',
    );
  });
}
