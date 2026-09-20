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

  MapObject copyWith({
    int? x,
    int? y,
    int? width,
    int? height,
    String? label,
    List<String>? categoryIds,
    bool clearLabel = false,
  }) {
    return MapObject(
      id: id,
      type: type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      label: clearLabel ? null : label ?? this.label,
      categoryIds: categoryIds ?? this.categoryIds,
    );
  }
}
