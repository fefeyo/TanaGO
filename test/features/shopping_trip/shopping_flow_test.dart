import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanago/src/app.dart';
import 'package:tanago/src/features/product_categories/domain/product_category.dart';
import 'package:tanago/src/features/household/domain/household.dart';
import 'package:tanago/src/features/auth/data/in_memory_auth_repository.dart';
import 'package:tanago/src/features/auth/presentation/auth_controller.dart';
import 'package:tanago/src/features/household/data/in_memory_household_repository.dart';
import 'package:tanago/src/features/household/presentation/household_controller.dart';
import 'package:tanago/src/features/map_editor/data/in_memory_map_repository.dart';
import 'package:tanago/src/features/map_editor/domain/map_object.dart';
import 'package:tanago/src/features/map_editor/domain/store_map_key.dart';
import 'package:tanago/src/features/map_editor/presentation/map_editor_controller.dart';
import 'package:tanago/src/features/product_categories/data/in_memory_category_repository.dart';
import 'package:tanago/src/features/product_categories/presentation/category_controller.dart';
import 'package:tanago/src/features/shopping_list/data/in_memory_shopping_list_repository.dart';
import 'package:tanago/src/features/shopping_list/domain/shopping_item.dart';
import 'package:tanago/src/features/shopping_list/presentation/shopping_list_controller.dart';
import 'package:tanago/src/features/shopping_trip/presentation/shopping_trip_controller.dart';
import 'package:tanago/src/features/stores/data/in_memory_store_repository.dart';
import 'package:tanago/src/features/stores/domain/store.dart';
import 'package:tanago/src/features/stores/presentation/store_controller.dart';

class FlowFixture {
  FlowFixture({InMemoryShoppingListRepository? repository})
      : items = repository ?? InMemoryShoppingListRepository();
  final auth = InMemoryAuthRepository();
  final homes = InMemoryHouseholdRepository();
  final InMemoryShoppingListRepository items;
  final stores = InMemoryStoreRepository();
  final maps = InMemoryMapRepository();
  final categories = InMemoryCategoryRepository();
  late String hid;
  Future<void> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final home = await homes.createHousehold(
      name: 'テストの家',
      ownerUid: 'local-user',
      ownerDisplayName: 'ゆう',
    );
    hid = home.id;
    await homes.joinHousehold(
      inviteCode: await homes.getInviteCode(hid),
      uid: 'family-b',
      displayName: 'あき',
    );
    await stores.addStore(
      hid,
      Store(
        id: 's',
        householdId: hid,
        name: 'スーパーA',
        mapWidth: 12,
        mapHeight: 16,
      ),
    );
    await maps.saveObject(
      StoreMapKey(householdId: hid, storeId: 's'),
      const MapObject(
        id: 'shelf',
        type: MapObjectType.shelf,
        x: 1,
        y: 1,
        width: 3,
        height: 1,
        label: '冷蔵',
        categoryIds: ['dairy'],
      ),
    );
    for (final entry in [
      ('milk', '牛乳', 'dairy', 'family-b'),
      ('egg', '卵', 'dairy', 'local-user'),
      ('fish', '鮭', 'seafood', 'family-b'),
    ]) {
      await items.addItem(
        hid,
        ShoppingItem(
          id: entry.$1,
          name: entry.$2,
          categoryId: entry.$3,
          addedByUid: entry.$4,
          createdAt: DateTime(2026),
        ),
      );
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          householdRepositoryProvider.overrideWithValue(homes),
          shoppingListRepositoryProvider.overrideWithValue(items),
          storeRepositoryProvider.overrideWithValue(stores),
          mapRepositoryProvider.overrideWithValue(maps),
          categoryRepositoryProvider.overrideWithValue(categories),
        ],
        child: const TanaGoApp(),
      ),
    );
    await tester.pumpAndSettle();
  }
}

class FailingCompletionRepository extends InMemoryShoppingListRepository {
  bool fail = true;
  @override
  Future<void> removeItems(String hid, Set<String> ids) async {
    if (fail) {
      fail = false;
      throw StateError('offline');
    }
    await super.removeItems(hid, ids);
  }
}

