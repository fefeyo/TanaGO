import 'dart:async';
import '../domain/category_repository.dart';
import '../domain/product_category.dart';

class InMemoryCategoryRepository implements CategoryRepository {
  final _categories = <String, Map<String, ProductCategory>>{};
  final _streams = <String, StreamController<List<ProductCategory>>>{};
  StreamController<List<ProductCategory>> _stream(String id) =>
      _streams.putIfAbsent(
        id,
        () => StreamController<List<ProductCategory>>.broadcast(),
      );
  @override
  Stream<List<ProductCategory>> watchCategories(String householdId) async* {
    yield _categories[householdId]?.values.toList() ?? [];
    yield* _stream(householdId).stream;
  }

  @override
  Future<void> save(String householdId, ProductCategory category) async {
    if (category.name.trim().isEmpty || category.name.length > 50) {
      throw ArgumentError('カテゴリ名は1〜50文字で入力してください');
    }
    final categories = _categories.putIfAbsent(householdId, () => {});
    if (categories.values
        .any((c) => c.id != category.id && c.name == category.name.trim())) {
      throw StateError('同じ名前のカテゴリがあります');
    }
    categories[category.id] =
        ProductCategory(id: category.id, name: category.name.trim());
    _stream(householdId).add(categories.values.toList());
  }
}
