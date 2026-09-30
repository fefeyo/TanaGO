import 'package:flutter/material.dart';
import '../../product_categories/domain/product_category.dart';
import '../domain/shopping_item.dart';

/// Category order follows the shared category catalog; unknown categories are
/// grouped with unassigned items. Within each group, urgent items come first.
class CategoryShoppingList extends StatelessWidget {
  const CategoryShoppingList({
    super.key,
    required this.items,
    required this.categories,
    required this.onEdit,
    required this.onDelete,
  });
  final List<ShoppingItem> items;
  final List<ProductCategory> categories;
  final ValueChanged<ShoppingItem> onEdit;
  final ValueChanged<ShoppingItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final known = categories.map((c) => c.id).toSet();
    final groups = <String?, List<ShoppingItem>>{};
    for (final item in items) {
      final id = known.contains(item.categoryId) ? item.categoryId : null;
      (groups[id] ??= []).add(item);
    }
    final order = [
      for (final category in categories)
        if (groups.containsKey(category.id)) category.id,
      if (groups.containsKey(null)) null,
    ];
    for (final group in groups.values) {
      group.sort((a, b) {
        final priority = (a.buySoon ? 0 : 1).compareTo(b.buySoon ? 0 : 1);
        if (priority != 0) return priority;
        final created = a.createdAt.compareTo(b.createdAt);
        return created != 0 ? created : a.id.compareTo(b.id);
      });
    }
    return CustomScrollView(
      key: const ValueKey('category-shopping-list'),
      slivers: [
        for (final id in order)
          SliverMainAxisGroup(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _CategoryHeader(
                  id: id,
                  name: id == null
                      ? '未分類'
                      : categories.firstWhere((c) => c.id == id).name,
                  count: groups[id]!.length,
                  textScaler: MediaQuery.textScalerOf(context),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                sliver: SliverList.builder(
                  itemCount: groups[id]!.length,
                  itemBuilder: (context, index) {
                    final item = groups[id]![index];
                    return _CompactItem(
                      key: ValueKey(item.id),
                      item: item,
                      unclassified: id == null,
                      onEdit: () => onEdit(item),
                      onDelete: () => onDelete(item),
                    );
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _CategoryHeader extends SliverPersistentHeaderDelegate {
  const _CategoryHeader({
    required this.id,
    required this.name,
    required this.count,
    required this.textScaler,
  });
  final String? id;
  final String name;
  final int count;
  final TextScaler textScaler;
  @override
  double get minExtent => 24 + textScaler.scale(18);
  @override
  double get maxExtent => minExtent;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      Semantics(
        header: true,
        child: Container(
          key: ValueKey('category-header-${id ?? 'unclassified'}'),
          height: maxExtent,
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              if (id == null) ...[
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFF8A5800),
                  size: 20,
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Tooltip(
                  message: name,
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('$count点', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
  @override
  bool shouldRebuild(covariant _CategoryHeader oldDelegate) =>
      id != oldDelegate.id ||
      name != oldDelegate.name ||
      count != oldDelegate.count ||
      textScaler != oldDelegate.textScaler;
}

class _CompactItem extends StatelessWidget {
  const _CompactItem({
    super.key,
    required this.item,
    required this.unclassified,
    required this.onEdit,
    required this.onDelete,
  });
  final ShoppingItem item;
  final bool unclassified;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Material(
        color: item.buySoon
            ? const Color(0xFFFFE4D8)
            : unclassified
                ? const Color(0xFFFFF5DF)
                : Colors.white,
        child: InkWell(
          onTap: onEdit,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: item.buySoon
                      ? const Color(0xFFB24B32)
                      : Colors.transparent,
                  width: 3,
                ),
                bottom: const BorderSide(color: Color(0xFFE6EAE3)),
              ),
            ),
            padding: const EdgeInsets.only(left: 9, top: 4, bottom: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (item.buySoon)
                        const Text(
                          'すぐ買いたい！',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9B3C28),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (unclassified)
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            'カテゴリを設定',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8A5800),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '${item.name}を削除',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20),
                ),
              ],
            ),
          ),
        ),
      );
}
