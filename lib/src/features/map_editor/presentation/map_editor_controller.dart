import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/firestore_map_repository.dart';
import '../domain/map_object.dart';
import '../domain/map_repository.dart';
import '../domain/store_map_key.dart';

final mapRepositoryProvider = Provider<MapRepository>(
  (ref) => FirestoreMapRepository(FirebaseFirestore.instance),
);

final mapEditorProvider =
    StreamProvider.autoDispose.family<List<MapObject>, StoreMapKey>(
  (ref, key) => ref.watch(mapRepositoryProvider).watchObjects(key),
);

final mapEditorControllerProvider =
    Provider.family<MapEditorController, StoreMapKey>(
  (ref, key) => MapEditorController(
    repository: ref.watch(mapRepositoryProvider),
    key: key,
  ),
);

class MapEditorController {
  MapEditorController({
    required MapRepository repository,
    required StoreMapKey key,
  })  : _repository = repository,
        _key = key;

  static const _uuid = Uuid();

  final MapRepository _repository;
  final StoreMapKey _key;

  Future<void> add({
    required MapObjectType type,
    required int x,
    required int y,
    int mapWidth = 12,
    int mapHeight = 16,
  }) {
    return _repository.saveObject(
      _key,
      MapObject(
        id: _uuid.v4(),
        type: type,
        x: x.clamp(0, mapWidth - (type == MapObjectType.shelf ? 3 : 1)),
        y: y.clamp(0, mapHeight - 1),
        width: type == MapObjectType.shelf ? 3 : 1,
        height: 1,
      ),
    );
  }

  Future<MapObject?> move({
    required String id,
    required int x,
    required int y,
    int mapWidth = 12,
    int mapHeight = 16,
  }) async {
    MapObject? saved;
    await _repository.updateObject(_key, id, (object) {
      saved = object.copyWith(
        x: x.clamp(0, mapWidth - object.width),
        y: y.clamp(0, mapHeight - object.height),
      );
      return saved!;
    });
    return saved;
  }

  Future<void> resize({
    required String id,
    required int width,
    required int height,
    int mapWidth = 12,
    int mapHeight = 16,
  }) {
    return _repository.updateObject(
      _key,
      id,
      (object) => object.copyWith(
        width: width.clamp(1, mapWidth - object.x),
        height: height.clamp(1, mapHeight - object.y),
      ),
    );
  }

  Future<void> updateDetails({
    required String id,
    String? label,
    List<String>? categoryIds,
  }) {
    return _repository.updateObject(
      _key,
      id,
      (object) => object.copyWith(
        label: label,
        categoryIds: categoryIds,
        clearLabel: label != null && label.trim().isEmpty,
      ),
    );
  }

  Future<void> remove(String id) => _repository.removeObject(_key, id);
  Future<void> clear() => _repository.clear(_key);
}
