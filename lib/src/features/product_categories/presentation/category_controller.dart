import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/firestore_category_repository.dart';
import '../domain/category_repository.dart';
import '../domain/product_categories.dart';
import '../domain/product_category.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => FirestoreCategoryRepository(FirebaseFirestore.instance),
);
final categoriesProvider =
    StreamProvider.autoDispose.family<List<ProductCategory>, String>(
  (ref, householdId) => ref
      .watch(categoryRepositoryProvider)
      .watchCategories(householdId)
      .map((custom) => [...productCategories, ...custom]),
);

Future<ProductCategory> saveCategory(
  CategoryRepository repository,
  String householdId,
  String name, {
  String? id,
}) async {
  final trimmed = name.trim();
  if (trimmed.isEmpty || trimmed.length > 50) {
    throw ArgumentError('カテゴリ名は1〜50文字で入力してください');
  }
  if (productCategories.any((c) => c.name == trimmed)) {
    throw StateError('同じ名前のカテゴリがあります');
  }
  final category =
      ProductCategory(id: id ?? 'custom_${const Uuid().v4()}', name: trimmed);
  await repository.save(householdId, category);
  return category;
}

String categoryName(List<ProductCategory> categories, String? id) =>
    categories.where((c) => c.id == id).firstOrNull?.name ?? '未分類';
