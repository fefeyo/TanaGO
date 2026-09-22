import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanago/src/features/household/domain/household.dart';
import 'package:tanago/src/features/household/presentation/household_controller.dart';
import 'package:tanago/src/features/map_editor/data/in_memory_map_repository.dart';
import 'package:tanago/src/features/map_editor/domain/map_object.dart';
import 'package:tanago/src/features/map_editor/domain/store_map_key.dart';
import 'package:tanago/src/features/map_editor/presentation/map_editor_controller.dart';
import 'package:tanago/src/features/map_editor/presentation/map_editor_page.dart';
import 'package:tanago/src/features/map_editor/presentation/map_viewport.dart';
import 'package:tanago/src/features/stores/data/in_memory_store_repository.dart';
import 'package:tanago/src/features/stores/domain/store.dart';
import 'package:tanago/src/features/stores/presentation/store_controller.dart';

void main() {
  testWidgets(
      'expands a store, navigates without placing and edits beyond the old bounds',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final stores = InMemoryStoreRepository();
    final maps = InMemoryMapRepository();
    const key = StoreMapKey(householdId: 'h', storeId: 's');
    await stores.addStore(
      'h',
      const Store(
        id: 's',
        householdId: 'h',
        name: '店',
        mapWidth: 12,
        mapHeight: 16,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          householdProvider.overrideWith(
            (ref) => Stream.value(
              const Household(id: 'h', name: '家', createdByUid: 'u'),
            ),
          ),
          storeRepositoryProvider.overrideWithValue(stores),
          mapRepositoryProvider.overrideWithValue(maps),
        ],
        child: const MaterialApp(home: MapEditorPage(storeId: 's')),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('12 × 16 マス'), findsOneWidget);
    await tester.tap(find.byTooltip('マス目を増やす'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '24');
    await tester.enterText(find.byType(TextFormField).at(1), '32');
    await tester.tap(find.text('広げる'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('24 × 32 マス'), findsOneWidget);
    expect((await stores.getStores('h')).single.mapWidth, 24);

    await tester.tap(find.text('移動・拡大'));
    await tester.pumpAndSettle();
    final viewport =
        tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    final center = tester.getCenter(find.byKey(const ValueKey('map-viewport')));
    await tester.tapAt(center);
    await tester.pumpAndSettle();
    expect(await maps.getObjects(key), isEmpty);
    await tester.dragFrom(center, const Offset(-200, -200));
    await tester.pumpAndSettle();
    expect(viewport.transformationController!.value.storage[12], lessThan(0));
    expect(await maps.getObjects(key), isEmpty);

    await tester.tap(find.byTooltip('全体を表示'));
    await tester.pumpAndSettle();
    final transform = viewport.transformationController!;
    expect(transform.value.getMaxScaleOnAxis(), lessThan(1));
    await tester.tap(find.text('移動・拡大'));
    await tester.pumpAndSettle();
    final scenePoint =
        const Offset(20.5 * MapViewport.cellSize, 25.5 * MapViewport.cellSize);
    final screenPoint =
        MatrixUtils.transformPoint(transform.value, scenePoint) +
            tester.getTopLeft(find.byKey(const ValueKey('map-viewport')));
    await tester.tapAt(screenPoint);
    await tester.pumpAndSettle();
    final object = (await maps.getObjects(key)).single;
    expect(object.x, 20);
    expect(object.y, 25);
    // Confirm that the object recognizer wins over InteractiveViewer in edit mode.
    final tile = find.byKey(ValueKey('map-object-${object.id}'));
    final scale = transform.value.getMaxScaleOnAxis();
    await tester.drag(
      tile,
      Offset(
        -4 * MapViewport.cellSize * scale,
        -4 * MapViewport.cellSize * scale,
      ),
    );
    await tester.pumpAndSettle();
    final moved = (await maps.getObjects(key)).single;
    expect(moved.x, 16);
    expect(moved.y, 21);
    expect(tester.takeException(), isNull);
  });

  test(
      'controller respects expanded dimensions for placement, movement and resizing',
      () async {
    final repository = InMemoryMapRepository();
    const key = StoreMapKey(householdId: 'h', storeId: 's');
    final controller = MapEditorController(repository: repository, key: key);
    await controller.add(
      type: MapObjectType.shelf,
      x: 99,
      y: 200,
      mapWidth: 100,
      mapHeight: 100,
    );
    var object = (await repository.getObjects(key)).single;
    expect(object.x, 97);
    expect(object.y, 99);
    await controller.move(
      id: object.id,
      x: 40,
      y: 50,
      mapWidth: 100,
      mapHeight: 100,
    );
    await controller.resize(
      id: object.id,
      width: 80,
      height: 80,
      mapWidth: 100,
      mapHeight: 100,
    );
    object = (await repository.getObjects(key)).single;
    expect(object.x, 40);
    expect(object.y, 50);
    expect(object.width, 60);
    expect(object.height, 50);
  });
}
