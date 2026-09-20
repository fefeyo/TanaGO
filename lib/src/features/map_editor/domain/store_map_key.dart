class StoreMapKey {
  const StoreMapKey({
    required this.householdId,
    required this.storeId,
  });

  final String householdId;
  final String storeId;

  @override
  bool operator ==(Object other) {
    return other is StoreMapKey &&
        other.householdId == householdId &&
        other.storeId == storeId;
  }

  @override
  int get hashCode => Object.hash(householdId, storeId);
}
