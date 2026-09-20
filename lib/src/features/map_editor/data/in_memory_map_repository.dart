import 'dart:async';

import '../domain/map_object.dart';
import '../domain/map_repository.dart';

class InMemoryMapRepository implements MapRepository {
  final _objects = <String, List<MapObject>>{};
  final _controllers = <String, StreamController<List<MapObject>>>{};

  @override
  Stream<List<MapObject>> watchObjects(String storeId) async* {
    yield List.unmodifiable(_objects[storeId] ?? const []);
    yield* _controller(storeId).stream;
  }

  @override
  Future<List<MapObject>> getObjects(String storeId) async {
    return List.unmodifiable(_objects[storeId] ?? const []);
  }

  @override
  Future<void> saveObject(String storeId, MapObject object) async {
    final current = _objects[storeId] ?? const <MapObject>[];
    final exists = current.any((item) => item.id == object.id);
    _objects[storeId] = exists
        ? [
            for (final item in current)
              if (item.id == object.id) object else item,
          ]
        : [...current, object];
    _emit(storeId);
  }

  @override
  Future<void> removeObject(String storeId, String objectId) async {
    _objects[storeId] = [
      for (final object in _objects[storeId] ?? const <MapObject>[])
        if (object.id != objectId) object,
    ];
    _emit(storeId);
  }

  @override
  Future<void> clear(String storeId) async {
    _objects[storeId] = const [];
    _emit(storeId);
  }

  StreamController<List<MapObject>> _controller(String storeId) {
    return _controllers.putIfAbsent(
      storeId,
      () => StreamController<List<MapObject>>.broadcast(),
    );
  }

  void _emit(String storeId) {
    _controller(storeId).add(
      List.unmodifiable(_objects[storeId] ?? const []),
    );
  }
}
