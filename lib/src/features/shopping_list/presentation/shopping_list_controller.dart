import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../auth/domain/auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../product_categories/domain/product_category_classifier.dart';
import '../data/firestore_shopping_list_repository.dart';
import '../domain/shopping_item.dart';
import '../domain/shopping_list_repository.dart';

final shoppingListRepositoryProvider = Provider<ShoppingListRepository>(
  (ref) => FirestoreShoppingListRepository(FirebaseFirestore.instance),
);

final shoppingListProvider =
    StreamProvider.autoDispose.family<List<ShoppingItem>, String>(
  (ref, householdId) =>
      ref.watch(shoppingListRepositoryProvider).watchItems(householdId),
);

final shoppingListControllerProvider =
    Provider.family<ShoppingListController, String>(
  (ref, householdId) => ShoppingListController(
    repository: ref.watch(shoppingListRepositoryProvider),
    authRepository: ref.watch(authRepositoryProvider),
    householdId: householdId,
  ),
);

class ShoppingListController {
  ShoppingListController({
    required ShoppingListRepository repository,
    required AuthRepository authRepository,
    required String householdId,
  })  : _repository = repository,
        _authRepository = authRepository,
        _householdId = householdId;

  static const _uuid = Uuid();
  static const _categoryClassifier = ProductCategoryClassifier();

  final ShoppingListRepository _repository;
  final AuthRepository _authRepository;
  final String _householdId;

  Future<void> add(
    String name, {
    String? categoryId,
    bool autoClassify = true,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final user = _authRepository.currentUser ?? await _authRepository.signIn();

    await _repository.addItem(
      _householdId,
      ShoppingItem(
        id: _uuid.v4(),
        name: trimmed,
        addedByUid: user.uid,
        createdAt: DateTime.now(),
        categoryId: categoryId ??
            (autoClassify ? _categoryClassifier.classify(trimmed) : null),
      ),
    );
  }

  Future<void> edit(String id, {required String name, String? categoryId}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 200) {
      throw ArgumentError('商品名は1〜200文字で入力してください');
    }
    return _repository.updateItem(
      _householdId,
      id,
      (item) => item.copyWith(
        name: trimmed,
        categoryId: categoryId,
        clearCategory: categoryId == null,
      ),
    );
  }

  Future<void> complete(Iterable<String> ids) =>
      _repository.removeItems(_householdId, ids.toSet());

  Future<void> updateCategory(String id, String categoryId) {
    return _repository.updateItem(
      _householdId,
      id,
      (item) => item.copyWith(categoryId: categoryId),
    );
  }

  Future<void> togglePurchased(String id) async {
    final user = _authRepository.currentUser ?? await _authRepository.signIn();
    final purchasedAt = DateTime.now();
    await _repository.updateItem(
      _householdId,
      id,
      (item) => item.isPurchased
          ? item.copyWith(
              isPurchased: false,
              clearPurchasedByUid: true,
              clearPurchasedAt: true,
            )
          : item.copyWith(
              isPurchased: true,
              purchasedByUid: user.uid,
              purchasedAt: purchasedAt,
            ),
    );
  }

  Future<void> remove(String id) => _repository.removeItem(_householdId, id);
}
