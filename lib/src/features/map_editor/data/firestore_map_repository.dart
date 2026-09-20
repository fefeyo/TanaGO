import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/map_object.dart';
import '../domain/map_repository.dart';
import '../domain/store_map_key.dart';

class FirestoreMapRepository implements MapRepository {
  FirestoreMapRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _objects(StoreMapKey key) {
    return _firestore
        .collection('households')
        .doc(key.householdId)
        .collection('stores')
        .doc(key.storeId)
        .collection('mapObjects');
  }

  @override
  Stream<List<MapObject>> watchObjects(StoreMapKey key) {
    return _objects(key).snapshots().map(
          (snapshot) => snapshot.docs.map(_fromDocument).toList(),
        );
  }

  @override
  Future<List<MapObject>> getObjects(StoreMapKey key) async {
    final snapshot = await _objects(key).get();
    return snapshot.docs.map(_fromDocument).toList();
  }

  @override
  Future<void> saveObject(StoreMapKey key, MapObject object) {
    return _objects(key).doc(object.id).set(_toMap(object));
  }

  @override
  Future<void> removeObject(StoreMapKey key, String objectId) {
    return _objects(key).doc(objectId).delete();
  }

  @override
  Future<void> clear(StoreMapKey key) async {
    final snapshot = await _objects(key).get();
    final batch = _firestore.batch();
    for (final document in snapshot.docs) {
      batch.delete(document.reference);
    }
    await batch.commit();
  }

  MapObject _fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final typeName = data['type'] as String?;
    final type = MapObjectType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => MapObjectType.shelf,
    );

    return MapObject(
      id: document.id,
      type: type,
      x: (data['x'] as num?)?.toInt() ?? 0,
      y: (data['y'] as num?)?.toInt() ?? 0,
      width: (data['width'] as num?)?.toInt() ?? 1,
      height: (data['height'] as num?)?.toInt() ?? 1,
      label: data['label'] as String?,
      categoryIds: List<String>.from(
        data['categoryIds'] as List<dynamic>? ?? const [],
      ),
    );
  }

  Map<String, dynamic> _toMap(MapObject object) {
    return {
      'type': object.type.name,
      'x': object.x,
      'y': object.y,
      'width': object.width,
      'height': object.height,
      'label': object.label,
      'categoryIds': object.categoryIds,
    };
  }
}
