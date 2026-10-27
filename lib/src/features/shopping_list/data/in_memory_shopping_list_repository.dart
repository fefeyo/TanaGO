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

  final _history = <String, Map<String, PurchaseRecord>>{};
  final _historyControllers =
      <String, StreamController<List<PurchaseRecord>>>{};
  StreamController<List<PurchaseRecord>> _historyController(String hid) =>
      _historyControllers.putIfAbsent(
        hid,
        () => StreamController<List<PurchaseRecord>>.broadcast(),
      );
  List<PurchaseRecord> _recent(String hid) =>
      (_history[hid]?.values.toList() ?? [])
        ..sort((a, b) => b.item.purchasedAt!.compareTo(a.item.purchasedAt!));
  @override
  Stream<List<PurchaseRecord>> watchRecentPurchases(String householdId) async* {
    yield _recent(householdId).take(60).toList();
    yield* _historyController(householdId).stream;
  }

  @override
  Future<List<PurchaseRecord>> purchaseItems(
    String householdId,
    Set<String> itemIds, {
    required String purchaseId,
    required String purchasedByUid,
  }) async {
    final history = _history.putIfAbsent(householdId, () => {});
    final result = <PurchaseRecord>[];
    for (final id in itemIds) {
      final item = (_items[householdId] ?? [])
          .where((item) => item.id == id)
          .firstOrNull;
      if (item == null) {
        if (history[id]?.purchaseId == purchaseId) result.add(history[id]!);
        continue;
      }
      if (history.containsKey(id)) throw StateError('Already archived');
      final record = PurchaseRecord(
        item: item.copyWith(
          isPurchased: true,
          purchasedByUid: purchasedByUid,
          purchasedAt: DateTime.now(),
        ),
        purchaseId: purchaseId,
      );
      history[id] = record;
      result.add(record);
    }
    _items[householdId] = [...?_items[householdId]]
        .where((item) => !itemIds.contains(item.id))
        .toList();
    _emit(householdId);
    _historyController(householdId).add(_recent(householdId).take(60).toList());
    return result;
  }

  @override
  Future<void> undoPurchase(
    String householdId,
    List<PurchaseRecord> records,
  ) async {
    final history = _history[householdId] ?? {};
    final active = [...?_items[householdId]];
    for (final record in records) {
      final stored = history[record.item.id];
      if (stored?.purchaseId != record.purchaseId) continue;
      if (!active.any((item) => item.id == record.item.id)) {
        active.add(
          stored!.item.copyWith(
            isPurchased: false,
            clearPurchasedByUid: true,
            clearPurchasedAt: true,
          ),
        );
      }
      history.remove(record.item.id);
    }
    _items[householdId] = active;
    _emit(householdId);
    _historyController(householdId).add(_recent(householdId).take(60).toList());
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
