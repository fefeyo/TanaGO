import 'shopping_item.dart';

abstract interface class ShoppingListRepository {
  Stream<List<ShoppingItem>> watchItems(String householdId);
  Future<List<ShoppingItem>> getItems(String householdId);
  Future<void> addItem(String householdId, ShoppingItem item);
  // The pure update callback may run more than once on a transaction retry.
  // Missing/deleted items are not recreated.
  Future<void> updateItem(
    String householdId,
    String itemId,
    ShoppingItem Function(ShoppingItem current) update,
  );
  Future<void> removeItems(String householdId, Set<String> itemIds);
  Future<void> removeItem(String householdId, String itemId);
}
