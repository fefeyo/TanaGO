import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/map_object.dart';

final mapEditorProvider =
    NotifierProvider.family<MapEditorController, List<MapObject>, String>(
  MapEditorController.new,
);

class MapEditorController extends FamilyNotifier<List<MapObject>, String> {
  static const _uuid = Uuid();

  @override
  List<MapObject> build(String storeId) => const [];

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

  void move({
    required String id,
    required int x,
    required int y,
  }) {
    _update(id, (object) => object.copyWith(x: x, y: y));
  }

  void resize({
    required String id,
    required int width,
    required int height,
  }) {
    _update(
      id,
      (object) => object.copyWith(
        width: width.clamp(1, 12),
        height: height.clamp(1, 16),
      ),
    );
  }

  void updateDetails({
    required String id,
    String? label,
    List<String>? categoryIds,
  }) {
    _update(
      id,
      (object) => object.copyWith(
        label: label,
        categoryIds: categoryIds,
        clearLabel: label != null && label.trim().isEmpty,
      ),
    );
  }

  void remove(String id) {
    state = state.where((object) => object.id != id).toList();
  }

  void clear() {
    state = const [];
  }

  void _update(
    String id,
    MapObject Function(MapObject object) transform,
  ) {
    state = [
      for (final object in state)
        if (object.id == id) transform(object) else object,
    ];
  }
}
