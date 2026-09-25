import 'dart:async';

import '../domain/shopping_item.dart';
import '../domain/shopping_list_repository.dart';

class InMemoryShoppingListRepository implements ShoppingListRepository {
  final _items = <String, List<ShoppingItem>>{};
  final _controllers = <String, StreamController<List<ShoppingItem>>>{};

  @override
  Stream<List<ShoppingItem>> watchItems(String householdId) async* {
    yield List.unmodifiable(_items[householdId] ?? const []);
    yield* _controller(householdId).stream;
  }

  @override
  Future<List<ShoppingItem>> getItems(String householdId) async {
    return List.unmodifiable(_items[householdId] ?? const []);
  }

  @override
  Future<void> addItem(String householdId, ShoppingItem item) async {
    final items = [...?_items[householdId], item];
    _items[householdId] = items;
    _emit(householdId);
  }

  @override
  Future<void> updateItem(
    String householdId,
    String itemId,
    ShoppingItem Function(ShoppingItem current) update,
  ) async {
    final items = [
      for (final current in _items[householdId] ?? const <ShoppingItem>[])
        if (current.id == itemId) update(current) else current,
    ];
    _items[householdId] = items;
    _emit(householdId);
  }

  @override
  Future<void> removeItems(String householdId, Set<String> itemIds) async {
    for (final id in itemIds) {
      await removeItem(householdId, id);
    }
  }

  @override
  Future<void> removeItem(String householdId, String itemId) async {
    _items[householdId] = [
      for (final item in _items[householdId] ?? const <ShoppingItem>[])
        if (item.id != itemId) item,
    ];
    _emit(householdId);
  }

  StreamController<List<ShoppingItem>> _controller(String householdId) {
    return _controllers.putIfAbsent(
      householdId,
      () => StreamController<List<ShoppingItem>>.broadcast(),
    );
  }

  void _emit(String householdId) {
    _controller(householdId).add(
      List.unmodifiable(_items[householdId] ?? const []),
    );
  }
}
