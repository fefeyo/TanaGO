import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanago/src/features/map_editor/domain/map_object.dart';
import 'package:tanago/src/features/map_editor/presentation/draggable_map_object.dart';

const shelf = MapObject(
  id: 'shelf',
  type: MapObjectType.shelf,
  x: 1,
  y: 1,
  width: 3,
  height: 1,
);
final tile = find.byKey(const ValueKey('map-object-shelf'));

class Fixture {
  MapObject object = shelf;
  final pending = <Completer<Offset?>>[];
  final writes = <Offset>[];
  int errors = 0;
  late StateSetter rebuild;
  final transform = TransformationController();

  Future<void> mount(WidgetTester tester, {double scale = 1}) async {
    transform.value = Matrix4.diagonal3Values(scale, scale, scale);
    addTearDown(transform.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return Transform.scale(
                scale: scale,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 432,
                  height: 576,
                  child: Stack(
                    children: [
                      DraggableMapObject(
                        key: const ValueKey('shelf'),
                        object: object,
                        columns: 12,
                        rows: 16,
                        transform: transform,
                        enabled: true,
                        onMove: (x, y) {
                          writes.add(Offset(x.toDouble(), y.toDouble()));
                          final completer = Completer<Offset?>();
                          pending.add(completer);
                          return completer.future;
                        },
                        onError: () => errors++,
                        onTap: () {},
                        onLongPress: () {},
                        child: const ColoredBox(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> snapshot(WidgetTester tester, MapObject value) async {
    rebuild(() => object = value);
    await tester.pump();
  }
}

Future<TestGesture> move(WidgetTester tester, Offset delta) async {
  final gesture = await tester.startGesture(tester.getCenter(tile));
  // Separate updates exercise position changes while hit testing the same tile.
  await gesture.moveBy(delta / 2);
  await tester.pump();
  await gesture.moveBy(delta / 2);
  await tester.pump();
  return gesture;
}

void main() {
  testWidgets('moves immediately, saves once on drop, ignores stale snapshots',
      (tester) async {
    final f = Fixture();
    await f.mount(tester);
    final start = tester.getTopLeft(tile);
    final gesture = await move(tester, const Offset(54, 36));
    expect(tester.getTopLeft(tile), start + const Offset(54, 36));
    expect(f.writes, isEmpty);
    await gesture.up();
    await tester.pump();
    expect(f.writes, [const Offset(3, 2)]);
    expect(tester.getTopLeft(tile), const Offset(108, 72));
    await f.snapshot(tester, shelf.copyWith(label: 'new label'));
    expect(tester.getTopLeft(tile), const Offset(108, 72));
    f.pending.single.complete(const Offset(3, 2));
    await tester.pump();
    expect(tester.getTopLeft(tile), const Offset(108, 72));
    await f.snapshot(tester, shelf.copyWith(x: 3, y: 2));
    await f.snapshot(tester, shelf.copyWith(x: 4, y: 3));
    expect(tester.getTopLeft(tile), const Offset(144, 108));
  });

  testWidgets(
      'successive drags serialize writes and never rewind to the first save',
      (tester) async {
    final f = Fixture();
    await f.mount(tester);
    await (await move(tester, const Offset(72, 0))).up();
    await tester.pump();
    await (await move(tester, const Offset(36, 36))).up();
    await tester.pump();
    expect(f.writes, [const Offset(3, 1)]);
    expect(tester.getTopLeft(tile), const Offset(144, 72));
    await f.snapshot(tester, shelf.copyWith(x: 3));
    f.pending.first.complete(const Offset(3, 1));
    await tester.pump();
    expect(f.writes, [const Offset(3, 1), const Offset(4, 2)]);
    expect(tester.getTopLeft(tile), const Offset(144, 72));
    await f.snapshot(tester, shelf.copyWith(x: 4, y: 2));
    f.pending.last.complete(const Offset(4, 2));
    await tester.pump();
    expect(tester.getTopLeft(tile), const Offset(144, 72));
  });

  testWidgets('cancel restores the pre-drag position without a write',
      (tester) async {
    final f = Fixture();
    await f.mount(tester);
    await (await move(tester, const Offset(72, 36))).cancel();
    await tester.pump();
    expect(f.writes, isEmpty);
    expect(tester.getTopLeft(tile), const Offset(36, 36));
  });

  testWidgets('failed save restores server position and reports the error',
      (tester) async {
    final f = Fixture();
    await f.mount(tester);
    await (await move(tester, const Offset(72, 0))).up();
    await tester.pump();
    f.pending.single.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(f.errors, 1);
    expect(tester.getTopLeft(tile), const Offset(36, 36));
    expect(tester.takeException(), isNull);
  });

  testWidgets('drag coordinates account for zoom and moving tile transforms',
      (tester) async {
    final f = Fixture();
    await f.mount(tester, scale: 2);
    final start = tester.getTopLeft(tile);
    await (await move(tester, const Offset(72, 72))).up();
    await tester.pump();
    expect(tester.getTopLeft(tile), start + const Offset(72, 72));
    expect(f.writes.single, const Offset(2, 2));
    f.pending.single.complete(const Offset(2, 2));
    await tester.pump();
  });

  testWidgets('drag on a zoomed-out map stays under the pointer',
      (tester) async {
    final f = Fixture();
    await f.mount(tester, scale: 0.5);
    final start = tester.getTopLeft(tile);
    await (await move(tester, const Offset(36, 36))).up();
    await tester.pump();
    expect(tester.getTopLeft(tile), start + const Offset(36, 36));
    expect(f.writes.single, const Offset(3, 3));
    f.pending.single.complete(const Offset(3, 3));
    await tester.pump();
  });

  testWidgets('stays inside bounds and skips unchanged drops', (tester) async {
    final f = Fixture();
    f.object = shelf.copyWith(x: 0, y: 0);
    await f.mount(tester);
    await (await move(tester, const Offset(-100, -100))).up();
    await tester.pump();
    expect(tester.getTopLeft(tile), Offset.zero);
    expect(f.writes, isEmpty);
    await (await move(tester, const Offset(1000, 1000))).up();
    await tester.pump();
    expect(f.writes.single, const Offset(9, 15));
    f.pending.single.complete(const Offset(9, 15));
    await tester.pump();
  });

  testWidgets('cancel a second drag after the first save completes',
      (tester) async {
    final f = Fixture();
    await f.mount(tester);
    await (await move(tester, const Offset(72, 0))).up();
    await tester.pump();
    final next = await move(tester, const Offset(36, 36));
    await f.snapshot(tester, shelf.copyWith(x: 3));
    f.pending.single.complete(const Offset(3, 1));
    await tester.pump();
    await next.cancel();
    await tester.pump();
    expect(tester.getTopLeft(tile), const Offset(108, 36));
    expect(f.writes.length, 1);
  });
}
