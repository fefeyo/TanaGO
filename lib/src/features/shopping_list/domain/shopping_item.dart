enum ShoppingPriority {
  high('高'),
  normal('通常'),
  low('低');

  const ShoppingPriority(this.label);
  final String label;
  static ShoppingPriority fromValue(Object? value) =>
      values.where((p) => p.name == value).firstOrNull ?? normal;
}

class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.name,
    required this.addedByUid,
    required this.createdAt,
    this.categoryId,
    this.quantity = '',
    this.memo = '',
    this.priority = ShoppingPriority.normal,
    this.isPurchased = false,
    this.purchasedByUid,
    this.purchasedAt,
  });

  final String id;
  final String name;
  final String addedByUid;
  final DateTime createdAt;
  final String? categoryId;
  final String quantity;
  final String memo;
  String get details => [quantity, memo].where((s) => s.isNotEmpty).join(' · ');
  String get shoppingDetails => [if (buySoon) 'すぐ買いたい！', quantity, memo]
      .where((s) => s.isNotEmpty)
      .join(' · ');
  // Keep the stored priority compatible with previously distributed clients.
  // Only the old high value maps to the current "buy soon" toggle.
  final ShoppingPriority priority;
  bool get buySoon => priority == ShoppingPriority.high;
  final bool isPurchased;
  final String? purchasedByUid;
  final DateTime? purchasedAt;

  ShoppingItem copyWith({
    String? name,
    String? categoryId,
    String? quantity,
    String? memo,
    ShoppingPriority? priority,
    bool? isPurchased,
    String? purchasedByUid,
    DateTime? purchasedAt,
    bool clearCategory = false,
    bool clearPurchasedByUid = false,
    bool clearPurchasedAt = false,
  }) {
    return ShoppingItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      memo: memo ?? this.memo,
      addedByUid: addedByUid,
      createdAt: createdAt,
      priority: priority ?? this.priority,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      isPurchased: isPurchased ?? this.isPurchased,
      purchasedByUid:
          clearPurchasedByUid ? null : purchasedByUid ?? this.purchasedByUid,
      purchasedAt: clearPurchasedAt ? null : purchasedAt ?? this.purchasedAt,
    );
  }
}

/// A completed item and the operation that archived it. The operation identity
/// prevents a stale undo from consuming a newer purchase of the same item.
class PurchaseRecord {
  const PurchaseRecord({required this.item, required this.purchaseId});
  final ShoppingItem item;
  final String purchaseId;
}
