import 'dart:async';

import '../domain/map_object.dart';
import '../domain/map_repository.dart';
import '../domain/store_map_key.dart';

class InMemoryMapRepository implements MapRepository {
  final _objects = <StoreMapKey, List<MapObject>>{};
  final _controllers =
      <StoreMapKey, StreamController<List<MapObject>>>{};

  @override
  Stream<List<MapObject>> watchObjects(StoreMapKey key) async* {
    yield List.unmodifiable(_objects[key] ?? const []);
    yield* _controller(key).stream;
  }

  @override
  Future<List<MapObject>> getObjects(StoreMapKey key) async {
    return List.unmodifiable(_objects[key] ?? const []);
  }

  @override
  Future<void> saveObject(StoreMapKey key, MapObject object) async {
    final current = _objects[key] ?? const <MapObject>[];
    final exists = current.any((item) => item.id == object.id);
    _objects[key] = exists
        ? [
            for (final item in current)
              if (item.id == object.id) object else item,
          ]
        : [...current, object];
    _emit(key);
  }

  @override
  Future<void> removeObject(StoreMapKey key, String objectId) async {
    _objects[key] = [
      for (final object in _objects[key] ?? const <MapObject>[])
        if (object.id != objectId) object,
    ];
    _emit(key);
  }

  @override
  Future<void> clear(StoreMapKey key) async {
    _objects[key] = const [];
    _emit(key);
  }

  StreamController<List<MapObject>> _controller(StoreMapKey key) {
    return _controllers.putIfAbsent(
      key,
      () => StreamController<List<MapObject>>.broadcast(),
    );
  }

  void _emit(StoreMapKey key) {
    _controller(key).add(
      List.unmodifiable(_objects[key] ?? const []),
    );
  }
}
