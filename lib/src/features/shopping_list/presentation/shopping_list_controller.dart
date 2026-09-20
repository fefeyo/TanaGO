import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../household/presentation/household_controller.dart';
import '../../product_categories/domain/product_category_classifier.dart';
import '../data/in_memory_shopping_list_repository.dart';
import '../domain/shopping_item.dart';
import '../domain/shopping_list_repository.dart';

final shoppingListRepositoryProvider = Provider<ShoppingListRepository>(
  (ref) => InMemoryShoppingListRepository(),
);

final shoppingListProvider =
    StreamProvider.family<List<ShoppingItem>, String>(
  (ref, householdId) => ref
      .watch(shoppingListRepositoryProvider)
      .watchItems(householdId),
);

final shoppingListControllerProvider =
    Provider.family<ShoppingListController, String>(
  (ref, householdId) => ShoppingListController(
    repository: ref.watch(shoppingListRepositoryProvider),
    householdId: householdId,
  ),
);

class ShoppingListController {
  ShoppingListController({
    required ShoppingListRepository repository,
    required String householdId,
  })  : _repository = repository,
        _householdId = householdId;

  static const _uuid = Uuid();
  static const _categoryClassifier = ProductCategoryClassifier();

  final ShoppingListRepository _repository;
  final String _householdId;

  Future<void> add(String name, {String? categoryId}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }

    await _repository.addItem(
      _householdId,
      ShoppingItem(
        id: _uuid.v4(),
        name: trimmed,
        addedByUid: localUserId,
        createdAt: DateTime.now(),
        categoryId: categoryId ?? _categoryClassifier.classify(trimmed),
      ),
    );
  }

  Future<void> updateCategory(String id, String categoryId) async {
    final item = await _findItem(id);
    if (item == null) {
      return;
    }
    await _repository.updateItem(
      _householdId,
      item.copyWith(categoryId: categoryId),
    );
  }

  Future<void> togglePurchased(String id) async {
    final item = await _findItem(id);
    if (item == null) {
      return;
    }

    await _repository.updateItem(
      _householdId,
      item.isPurchased
          ? item.copyWith(
              isPurchased: false,
              clearPurchasedByUid: true,
              clearPurchasedAt: true,
            )
          : item.copyWith(
              isPurchased: true,
              purchasedByUid: localUserId,
              purchasedAt: DateTime.now(),
            ),
    );
  }

  Future<void> remove(String id) {
    return _repository.removeItem(_householdId, id);
  }

  Future<ShoppingItem?> _findItem(String id) async {
    final items = await _repository.getItems(_householdId);
    for (final item in items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }
}
