import 'map_object.dart';
import 'store_map_key.dart';

abstract interface class MapRepository {
  Stream<List<MapObject>> watchObjects(StoreMapKey key);
  Future<List<MapObject>> getObjects(StoreMapKey key);
  Future<void> saveObject(StoreMapKey key, MapObject object);
  // Apply a pure transformation to the latest version, without recreating it.
  Future<void> updateObject(
    StoreMapKey key,
    String objectId,
    MapObject Function(MapObject current) update,
  );
  Future<void> removeObject(StoreMapKey key, String objectId);
  Future<void> clear(StoreMapKey key);
}
