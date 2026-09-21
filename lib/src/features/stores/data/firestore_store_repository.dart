import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/store.dart';
import '../domain/store_repository.dart';

class FirestoreStoreRepository implements StoreRepository {
  FirestoreStoreRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _stores(String householdId) {
    return _firestore
        .collection('households')
        .doc(householdId)
        .collection('stores');
  }

  @override
  Stream<List<Store>> watchStores(String householdId) {
    return _stores(householdId).orderBy('name').snapshots().map(
          (snapshot) => snapshot.docs
              .map((document) => _fromDocument(householdId, document))
              .toList(),
        );
  }

  @override
  Future<List<Store>> getStores(String householdId) async {
    final snapshot = await _stores(householdId).orderBy('name').get();
    return snapshot.docs
        .map((document) => _fromDocument(householdId, document))
        .toList();
  }

  @override
  Future<void> addStore(String householdId, Store store) {
    return _stores(householdId).doc(store.id).set(_toMap(store));
  }

  @override
  Future<void> removeStore(String householdId, String storeId) async {
    final store = _stores(householdId).doc(storeId);
    // Rules reject new/updated map objects once deletion starts. Retrying a
    // partially completed deletion is safe, including maps larger than a batch.
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(store);
      if (snapshot.exists) transaction.update(store, {'deleting': true});
    });
    while (true) {
      final objects = await store.collection('mapObjects').limit(400).get();
      if (objects.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final document in objects.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
    await store.delete();
  }

  Store _fromDocument(
    String householdId,
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return Store(
      id: document.id,
      householdId: householdId,
      name: data['name'] as String? ?? '',
      mapWidth: (data['mapWidth'] as num?)?.toInt() ?? 12,
      mapHeight: (data['mapHeight'] as num?)?.toInt() ?? 16,
    );
  }

  Map<String, dynamic> _toMap(Store store) {
    return {
      'name': store.name,
      'mapWidth': store.mapWidth,
      'mapHeight': store.mapHeight,
    };
  }
}
