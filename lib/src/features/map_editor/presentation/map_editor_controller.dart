import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/in_memory_map_repository.dart';
import '../domain/map_object.dart';
import '../domain/map_repository.dart';
import '../domain/store_map_key.dart';

final mapRepositoryProvider = Provider<MapRepository>(
  (ref) => InMemoryMapRepository(),
);

final mapEditorProvider =
    StreamProvider.family<List<MapObject>, StoreMapKey>(
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
  }) {
    return _repository.saveObject(
      _key,
      MapObject(
        id: _uuid.v4(),
        type: type,
        x: x,
        y: y,
        width: type == MapObjectType.shelf ? 3 : 1,
        height: 1,
      ),
    );
  }

  Future<void> move({
    required String id,
    required int x,
    required int y,
  }) async {
    final object = await _findObject(id);
    if (object == null) return;
    await _repository.saveObject(_key, object.copyWith(x: x, y: y));
  }

  Future<void> resize({
    required String id,
    required int width,
    required int height,
  }) async {
    final object = await _findObject(id);
    if (object == null) return;
    await _repository.saveObject(
      _key,
      object.copyWith(
        width: width.clamp(1, 12),
        height: height.clamp(1, 16),
      ),
    );
  }

  Future<void> updateDetails({
    required String id,
    String? label,
    List<String>? categoryIds,
  }) async {
    final object = await _findObject(id);
    if (object == null) return;
    await _repository.saveObject(
      _key,
      object.copyWith(
        label: label,
        categoryIds: categoryIds,
        clearLabel: label != null && label.trim().isEmpty,
      ),
    );
  }

  Future<void> remove(String id) {
    return _repository.removeObject(_key, id);
  }

  Future<void> clear() {
    return _repository.clear(_key);
  }

  Future<MapObject?> _findObject(String id) async {
    final objects = await _repository.getObjects(_key);
    for (final object in objects) {
      if (object.id == id) return object;
    }
    return null;
  }
}
