import 'map_object.dart';
import 'store_map_key.dart';

abstract interface class MapRepository {
  Stream<List<MapObject>> watchObjects(StoreMapKey key);
  Future<List<MapObject>> getObjects(StoreMapKey key);
  Future<void> saveObject(StoreMapKey key, MapObject object);
  Future<void> removeObject(StoreMapKey key, String objectId);
  Future<void> clear(StoreMapKey key);
}
