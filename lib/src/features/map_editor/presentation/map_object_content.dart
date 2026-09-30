import 'package:flutter/material.dart';
import '../../product_categories/domain/product_category.dart';
import '../domain/map_object.dart';

List<String> shelfCategoryNames(
  MapObject object,
  List<ProductCategory> categories,
) =>
    [
      for (final id in object.categoryIds)
        categories.where((c) => c.id == id).firstOrNull?.name ?? 'カテゴリ読み込み中',
    ];

/// Shared labels for editing and shopping. Full category names remain available
/// in the tooltip and selected-shelf panel when a tile is too small to fit them.
class MapObjectContent extends StatelessWidget {
  const MapObjectContent({
    super.key,
    required this.object,
    required this.categories,
  });
  final MapObject object;
  final List<ProductCategory> categories;

  @override
  Widget build(BuildContext context) {
    final names = shelfCategoryNames(object, categories);
    final typeName = switch (object.type) {
      MapObjectType.shelf => '棚',
      MapObjectType.wall => '壁',
      MapObjectType.entrance => '入口',
      MapObjectType.exit => '出口',
      MapObjectType.register => 'レジ',
    };
    final label = object.label?.trim();
    final title = label != null && label.isNotEmpty
        ? label
        : names.isEmpty
            ? typeName
            : names.join('・');
    final subtitle = label != null && label.isNotEmpty && names.isNotEmpty
        ? names.join('・')
        : null;
    final full = [title, if (subtitle != null) subtitle].join('\n');
    return Tooltip(
      message: full,
      child: Semantics(
        label: full,
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 55;
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        // Diagram labels scale with the map zoom. Full text in
                        // the shelf panel follows the system text size.
                        textScaler: TextScaler.noScaling,
                        key: ValueKey('map-label-${object.id}'),
                        maxLines:
                            subtitle == null && constraints.maxHeight >= 28
                                ? 2
                                : 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: compact ? 10 : 11,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null && constraints.maxHeight >= 26)
                        Text(
                          subtitle,
                          textScaler: TextScaler.noScaling,
                          key: ValueKey('map-categories-${object.id}'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10, height: 1.1),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