void main() {
  testWidgets(
      'purchase confirmation can uncheck and recheck without losing rows',
      (tester) async {
    final f = FlowFixture();
    await f.mount(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(TanaGoApp)));
    final key = StoreMapKey(householdId: f.hid, storeId: 's');
    final trip = container.read(shoppingTripProvider(key).notifier);
    trip.select('milk', true);
    trip.select('egg', true);
    trip.check('milk', true);
    trip.check('egg', true);
    GoRouter.of(tester.element(find.byType(Scaffold))).go('/stores/s/complete');
    await tester.pumpAndSettle();
    final milk = find.byKey(const ValueKey('confirm-milk'));
    final egg = find.byKey(const ValueKey('confirm-egg'));
    await tester.tap(milk);
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(milk).value, isFalse);
    expect(find.text('チェックした1点を購入済みにします'), findsOneWidget);
    await tester.tap(egg);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '購入を確定する'))
          .onPressed,
      isNull,
    );
    await tester.tap(milk);
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(milk).value, isTrue);
    await tester.tap(milk);
    await tester.tap(egg);
    await tester.pumpAndSettle();
    await tester.tap(find.text('購入を確定する'));
    await tester.pumpAndSettle();
    expect(
      (await f.items.getItems(f.hid)).map((i) => i.id).toSet(),
      {'milk', 'fish'},
    );
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.text('1点の購入が完了しました'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'map highlights registered items while browsing and unchecked selected items while shopping',
      (tester) async {
    final f = FlowFixture();
    await f.mount(tester);
    final key = StoreMapKey(householdId: f.hid, storeId: 's');
    await f.maps.saveObject(
      key,
      const MapObject(
        id: 'empty-shelf',
        type: MapObjectType.shelf,
        x: 5,
        y: 1,
        width: 3,
        height: 1,
        categoryIds: ['snacks'],
      ),
    );
    final container =
        ProviderScope.containerOf(tester.element(find.byType(TanaGoApp)));
    GoRouter.of(tester.element(find.byType(Scaffold))).go('/stores/s/map');
    await tester.pumpAndSettle();
    Color? shelfColor(String id) => (tester
            .widget<AnimatedContainer>(
              find.byKey(ValueKey('shopping-shelf-$id')),
            )
            .decoration! as BoxDecoration)
        .color;
    final highlighted = shelfColor('shelf');
    final neutral = shelfColor('empty-shelf');
    expect(highlighted, isNot(neutral));
    final trip = container.read(shoppingTripProvider(key).notifier);
    trip.select('milk', true);
    await tester.pumpAndSettle();
    expect(shelfColor('shelf'), highlighted);
    trip.check('milk', true);
    await tester.pumpAndSettle();
    expect(shelfColor('shelf'), neutral);
    trip.check('milk', false);
    await tester.pumpAndSettle();
    expect(shelfColor('shelf'), highlighted);
    expect(find.byTooltip('拡大'), findsNothing);
    expect(find.byTooltip('縮小'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'priority persists through create and edit, and warning opens category assignment',
      (tester) async {
    final f = FlowFixture();
    await f.mount(tester);
    await tester.tap(find.text('登録'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '商品名'), '必要なもの');
    await tester
        .ensureVisible(find.widgetWithText(CheckboxListTile, 'すぐ買いたい！'));
    await tester.tap(find.widgetWithText(CheckboxListTile, 'すぐ買いたい！'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    var added =
        (await f.items.getItems(f.hid)).singleWhere((i) => i.name == '必要なもの');
    expect(added.priority, ShoppingPriority.high);
    expect(added.categoryId, isNull);
    await tester.scrollUntilVisible(
      find.text('カテゴリを設定'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('カテゴリを設定'));
    await tester.pumpAndSettle();
    expect(find.text('買いたいものを編集'), findsOneWidget);
    expect(
      tester
          .widget<CheckboxListTile>(
            find.widgetWithText(CheckboxListTile, 'すぐ買いたい！'),
          )
          .value,
      isTrue,
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('野菜・果物').last);
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.widgetWithText(CheckboxListTile, 'すぐ買いたい！'));
    await tester.tap(find.widgetWithText(CheckboxListTile, 'すぐ買いたい！'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    added =
        (await f.items.getItems(f.hid)).singleWhere((i) => i.id == added.id);
    expect(added.buySoon, isFalse);
    expect(added.categoryId, 'produce');
    expect(find.text('カテゴリを設定'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all main screens keep content clear of system and cutout insets',
      (tester) async {
    final f = FlowFixture();
    await f.mount(tester);
    const insets = FakeViewPadding(top: 44, bottom: 34, left: 20, right: 20);
    tester.view.padding = insets;
    tester.view.viewPadding = insets;
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(Scaffold)));
    for (final path in [
      '/',
      '/stores',
      '/categories',
      '/household',
      '/stores/s/select',
      '/stores/s/map',
      '/stores/s/map/edit',
      '/stores/s/complete',
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.body, isA<SafeArea>(), reason: path);
      final safe = scaffold.body! as SafeArea;
      final rect = tester.getRect(find.byWidget(safe.child));
      expect(rect.left, greaterThanOrEqualTo(20), reason: path);
      expect(rect.right, lessThanOrEqualTo(380), reason: path);
      expect(rect.top, greaterThanOrEqualTo(44), reason: path);
      expect(rect.bottom, lessThanOrEqualTo(816), reason: path);
      if (scaffold.floatingActionButton != null) {
        final fab =
            tester.getRect(find.byWidget(scaffold.floatingActionButton!));
        expect(fab.right, lessThanOrEqualTo(380), reason: path);
        expect(fab.bottom, lessThanOrEqualTo(816), reason: path);
      }
      expect(tester.takeException(), isNull, reason: path);
    }
  });

  testWidgets('shopping remains usable on a compact screen with larger text',
      (tester) async {
    final f = FlowFixture();
    await f.mount(tester);
    tester.view.physicalSize = const Size(320, 640);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('買い物に行く'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('スーパーA'));
    await tester.tap(find.text('スーパーA'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byKey(const ValueKey('select-milk')));
    await tester.tap(find.byKey(const ValueKey('select-milk')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1点を持って店内マップへ'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('map-label-shelf')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.widgetWithText(CheckboxListTile, '牛乳'));
    await tester.tap(find.widgetWithText(CheckboxListTile, '牛乳'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('チェックした1点の購入を完了する'));
    await tester.pumpAndSettle();
    expect(find.text('購入を確定する'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'missing name can be set from the registration screen without showing a UID',
      (tester) async {
    final f = FlowFixture();
    await f.mount(tester);
    await f.homes.updateMemberName(f.hid, 'local-user', 'local-user');
    await tester.pumpAndSettle();
    expect(find.textContaining('local-user'), findsNothing);
    await tester.tap(find.text('名前を設定'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '名前'), 'たろう');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('名前を設定'), findsNothing);
    expect(find.textContaining('が登録'), findsNothing);
    await tester.tap(find.byTooltip('わが家'));
    await tester.pumpAndSettle();
    expect(find.text('自分の名前を変更'), findsOneWidget);
    expect(find.text('たろう（自分）'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'browsing map shows shelf and custom category labels, including unselected shelves',
      (tester) async {
    final f = FlowFixture();
    await f.mount(tester);
    const custom = ProductCategory(id: 'custom_test', name: '健康食品・サプリメント');
    await f.categories.save(f.hid, custom);
    await f.maps.saveObject(
      StoreMapKey(householdId: f.hid, storeId: 's'),
      const MapObject(
        id: 'health',
        type: MapObjectType.shelf,
        x: 1,
        y: 3,
        width: 1,
        height: 1,
        label: '健康コーナー',
        categoryIds: ['custom_test', 'daily_goods'],
      ),
    );
    await tester.tap(find.byTooltip('店舗を管理'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('スーパーA'));
    await tester.pumpAndSettle();
    expect(find.text('売り場を確認'), findsOneWidget);
    expect(find.byKey(const ValueKey('map-categories-shelf')), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('map-categories-shelf')))
          .data,
      '乳製品・卵',
    );
    expect(find.byKey(const ValueKey('map-categories-health')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('map-label-health')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(Chip, '健康食品・サプリメント'), findsOneWidget);
    expect(find.widgetWithText(Chip, '日用品'), findsOneWidget);
    expect(find.text('今回この棚で買うものはありません。'), findsOneWidget);
    await f.categories
        .save(f.hid, const ProductCategory(id: 'custom_test', name: 'サプリ'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(Chip, 'サプリ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('legacy unnamed members use readable placeholders, never IDs', () {
    const members = [
      HouseholdMember(
        uid: 'private-id',
        displayName: 'あなた',
        role: HouseholdRole.owner,
      ),
    ];
    expect(memberName(members, 'private-id'), 'メンバー1（名前未設定）');
    expect(memberName(members, 'unknown-private-id'), '名前未設定のメンバー');
  });

  testWidgets('new store is saved before the input dialog closes',
      (tester) async {
    final f = FlowFixture();
    await f.mount(tester);
    await tester.tap(find.byTooltip('店舗を管理'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('店舗を追加'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '店舗名'), 'スーパーB');
    await tester.tap(find.text('追加'));
    await tester.pumpAndSettle();
    expect(find.text('スーパーB'), findsOneWidget);
    expect(await f.stores.getStores(f.hid), hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'store-first selection, temporary map checks and explicit completion delete only checked items',
      (tester) async {
    final f = FlowFixture();
    await f.mount(tester);
    expect(find.byType(Checkbox), findsNothing);
    expect(find.textContaining('が登録'), findsNothing);
    await tester.tap(find.text('買い物に行く'));
    await tester.pumpAndSettle();
    expect(find.text('買い物する店舗を選ぶ'), findsOneWidget);
    await tester.tap(find.text('スーパーA'));
    await tester.pumpAndSettle();
    expect(find.text('これから買うもの'), findsOneWidget);
    expect(find.text('乳製品・卵'), findsOneWidget);
    expect(find.text('鮮魚'), findsNothing);
    expect(find.text('鮭'), findsNothing);
    expect(find.text('精肉'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('select-milk')));
    await tester.tap(find.byKey(const ValueKey('select-egg')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2点を持って店内マップへ'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, '牛乳'));
    await tester.pumpAndSettle();
    expect((await f.items.getItems(f.hid)).length, 3);
    expect(
      (await f.items.getItems(f.hid)).every((i) => !i.isPurchased),
      isTrue,
    );
    await tester.tap(find.text('チェックした1点の購入を完了する'));
    await tester.pumpAndSettle();
    expect(find.text('購入内容の確認'), findsOneWidget);
    expect(
      tester
          .widget<CheckboxListTile>(find.byKey(const ValueKey('confirm-egg')))
          .value,
      isFalse,
    );
    expect((await f.items.getItems(f.hid)).length, 3);
    await tester.tap(find.text('購入を確定する'));
    await tester.pumpAndSettle();
    expect(find.text('購入完了'), findsOneWidget);
    expect(
      (await f.items.getItems(f.hid)).map((i) => i.id).toSet(),
      {'egg', 'fish'},
    );
    await tester.tap(find.text('登録一覧に戻る'));
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsNothing);
    expect(find.text('牛乳'), findsNothing);
    expect(find.text('卵'), findsOneWidget);
    expect(find.text('鮭'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'create category inside shared item dialog, edit and clear category, then change own name',
      (tester) async {
    final f = FlowFixture();
    await f.mount(tester);
    await tester.tap(find.text('登録'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '商品名'), 'プロテイン');
    await tester.tap(find.text('カテゴリを作成'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'カテゴリ名'), '健康食品');
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();
    expect(find.text('健康食品'), findsOneWidget);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    var added =
        (await f.items.getItems(f.hid)).singleWhere((i) => i.name == 'プロテイン');
    final customId = added.categoryId;
    expect(customId, startsWith('custom_'));
    expect(find.text('健康食品'), findsOneWidget);
    expect(find.textContaining('が登録'), findsNothing);
    await tester.tap(find.byTooltip('店舗を管理'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('店内マップを編集'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('map-object-shelf')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilterChip, '健康食品'));
    await tester.tap(find.widgetWithText(FilterChip, '健康食品'));
    await tester.pumpAndSettle();
    expect(
      (await f.maps.getObjects(StoreMapKey(householdId: f.hid, storeId: 's')))
          .single
          .categoryIds,
      contains(customId),
    );
    await tester.ensureVisible(find.text('完了'));
    await tester.tap(find.text('完了'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('プロテイン'));
    await tester.pumpAndSettle();
    expect(find.text('買いたいものを編集'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, '商品名'),
      'プロテイン大袋',
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('未分類').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    added =
        (await f.items.getItems(f.hid)).singleWhere((i) => i.id == added.id);
    expect(added.name, 'プロテイン大袋');
    expect(added.categoryId, isNull);
    expect(added.addedByUid, 'local-user');
    expect(
      (await f.categories.watchCategories(f.hid).first).single.id,
      customId,
    );
    await tester.tap(find.byTooltip('わが家'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('名前を変更'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '名前'), 'ゆうた');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('ゆうた（自分）'), findsOneWidget);
    expect(find.text('あき'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('カテゴリを設定'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'completion failure keeps items and checked choices available for retry',
      (tester) async {
    final f = FlowFixture(repository: FailingCompletionRepository());
    await f.mount(tester);
    await tester.tap(find.text('買い物に行く'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('スーパーA'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('select-milk')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1点を持って店内マップへ'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, '牛乳'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('チェックした1点の購入を完了する'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CheckboxListTile>(
            find.widgetWithText(CheckboxListTile, '牛乳'),
          )
          .value,
      isTrue,
    );
    await tester.tap(find.text('チェックした1点の購入を完了する'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('購入を確定する'));
    await tester.pumpAndSettle();
    expect(find.textContaining('購入の確定に失敗しました'), findsOneWidget);
    expect(await f.items.getItems(f.hid), hasLength(3));
    await tester.tap(find.text('購入を確定する'));
    await tester.pumpAndSettle();
    expect(find.text('購入完了'), findsOneWidget);
    expect(await f.items.getItems(f.hid), hasLength(2));
    expect(tester.takeException(), isNull);
  });

  test(
      'custom category is offered only in stores whose shelves reference it, and trips stay isolated',
      () async {
    final items = InMemoryShoppingListRepository();
    final maps = InMemoryMapRepository();
    const a = StoreMapKey(householdId: 'h', storeId: 'a');
    const b = StoreMapKey(householdId: 'h', storeId: 'b');
    await items.addItem(
      'h',
      ShoppingItem(
        id: 'i',
        name: 'サプリ',
        categoryId: 'custom_test',
        addedByUid: 'u',
        createdAt: DateTime(2026),
      ),
    );
    await maps.saveObject(
      a,
      const MapObject(
        id: 's',
        type: MapObjectType.shelf,
        x: 0,
        y: 0,
        width: 1,
        height: 1,
        categoryIds: ['custom_test'],
      ),
    );
    final container = ProviderContainer(
      overrides: [
        shoppingListRepositoryProvider.overrideWithValue(items),
        mapRepositoryProvider.overrideWithValue(maps),
      ],
    );
    addTearDown(container.dispose);
    final subA = container.listen(storeShoppingItemsProvider(a), (_, __) {});
    final subB = container.listen(storeShoppingItemsProvider(b), (_, __) {});
    addTearDown(subA.close);
    addTearDown(subB.close);
    await container.read(shoppingListProvider('h').future);
    await container.read(mapEditorProvider(a).future);
    await container.read(mapEditorProvider(b).future);
    expect(
      container.read(storeShoppingItemsProvider(a)).requireValue.single.id,
      'i',
    );
    expect(container.read(storeShoppingItemsProvider(b)).requireValue, isEmpty);
    final trip = container.read(shoppingTripProvider(a).notifier);
    trip.check('i', true);
    expect(container.read(shoppingTripProvider(a)).checked, isEmpty);
    trip.select('i', true);
    trip.check('i', true);
    expect(container.read(shoppingTripProvider(a)).checked, {'i'});
    expect(container.read(shoppingTripProvider(b)).selected, isEmpty);
    trip.select('i', false);
    expect(container.read(shoppingTripProvider(a)).checked, isEmpty);
  });
}
