import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/shopping_item.dart';
import '../domain/shopping_list_repository.dart';

class FirestoreShoppingListRepository implements ShoppingListRepository {
  FirestoreShoppingListRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _items(String householdId) {
    return _firestore
        .collection('households')
        .doc(householdId)
        .collection('shoppingLists')
        .doc('active')
        .collection('items');
  }

  @override
  Stream<List<ShoppingItem>> watchItems(String householdId) {
    return _items(householdId)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDocument).toList());
  }

  @override
  Future<List<ShoppingItem>> getItems(String householdId) async {
    final snapshot = await _items(householdId).orderBy('createdAt').get();
    return snapshot.docs.map(_fromDocument).toList();
  }

  @override
  Future<void> addItem(String householdId, ShoppingItem item) {
    return _items(householdId).doc(item.id).set(_toMap(item));
  }

  @override
  Future<void> updateItem(
    String householdId,
    String itemId,
    ShoppingItem Function(ShoppingItem current) update,
  ) {
    final reference = _items(householdId).doc(itemId);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) return;
      final current = _fromDocument(snapshot);
      transaction.update(reference, _toMap(update(current)));
    });
  }

  CollectionReference<Map<String, dynamic>> _history(String householdId) =>
      _firestore
          .collection('households')
          .doc(householdId)
          .collection('purchaseHistory');

  @override
  Stream<List<PurchaseRecord>> watchRecentPurchases(String householdId) =>
      _history(householdId)
          .orderBy('purchasedAt', descending: true)
          .limit(60)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (doc) => PurchaseRecord(
                    item: _fromDocument(doc),
                    purchaseId: doc.data()['purchaseId'] as String,
                  ),
                )
                .toList(),
          );

  @override
  Future<List<PurchaseRecord>> purchaseItems(
    String householdId,
    Set<String> itemIds, {
    required String purchaseId,
    required String purchasedByUid,
  }) async {
    final records = <PurchaseRecord>[];
    final ids = itemIds.toList();
    // Small transactions stay within the rules' document-access budget.
    // Reusing purchaseId makes retries after a partially completed run safe.
    for (var offset = 0; offset < ids.length; offset += 8) {
      final chunk = ids.skip(offset).take(8).toList();
      records.addAll(
        await _firestore.runTransaction((transaction) async {
          final active = <DocumentSnapshot<Map<String, dynamic>>>[];
          final history = <DocumentSnapshot<Map<String, dynamic>>>[];
          for (final id in chunk) {
            active.add(await transaction.get(_items(householdId).doc(id)));
            history.add(await transaction.get(_history(householdId).doc(id)));
          }
          final result = <PurchaseRecord>[];
          for (var i = 0; i < chunk.length; i++) {
            if (!active[i].exists) {
              if (history[i].data()?['purchaseId'] == purchaseId) {
                result.add(
                  PurchaseRecord(
                    item: _fromDocument(history[i]),
                    purchaseId: purchaseId,
                  ),
                );
              }
              continue;
            }
            if (history[i].exists) {
              throw StateError(
                'An existing purchase must be restored before repurchase.',
              );
            }
            final item = _fromDocument(active[i]).copyWith(
              isPurchased: true,
              purchasedByUid: purchasedByUid,
              purchasedAt: DateTime.now(),
            );
            // Preserve missing optional fields in older documents exactly.
            transaction.set(_history(householdId).doc(chunk[i]), {
              ...active[i].data()!,
              'purchaseId': purchaseId,
              'isPurchased': true,
              'purchasedByUid': purchasedByUid,
              'purchasedAt': FieldValue.serverTimestamp(),
            });
            transaction.delete(active[i].reference);
            result.add(PurchaseRecord(item: item, purchaseId: purchaseId));
          }
          return result;
        }),
      );
    }
    return records;
  }

  @override
  Future<void> undoPurchase(
    String householdId,
    List<PurchaseRecord> records,
  ) async {
    for (var offset = 0; offset < records.length; offset += 8) {
      final chunk = records.skip(offset).take(8).toList();
      await _firestore.runTransaction((transaction) async {
        final history = <DocumentSnapshot<Map<String, dynamic>>>[];
        final active = <DocumentSnapshot<Map<String, dynamic>>>[];
        for (final record in chunk) {
          history.add(
            await transaction.get(_history(householdId).doc(record.item.id)),
          );
          active.add(
            await transaction.get(_items(householdId).doc(record.item.id)),
          );
        }
        for (var i = 0; i < chunk.length; i++) {
          final data = history[i].data();
          if (data == null || data['purchaseId'] != chunk[i].purchaseId) {
            continue;
          }
          // Never overwrite a product that another family member has edited.
          if (!active[i].exists) {
            final restored = Map<String, dynamic>.from(data)
              ..remove('purchaseId');
            restored.addAll({
              'isPurchased': false,
              'purchasedByUid': null,
              'purchasedAt': null,
            });
            transaction.set(active[i].reference, restored);
          }
          transaction.delete(history[i].reference);
        }
      });
    }
  }

  @override
  Future<void> removeItems(String householdId, Set<String> itemIds) async {
    final ids = itemIds.toList();
    for (var offset = 0; offset < ids.length; offset += 400) {
      final batch = _firestore.batch();
      for (final id in ids.skip(offset).take(400)) {
        batch.delete(_items(householdId).doc(id));
      }
      await batch.commit();
    }
  }

  @override
  Future<void> removeItem(String householdId, String itemId) {
    return _items(householdId).doc(itemId).delete();
  }

  ShoppingItem _fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data()!;
    return ShoppingItem(
      id: document.id,
      name: data['name'] as String? ?? '',
      addedByUid: data['addedByUid'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      categoryId: data['categoryId'] as String?,
      quantity: data['quantity'] as String? ?? '',
      memo: data['memo'] as String? ?? '',
      priority: ShoppingPriority.fromValue(data['priority']),
      isPurchased: data['isPurchased'] as bool? ?? false,
      purchasedByUid: data['purchasedByUid'] as String?,
      purchasedAt: (data['purchasedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> _toMap(ShoppingItem item) {
    return {
      'name': item.name,
      'quantity': item.quantity,
      'memo': item.memo,
      'addedByUid': item.addedByUid,
      'createdAt': Timestamp.fromDate(item.createdAt),
      'categoryId': item.categoryId,
      'priority': item.priority.name,
      'isPurchased': item.isPurchased,
      'purchasedByUid': item.purchasedByUid,
      'purchasedAt': item.purchasedAt == null
          ? null
          : Timestamp.fromDate(item.purchasedAt!),
    };
  }
}
