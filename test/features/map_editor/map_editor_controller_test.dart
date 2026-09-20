import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanago/src/features/map_editor/domain/map_object.dart';
import 'package:tanago/src/features/map_editor/presentation/map_editor_controller.dart';

void main() {
  test('adds and edits a shelf', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(mapEditorProvider('store-a').notifier);
    controller.add(type: MapObjectType.shelf, x: 1, y: 2);

    final added = container.read(mapEditorProvider('store-a')).single;
    expect(added.width, 3);
    expect(added.height, 1);

    controller.move(id: added.id, x: 4, y: 5);
    controller.resize(id: added.id, width: 5, height: 2);
    controller.updateDetails(
      id: added.id,
      label: '乳製品',
      categoryIds: const ['dairy'],
    );

    final edited = container.read(mapEditorProvider('store-a')).single;
    expect(edited.x, 4);
    expect(edited.y, 5);
    expect(edited.width, 5);
    expect(edited.height, 2);
    expect(edited.label, '乳製品');
    expect(edited.categoryIds, const ['dairy']);
  });

  test('clears a shelf label', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(mapEditorProvider('store-a').notifier);
    controller.add(type: MapObjectType.shelf, x: 0, y: 0);

    final id = container.read(mapEditorProvider('store-a')).single.id;
    controller.updateDetails(id: id, label: '精肉');
    controller.updateDetails(id: id, label: '');

    expect(container.read(mapEditorProvider('store-a')).single.label, isNull);
  });
}
