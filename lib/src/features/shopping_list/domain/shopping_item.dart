class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.name,
    this.categoryId,
    this.isPurchased = false,
  });

  final String id;
  final String name;
  final String? categoryId;
  final bool isPurchased;

  ShoppingItem copyWith({
    String? name,
    String? categoryId,
    bool? isPurchased,
  }) {
    return ShoppingItem(
      id: id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }
}
