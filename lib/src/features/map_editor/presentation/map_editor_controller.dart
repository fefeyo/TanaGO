import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/map_object.dart';

final mapEditorProvider =
    NotifierProvider<MapEditorController, List<MapObject>>(
  MapEditorController.new,
);

class MapEditorController extends Notifier<List<MapObject>> {
  static const _uuid = Uuid();

  @override
  List<MapObject> build() => const [];

  void add({
    required MapObjectType type,
    required int x,
    required int y,
  }) {
    state = [
      ...state,
      MapObject(
        id: _uuid.v4(),
        type: type,
        x: x,
        y: y,
        width: type == MapObjectType.shelf ? 3 : 1,
        height: 1,
      ),
    ];
  }

  void remove(String id) {
    state = state.where((object) => object.id != id).toList();
  }

  void clear() {
    state = const [];
  }
}
