import 'product_category.dart';

abstract interface class CategoryRepository {
  Stream<List<ProductCategory>> watchCategories(String householdId);
  Future<void> save(String householdId, ProductCategory category);
}
