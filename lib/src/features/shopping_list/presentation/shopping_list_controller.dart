import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../household/presentation/household_controller.dart';
import '../domain/shopping_item.dart';

final shoppingListProvider =
    NotifierProvider<ShoppingListController, List<ShoppingItem>>(
  ShoppingListController.new,
);

class ShoppingListController extends Notifier<List<ShoppingItem>> {
  static const _uuid = Uuid();

  @override
  List<ShoppingItem> build() => const [];

  void add(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }

    state = [
      ...state,
      ShoppingItem(
        id: _uuid.v4(),
        name: trimmed,
        addedByUid: localUserId,
        createdAt: DateTime.now(),
      ),
    ];
  }

  void togglePurchased(String id) {
    state = [
      for (final item in state)
        if (item.id == id)
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
                )
        else
          item,
    ];
  }

  void remove(String id) {
    state = state.where((item) => item.id != id).toList();
  }
}
