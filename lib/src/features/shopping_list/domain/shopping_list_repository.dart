import 'shopping_item.dart';

abstract interface class ShoppingListRepository {
  Stream<List<ShoppingItem>> watchItems(String householdId);

  Future<void> addItem(String householdId, ShoppingItem item);

  Future<void> updateItem(String householdId, ShoppingItem item);

  Future<void> removeItem(String householdId, String itemId);
}
