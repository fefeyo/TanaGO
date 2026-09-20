import 'dart:async';

import '../domain/store.dart';
import '../domain/store_repository.dart';

class InMemoryStoreRepository implements StoreRepository {
  final _stores = <String, List<Store>>{};
  final _controllers = <String, StreamController<List<Store>>>{};

  @override
  Stream<List<Store>> watchStores(String householdId) async* {
    yield List.unmodifiable(_stores[householdId] ?? const []);
    yield* _controller(householdId).stream;
  }

  @override
  Future<void> addStore(String householdId, Store store) async {
    _stores[householdId] = [...?_stores[householdId], store];
    _emit(householdId);
  }

  @override
  Future<void> removeStore(String householdId, String storeId) async {
    _stores[householdId] = [
      for (final store in _stores[householdId] ?? const <Store>[])
        if (store.id != storeId) store,
    ];
    _emit(householdId);
  }

  StreamController<List<Store>> _controller(String householdId) {
    return _controllers.putIfAbsent(
      householdId,
      () => StreamController<List<Store>>.broadcast(),
    );
  }

  void _emit(String householdId) {
    _controller(householdId).add(
      List.unmodifiable(_stores[householdId] ?? const []),
    );
  }
}
