class Store {
  const Store({
    required this.id,
    required this.householdId,
    required this.name,
    required this.mapWidth,
    required this.mapHeight,
  });

  final String id;
  final String householdId;
  final String name;
  final int mapWidth;
  final int mapHeight;
}
