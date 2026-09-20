import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanago/src/features/map_editor/domain/map_object.dart';
import 'package:tanago/src/features/map_editor/presentation/map_editor_controller.dart';

void main() {
  test('adds and edits a shelf', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(mapEditorControllerProvider('store-a'));
    final repository = container.read(mapRepositoryProvider);

    await controller.add(type: MapObjectType.shelf, x: 1, y: 2);
    var object = (await repository.getObjects('store-a')).single;
    expect(object.width, 3);
    expect(object.height, 1);

    await controller.move(id: object.id, x: 4, y: 5);
    await controller.resize(id: object.id, width: 5, height: 2);
    await controller.updateDetails(
      id: object.id,
      label: '乳製品',
      categoryIds: const ['dairy'],
    );

    object = (await repository.getObjects('store-a')).single;
    expect(object.x, 4);
    expect(object.y, 5);
    expect(object.width, 5);
    expect(object.height, 2);
    expect(object.label, '乳製品');
    expect(object.categoryIds, const ['dairy']);
  });

  test('clears a shelf label', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(mapEditorControllerProvider('store-a'));
    final repository = container.read(mapRepositoryProvider);

    await controller.add(type: MapObjectType.shelf, x: 0, y: 0);
    final id = (await repository.getObjects('store-a')).single.id;
    await controller.updateDetails(id: id, label: '精肉');
    await controller.updateDetails(id: id, label: '');

    expect((await repository.getObjects('store-a')).single.label, isNull);
  });

  test('keeps map objects isolated per store', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(mapEditorControllerProvider('store-a'))
        .add(type: MapObjectType.shelf, x: 1, y: 1);
    await container
        .read(mapEditorControllerProvider('store-b'))
        .add(type: MapObjectType.register, x: 8, y: 12);

    final repository = container.read(mapRepositoryProvider);
    expect((await repository.getObjects('store-a')).single.type, MapObjectType.shelf);
    expect(
      (await repository.getObjects('store-b')).single.type,
      MapObjectType.register,
    );

    await container.read(mapEditorControllerProvider('store-a')).clear();

    expect(await repository.getObjects('store-a'), isEmpty);
    expect(await repository.getObjects('store-b'), hasLength(1));
  });
}
