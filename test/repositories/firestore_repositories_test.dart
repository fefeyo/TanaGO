import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanago/src/features/household/data/firestore_household_repository.dart';
import 'package:tanago/src/features/map_editor/data/firestore_map_repository.dart';
import 'package:tanago/src/features/map_editor/domain/map_object.dart';
import 'package:tanago/src/features/map_editor/domain/store_map_key.dart';
import 'package:tanago/src/features/shopping_list/data/firestore_shopping_list_repository.dart';
import 'package:tanago/src/features/shopping_list/domain/shopping_item.dart';
import 'package:tanago/src/features/stores/data/firestore_store_repository.dart';
import 'package:tanago/src/features/stores/domain/store.dart';

void main() {
  test('Firestore create and join preserve owner and reject another household',
      () async {
    final db = FakeFirebaseFirestore();
    final repository = FirestoreHouseholdRepository(db);
    final home = await repository.createHousehold(
      name: '家',
      ownerUid: 'owner',
      ownerDisplayName: 'A',
    );
    final code = await repository.getInviteCode(home.id);
    expect(
      (await db.collection('householdInvites').doc(code).get())
          .data()?['householdId'],
      home.id,
    );
    await repository.joinHousehold(
      inviteCode: code.toLowerCase(),
      uid: 'owner',
      displayName: 'A',
    );
    expect(
      (await repository.watchMembers(home.id).first).single.role.name,
      'owner',
    );
    await repository.joinHousehold(
      inviteCode: ' $code ',
      uid: 'guest',
      displayName: 'B',
    );
    expect(
      (await repository.watchCurrentHousehold('guest').first)?.id,
      home.id,
    );
    expect(await repository.watchMembers(home.id).first, hasLength(2));
    await expectLater(
      repository.createHousehold(
        name: 'other',
        ownerUid: 'owner',
        ownerDisplayName: 'A',
      ),
      throwsStateError,
    );
    final other = await repository.createHousehold(
      name: 'other',
      ownerUid: 'other',
      ownerDisplayName: 'C',
    );
    final otherCode = await repository.getInviteCode(other.id);
    await expectLater(
      repository.joinHousehold(
        inviteCode: otherCode,
        uid: 'guest',
        displayName: 'B',
      ),
      throwsStateError,
    );
    await expectLater(
      repository.joinHousehold(
        inviteCode: 'TANA-1234',
        uid: 'new',
        displayName: 'C',
      ),
      throwsStateError,
    );
  });

  test(
      'household stream follows live document changes and stops old subscriptions',
      () async {
    final db = FakeFirebaseFirestore();
    final repository = FirestoreHouseholdRepository(db);
    final a = await repository.createHousehold(
      name: 'A',
      ownerUid: 'a',
      ownerDisplayName: 'A',
    );
    final b = await repository.createHousehold(
      name: 'B',
      ownerUid: 'b',
      ownerDisplayName: 'B',
    );
    final names = <String?>[];
    final subscription = repository
        .watchCurrentHousehold('a')
        .listen((home) => names.add(home?.name));
    await Future<void>.delayed(Duration.zero);
    expect(names.last, 'A');
    await db.collection('households').doc(a.id).update({'name': 'A2'});
    await Future<void>.delayed(Duration.zero);
    expect(names.last, 'A2');
    // Admin-side membership repair: exercise switching streams, not client permission.
    await db.collection('users').doc('a').update({'householdId': b.id});
    await Future<void>.delayed(Duration.zero);
    expect(names.last, 'B');
    await db.collection('households').doc(a.id).update({'name': 'old'});
    await Future<void>.delayed(Duration.zero);
    expect(names.last, 'B');
    await db
        .collection('users')
        .doc('a')
        .update({'householdId': FieldValue.delete()});
    await Future<void>.delayed(Duration.zero);
    expect(names.last, isNull);
    await subscription.cancel();
  });

  test('Firestore edits read latest data and never recreate removed records',
      () async {
    final db = FakeFirebaseFirestore();
    final shopping = FirestoreShoppingListRepository(db);
    await shopping.addItem(
      'h',
      ShoppingItem(
        id: 'i',
        name: '牛乳',
        addedByUid: 'u',
        createdAt: DateTime(2026),
        categoryId: 'dairy',
      ),
    );
    await shopping.updateItem(
      'h',
      'i',
      (item) => item.copyWith(
        isPurchased: true,
        purchasedByUid: 'u',
        purchasedAt: DateTime(2026),
      ),
    );
    await shopping.updateItem(
      'h',
      'i',
      (item) => item.copyWith(categoryId: 'beverages'),
    );
    expect((await shopping.getItems('h')).single.isPurchased, true);
    await shopping.removeItem('h', 'i');
    await shopping.updateItem(
      'h',
      'i',
      (item) => item.copyWith(categoryId: 'dairy'),
    );
    expect(await shopping.getItems('h'), isEmpty);
    final maps = FirestoreMapRepository(db);
    const key = StoreMapKey(householdId: 'h', storeId: 's');
    await maps.saveObject(
      key,
      const MapObject(
        id: 'o',
        type: MapObjectType.shelf,
        x: 0,
        y: 0,
        width: 3,
        height: 1,
      ),
    );
    await maps.updateObject(key, 'o', (object) => object.copyWith(label: '牛乳'));
    await maps.updateObject(key, 'o', (object) => object.copyWith(x: 3));
    expect((await maps.getObjects(key)).single.label, '牛乳');
    await maps.removeObject(key, 'o');
    await maps.updateObject(key, 'o', (object) => object.copyWith(x: 4));
    expect(await maps.getObjects(key), isEmpty);
  });

  test('clear and store deletion handle more than one batch and are retryable',
      () async {
    final db = FakeFirebaseFirestore();
    final stores = FirestoreStoreRepository(db);
    final maps = FirestoreMapRepository(db);
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
    for (var i = 0; i < 501; i++) {
      await maps.saveObject(
        key,
        MapObject(
          id: '$i',
          type: MapObjectType.shelf,
          x: 0,
          y: 0,
          width: 3,
          height: 1,
        ),
      );
    }
    await maps.clear(key);
    expect(await maps.getObjects(key), isEmpty);
    for (var i = 0; i < 501; i++) {
      await maps.saveObject(
        key,
        MapObject(
          id: '$i',
          type: MapObjectType.shelf,
          x: 0,
          y: 0,
          width: 3,
          height: 1,
        ),
      );
    }
    await stores.removeStore('h', 's');
    expect(await stores.getStores('h'), isEmpty);
    expect(await maps.getObjects(key), isEmpty);
    await stores.removeStore('h', 's');
  });
}
