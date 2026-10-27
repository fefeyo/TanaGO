import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanago/src/features/shopping_list/data/firestore_shopping_list_repository.dart';
import 'package:tanago/src/features/shopping_list/data/in_memory_shopping_list_repository.dart';
import 'package:tanago/src/features/shopping_list/domain/shopping_item.dart';
import 'package:tanago/src/features/shopping_list/domain/shopping_list_repository.dart';

void main() {
  for (final firestore in [false, true]) {
    test(
        'archive, idempotent retry, restore and stale undo (${firestore ? 'Firestore' : 'memory'})',
        () async {
      final ShoppingListRepository repo = firestore
          ? FirestoreShoppingListRepository(FakeFirebaseFirestore())
          : InMemoryShoppingListRepository();
      for (var i = 0; i < 18; i++) {
        await repo.addItem(
          'home',
          ShoppingItem(
            id: '$i',
            name: '商品$i',
            addedByUid: 'family',
            createdAt: DateTime(2026),
            quantity: '2本',
            memo: '青いパッケージ',
            priority: ShoppingPriority.high,
          ),
        );
      }
      final ids = {for (var i = 0; i < 17; i++) '$i'};
      final records = await repo.purchaseItems(
        'home',
        ids,
        purchaseId: 'first',
        purchasedByUid: 'me',
      );
      expect(records, hasLength(17));
      expect((await repo.getItems('home')).single.id, '17');
      expect(await repo.watchRecentPurchases('home').first, hasLength(17));
      expect(await repo.watchRecentPurchases('other').first, isEmpty);
      final retried = await repo.purchaseItems(
        'home',
        ids,
        purchaseId: 'first',
        purchasedByUid: 'me',
      );
      expect(retried, hasLength(17));
      expect(
        await repo.purchaseItems(
          'home',
          ids,
          purchaseId: 'other',
          purchasedByUid: 'me',
        ),
        isEmpty,
      );
      await repo.undoPurchase('home', records);
      await repo.undoPurchase('home', records);
      final restored = await repo.getItems('home');
      expect(restored, hasLength(18));
      expect(
        restored.every(
          (i) =>
              i.addedByUid == 'family' &&
              !i.isPurchased &&
              i.purchasedAt == null &&
              i.purchasedByUid == null,
        ),
        isTrue,
      );
      expect(
        restored.every(
          (i) => i.quantity == '2本' && i.memo == '青いパッケージ' && i.buySoon,
        ),
        isTrue,
      );
      expect(await repo.watchRecentPurchases('home').first, isEmpty);
      await repo.purchaseItems(
        'home',
        ids,
        purchaseId: 'second',
        purchasedByUid: 'me',
      );
      await repo.undoPurchase('home', records);
      expect(await repo.getItems('home'), hasLength(1));
      expect(
        (await repo.watchRecentPurchases('home').first)
            .every((r) => r.purchaseId == 'second'),
        isTrue,
      );
    });
  }

  test(
      'legacy documents remain compatible and undo never overwrites a new edit',
      () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreShoppingListRepository(db);
    final doc = db.doc('households/h/shoppingLists/active/items/i');
    await doc.set({
      'name': '牛乳',
      'addedByUid': 'family',
      'createdAt': Timestamp.fromDate(DateTime(2026)),
      'categoryId': 'dairy',
      'isPurchased': false,
      'purchasedByUid': null,
      'purchasedAt': null,
    });
    expect((await repo.getItems('h')).single.details, isEmpty);
    final records = await repo.purchaseItems(
      'h',
      {'i'},
      purchaseId: 'p',
      purchasedByUid: 'me',
    );
    final archive = await db.doc('households/h/purchaseHistory/i').get();
    expect(archive.data()!.containsKey('quantity'), isFalse);
    await repo.undoPurchase('h', records);
    expect((await doc.get()).data()!.containsKey('quantity'), isFalse);
    final second = await repo.purchaseItems(
      'h',
      {'i'},
      purchaseId: 'p2',
      purchasedByUid: 'me',
    );
    await doc.set({
      'name': '家族が変更',
      'addedByUid': 'family',
      'createdAt': Timestamp.fromDate(DateTime(2026)),
      'categoryId': 'dairy',
      'isPurchased': false,
      'purchasedByUid': null,
      'purchasedAt': null,
    });
    await repo.undoPurchase('h', second);
    expect((await repo.getItems('h')).single.name, '家族が変更');
  });
}
