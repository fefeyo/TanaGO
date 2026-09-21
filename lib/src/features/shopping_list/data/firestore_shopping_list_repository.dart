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
      isPurchased: data['isPurchased'] as bool? ?? false,
      purchasedByUid: data['purchasedByUid'] as String?,
      purchasedAt: (data['purchasedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> _toMap(ShoppingItem item) {
    return {
      'name': item.name,
      'addedByUid': item.addedByUid,
      'createdAt': Timestamp.fromDate(item.createdAt),
      'categoryId': item.categoryId,
      'isPurchased': item.isPurchased,
      'purchasedByUid': item.purchasedByUid,
      'purchasedAt': item.purchasedAt == null
          ? null
          : Timestamp.fromDate(item.purchasedAt!),
    };
  }
}
