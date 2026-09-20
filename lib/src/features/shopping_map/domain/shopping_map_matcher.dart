import '../../map_editor/domain/map_object.dart';
import '../../shopping_list/domain/shopping_item.dart';

Set<String> requiredShelfIds({
  required List<MapObject> objects,
  required List<ShoppingItem> shoppingItems,
}) {
  final requiredCategoryIds = shoppingItems
      .where((item) => !item.isPurchased)
      .map((item) => item.categoryId)
      .whereType<String>()
      .toSet();

  return objects
      .where(
        (object) =>
            object.type == MapObjectType.shelf &&
            object.categoryIds.any(requiredCategoryIds.contains),
      )
      .map((object) => object.id)
      .toSet();
}

List<ShoppingItem> itemsForShelf({
  required MapObject shelf,
  required List<ShoppingItem> shoppingItems,
}) {
  return shoppingItems
      .where((item) => shelf.categoryIds.contains(item.categoryId))
      .toList();
}
