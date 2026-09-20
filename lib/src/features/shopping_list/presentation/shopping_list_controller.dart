import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

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
      ShoppingItem(id: _uuid.v4(), name: trimmed),
    ];
  }

  void togglePurchased(String id) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(isPurchased: !item.isPurchased)
        else
          item,
    ];
  }

  void remove(String id) {
    state = state.where((item) => item.id != id).toList();
  }
}
