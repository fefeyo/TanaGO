import 'package:flutter_test/flutter_test.dart';
import 'package:tanago/src/features/map_editor/domain/map_object.dart';
import 'package:tanago/src/features/shopping_list/domain/shopping_item.dart';
import 'package:tanago/src/features/shopping_map/domain/shopping_map_matcher.dart';

void main() {
  const dairyShelf = MapObject(
    id: 'dairy-shelf',
    type: MapObjectType.shelf,
    x: 0,
    y: 0,
    width: 3,
    height: 1,
    categoryIds: ['dairy'],
  );
  const seasoningShelf = MapObject(
    id: 'seasoning-shelf',
    type: MapObjectType.shelf,
    x: 0,
    y: 2,
    width: 3,
    height: 1,
    categoryIds: ['seasonings'],
  );

  ShoppingItem item({
    required String id,
    required String name,
    required String categoryId,
    bool isPurchased = false,
  }) {
    return ShoppingItem(
      id: id,
      name: name,
      addedByUid: 'user-a',
      createdAt: DateTime(2026),
      categoryId: categoryId,
      isPurchased: isPurchased,
    );
  }

  test('highlights shelves for unpurchased item categories', () {
    final ids = requiredShelfIds(
      objects: const [dairyShelf, seasoningShelf],
      shoppingItems: [
        item(id: 'milk', name: '牛乳', categoryId: 'dairy'),
        item(
          id: 'soy-sauce',
          name: 'しょうゆ',
          categoryId: 'seasonings',
          isPurchased: true,
        ),
      ],
    );

    expect(ids, {'dairy-shelf'});
  });

  test('returns all items assigned to selected shelf', () {
    final items = [
      item(id: 'milk', name: '牛乳', categoryId: 'dairy'),
      item(
        id: 'eggs',
        name: '卵',
        categoryId: 'dairy',
        isPurchased: true,
      ),
      item(id: 'soy-sauce', name: 'しょうゆ', categoryId: 'seasonings'),
    ];

    final result = itemsForShelf(
      shelf: dairyShelf,
      shoppingItems: items,
    );

    expect(result.map((item) => item.name), ['牛乳', '卵']);
  });
}
