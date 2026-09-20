class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.name,
    required this.addedByUid,
    required this.createdAt,
    this.categoryId,
    this.isPurchased = false,
    this.purchasedByUid,
    this.purchasedAt,
  });

  final String id;
  final String name;
  final String addedByUid;
  final DateTime createdAt;
  final String? categoryId;
  final bool isPurchased;
  final String? purchasedByUid;
  final DateTime? purchasedAt;

  ShoppingItem copyWith({
    String? name,
    String? categoryId,
    bool? isPurchased,
    String? purchasedByUid,
    DateTime? purchasedAt,
    bool clearPurchasedByUid = false,
    bool clearPurchasedAt = false,
  }) {
    return ShoppingItem(
      id: id,
      name: name ?? this.name,
      addedByUid: addedByUid,
      createdAt: createdAt,
      categoryId: categoryId ?? this.categoryId,
      isPurchased: isPurchased ?? this.isPurchased,
      purchasedByUid: clearPurchasedByUid
          ? null
          : purchasedByUid ?? this.purchasedByUid,
      purchasedAt:
          clearPurchasedAt ? null : purchasedAt ?? this.purchasedAt,
    );
  }
}
