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

    final id = container.read(shoppingListProvider).single.id;
    controller.togglePurchased(id);
    expect(container.read(shoppingListProvider).single.isPurchased, isTrue);

    controller.remove(id);
    expect(container.read(shoppingListProvider), isEmpty);
  });
}
