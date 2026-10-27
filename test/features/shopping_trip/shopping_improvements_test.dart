import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tanago/src/app.dart';
import 'package:tanago/src/features/map_editor/domain/store_map_key.dart';
import 'package:tanago/src/features/map_editor/domain/map_object.dart';
import 'package:tanago/src/features/shopping_list/data/in_memory_shopping_list_repository.dart';
import 'package:tanago/src/features/shopping_list/domain/shopping_item.dart';
import 'package:tanago/src/features/shopping_trip/presentation/shopping_trip_controller.dart';
import 'shopping_flow_test.dart' show FlowFixture;

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets(
      'shared dialog edits optional details without making empty rows taller',
      (tester) async {
    final f = FlowFixture();
    await f.mount(tester);
    await tester.tap(find.text('牛乳'));
    await tester.pumpAndSettle();
    final quantity = find.widgetWithText(TextFormField, '数量（任意）');
    final memo = find.widgetWithText(TextFormField, 'メモ（任意）');
    await tester.ensureVisible(quantity);
    await tester.enterText(quantity, '2本');
    await tester.ensureVisible(memo);
    await tester.enterText(memo, '青いパッケージ');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    var milk =
        (await f.items.getItems(f.hid)).singleWhere((i) => i.id == 'milk');
    expect(milk.quantity, '2本');
    expect(milk.memo, '青いパッケージ');
    expect(find.text('2本 · 青いパッケージ'), findsOneWidget);
    await tester.tap(find.text('牛乳'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(quantity).controller!.text, '2本');
    expect(tester.widget<TextFormField>(memo).controller!.text, '青いパッケージ');
    await tester.ensureVisible(quantity);
    await tester.enterText(quantity, '');
    await tester.ensureVisible(memo);
    await tester.enterText(memo, '');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    milk = (await f.items.getItems(f.hid)).singleWhere((i) => i.id == 'milk');
    expect(milk.details, isEmpty);
    expect(milk.addedByUid, 'family-b');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'completion can be undone and history re-add preserves details with a fresh ID',
      (tester) async {
    final f = FlowFixture();
    await f.mount(tester);
    await f.items.updateItem(
      f.hid,
      'milk',
      (i) => i.copyWith(
        quantity: '2本',
        memo: '青いパッケージ',
        priority: ShoppingPriority.high,
      ),
    );
    final container =
        ProviderScope.containerOf(tester.element(find.byType(TanaGoApp)));
    final key = StoreMapKey(householdId: f.hid, storeId: 's');
    final router = GoRouter.of(tester.element(find.byType(Scaffold)));
    Future<void> complete() async {
      final trip = container.read(shoppingTripProvider(key).notifier);
      trip.select('milk', true);
      trip.check('milk', true);
      router.go('/stores/s/complete');
      await tester.pumpAndSettle();
      await tester.tap(find.text('購入を確定する'));
      await tester.pumpAndSettle();
    }

    await complete();
    expect(await f.items.getItems(f.hid), hasLength(2));
    await tester.tap(find.text('購入完了を取り消す'));
    await tester.pumpAndSettle();
    final restored =
        (await f.items.getItems(f.hid)).singleWhere((i) => i.id == 'milk');
    expect(restored.addedByUid, 'family-b');
    expect(restored.quantity, '2本');
    expect(await f.items.watchRecentPurchases(f.hid).first, isEmpty);
    await complete();
    await tester.tap(find.text('登録一覧に戻る'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('最近買ったものから追加'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('牛乳をもう一度登録'));
    await tester.pumpAndSettle();
    expect(find.text('登録済み'), findsOneWidget);
    expect(find.byTooltip('牛乳をもう一度登録'), findsNothing);
    final added =
        (await f.items.getItems(f.hid)).singleWhere((i) => i.name == '牛乳');
    expect(added.id, isNot('milk'));
    expect(added.addedByUid, 'local-user');
    expect(added.categoryId, 'dairy');
    expect(added.quantity, '2本');
    expect(added.memo, '青いパッケージ');
    expect(added.buySoon, isFalse);
    expect(await f.items.watchRecentPurchases(f.hid).first, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'unmapped and unclassified items remain checkable without any store map',
      (tester) async {
    final f = FlowFixture();
    await f.mount(tester);
    final key = StoreMapKey(householdId: f.hid, storeId: 's');
    await f.maps.clear(key);
    await f.items.addItem(
      f.hid,
      ShoppingItem(
        id: 'unknown',
        name: '頼まれたもの',
        addedByUid: 'local-user',
        createdAt: DateTime(2026),
      ),
    );
    GoRouter.of(tester.element(find.byType(Scaffold))).go('/stores/s/select');
    await tester.pumpAndSettle();
    expect(find.text('場所未登録'), findsOneWidget);
    for (final id in ['fish', 'unknown']) {
      await tester.ensureVisible(find.byKey(ValueKey('select-$id')));
      await tester.tap(find.byKey(ValueKey('select-$id')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('2点を持って店内マップへ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('リストを広げる'));
    await tester.pumpAndSettle();
    for (final id in ['fish', 'unknown']) {
      await tester.ensureVisible(find.byKey(ValueKey('map-check-$id')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('map-check-$id')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('購入内容を確認（2点）'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('購入を確定する'));
    await tester.pumpAndSettle();
    expect(
      (await f.items.getItems(f.hid)).map((i) => i.id).toSet(),
      {'milk', 'egg'},
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'product locates its shelf, shelf filters products, sheet drags and checks stay independent',
      (tester) async {
    final f = FlowFixture();
    await f.mount(tester);
    final key = StoreMapKey(householdId: f.hid, storeId: 's');
    await f.maps.saveObject(
      key,
      const MapObject(
        id: 'fish-shelf',
        type: MapObjectType.shelf,
        x: 8,
        y: 10,
        width: 3,
        height: 2,
        label: '鮮魚売り場',
        categoryIds: ['seafood'],
      ),
    );
    final container =
        ProviderScope.containerOf(tester.element(find.byType(TanaGoApp)));
    final trip = container.read(shoppingTripProvider(key).notifier);
    trip.select('milk', true);
    trip.select('fish', true);
    GoRouter.of(tester.element(find.byType(Scaffold))).go('/stores/s/map');
    await tester.pumpAndSettle();
    final sheet = tester
        .widget<DraggableScrollableSheet>(find.byType(DraggableScrollableSheet))
        .controller!;
    final start = sheet.size;
    await tester.drag(find.text('今回買うもの'), const Offset(0, -140));
    await tester.pumpAndSettle();
    expect(sheet.size, greaterThan(start));
    await tester.ensureVisible(find.byKey(const ValueKey('map-locate-fish')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('map-locate-fish')));
    await tester.pumpAndSettle();
    expect(sheet.size, closeTo(0.32, 0.01));
    expect(container.read(shoppingTripProvider(key)).checked, isEmpty);
    final viewport = tester.getRect(find.byType(InteractiveViewer));
    final shelf =
        tester.getRect(find.byKey(const ValueKey('shopping-shelf-fish-shelf')));
    expect((viewport.center - shelf.center).distance, lessThan(2));
    await tester.tap(find.byKey(const ValueKey('shopping-shelf-fish-shelf')));
    await tester.pumpAndSettle();
    expect(sheet.size, closeTo(0.62, 0.01));
    expect(find.byKey(const ValueKey('map-check-milk')), findsNothing);
    final before = tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!
        .value
        .clone();
    await tester.ensureVisible(find.byKey(const ValueKey('map-check-fish')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('map-check-fish')));
    await tester.pumpAndSettle();
    expect(container.read(shoppingTripProvider(key)).checked, {'fish'});
    expect(
      tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!
          .value,
      before,
    );
    await tester.tap(find.byTooltip('すべての商品を表示'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('map-check-milk')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'retry after a partial purchase includes earlier successes in undo',
      (tester) async {
    final f = FlowFixture(repository: _PartialFailureRepository());
    await f.mount(tester);
    final key = StoreMapKey(householdId: f.hid, storeId: 's');
    final container =
        ProviderScope.containerOf(tester.element(find.byType(TanaGoApp)));
    final trip = container.read(shoppingTripProvider(key).notifier);
    for (final id in ['milk', 'egg']) {
      trip.select(id, true);
      trip.check(id, true);
    }
    GoRouter.of(tester.element(find.byType(Scaffold))).go('/stores/s/complete');
    await tester.pumpAndSettle();
    await tester.tap(find.text('購入を確定する'));
    await tester.pumpAndSettle();
    expect(await f.items.getItems(f.hid), hasLength(2));
    expect(find.textContaining('購入の確定に失敗しました'), findsOneWidget);
    await tester.tap(find.text('購入を確定する'));
    await tester.pumpAndSettle();
    expect(find.text('2点の購入が完了しました'), findsOneWidget);
    await tester.tap(find.text('購入完了を取り消す'));
    await tester.pumpAndSettle();
    expect(await f.items.getItems(f.hid), hasLength(3));
    expect(await f.items.watchRecentPurchases(f.hid).first, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

class _PartialFailureRepository extends InMemoryShoppingListRepository {
  bool fail = true;
  @override
  Future<List<PurchaseRecord>> purchaseItems(
    String householdId,
    Set<String> itemIds, {
    required String purchaseId,
    required String purchasedByUid,
  }) async {
    if (fail) {
      fail = false;
      await super.purchaseItems(
        householdId,
        {itemIds.first},
        purchaseId: purchaseId,
        purchasedByUid: purchasedByUid,
      );
      throw StateError('connection lost after first chunk');
    }
    return super.purchaseItems(
      householdId,
      itemIds,
      purchaseId: purchaseId,
      purchasedByUid: purchasedByUid,
    );
  }
}
