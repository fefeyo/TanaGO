import 'store.dart';

abstract interface class StoreRepository {
  Stream<List<Store>> watchStores(String householdId);
  Future<List<Store>> getStores(String householdId);
  Future<void> addStore(String householdId, Store store);
  Future<void> expandMap(
    String householdId,
    String storeId, {
    required int width,
    required int height,
  });
  Future<void> removeStore(String householdId, String storeId);
}
