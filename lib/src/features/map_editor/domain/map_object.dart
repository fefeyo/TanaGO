enum MapObjectType {
  shelf,
  wall,
  entrance,
  exit,
  register,
}

class MapObject {
  const MapObject({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.label,
    this.categoryIds = const [],
  });

  final String id;
  final MapObjectType type;
  final int x;
  final int y;
  final int width;
  final int height;
  final String? label;
  final List<String> categoryIds;

  bool get isWalkable =>
      type == MapObjectType.entrance ||
      type == MapObjectType.exit ||
      type == MapObjectType.register;
}
