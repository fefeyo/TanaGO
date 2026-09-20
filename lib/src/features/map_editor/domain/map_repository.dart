import 'map_object.dart';

abstract interface class MapRepository {
  Stream<List<MapObject>> watchObjects(String storeId);
  Future<List<MapObject>> getObjects(String storeId);
  Future<void> saveObject(String storeId, MapObject object);
  Future<void> removeObject(String storeId, String objectId);
  Future<void> clear(String storeId);
}
