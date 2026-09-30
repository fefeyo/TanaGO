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
