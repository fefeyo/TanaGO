import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/category_repository.dart';
import '../domain/product_category.dart';

class FirestoreCategoryRepository implements CategoryRepository {
  FirestoreCategoryRepository(this.firestore);
  final FirebaseFirestore firestore;

  DocumentReference<Map<String, dynamic>> _catalog(String householdId) =>
      firestore.doc('households/$householdId/categoryCatalog/active');

  @override
  Stream<List<ProductCategory>> watchCategories(String householdId) =>
      _catalog(householdId).snapshots().map((snapshot) {
        final names =
            Map<String, dynamic>.from(snapshot.data()?['names'] ?? {});
        return names.entries
            .map((e) => ProductCategory(id: e.key, name: e.value as String))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
      });

  @override
  Future<void> save(String householdId, ProductCategory category) async {
    if (category.name.trim().isEmpty || category.name.length > 50) {
      throw ArgumentError('カテゴリ名は1〜50文字で入力してください');
    }
    final reference = _catalog(householdId);
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final names = Map<String, dynamic>.from(snapshot.data()?['names'] ?? {});
      if (names.entries.any(
        (e) => e.key != category.id && e.value == category.name.trim(),
      )) {
        throw StateError('同じ名前のカテゴリがあります');
      }
      names[category.id] = category.name.trim();
      transaction.set(reference, {'names': names, 'lastEditedId': category.id});
    });
  }
}
