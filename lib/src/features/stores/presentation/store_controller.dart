import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/firestore_store_repository.dart';
import '../domain/store.dart';
import '../domain/store_repository.dart';

final storeRepositoryProvider = Provider<StoreRepository>(
  (ref) => FirestoreStoreRepository(FirebaseFirestore.instance),
);

final storesProvider = StreamProvider.autoDispose.family<List<Store>, String>(
  (ref, householdId) =>
      ref.watch(storeRepositoryProvider).watchStores(householdId),
);

final storeControllerProvider = Provider.family<StoreController, String>(
  (ref, householdId) => StoreController(
    repository: ref.watch(storeRepositoryProvider),
    householdId: householdId,
  ),
);

class StoreController {
  StoreController({
    required StoreRepository repository,
    required String householdId,
  })  : _repository = repository,
        _householdId = householdId;

  static const _uuid = Uuid();

  final StoreRepository _repository;
  final String _householdId;

  Future<void> add(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }

    await _repository.addStore(
      _householdId,
      Store(
        id: _uuid.v4(),
        householdId: _householdId,
        name: trimmed,
        mapWidth: 12,
        mapHeight: 16,
      ),
    );
  }

  Future<void> remove(String id) {
    return _repository.removeStore(_householdId, id);
  }
}
