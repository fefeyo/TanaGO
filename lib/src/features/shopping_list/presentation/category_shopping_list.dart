import 'package:flutter/material.dart';
import '../../household/domain/household.dart';
import '../../product_categories/domain/product_category.dart';
import '../domain/shopping_item.dart';

/// Category order follows the shared category catalog; unknown categories are
/// grouped with unassigned items. Within each group, urgent items come first.
class CategoryShoppingList extends StatelessWidget {
  const CategoryShoppingList({
    super.key,
    required this.items,
    required this.categories,
    required this.members,
    required this.onEdit,
    required this.onDelete,
  });
  final List<ShoppingItem> items;
  final List<ProductCategory> categories;
  final List<HouseholdMember> members;
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
        final priority = a.priority.index.compareTo(b.priority.index);
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
                      member: memberName(members, item.addedByUid),
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
    required this.member,
    required this.unclassified,
    required this.onEdit,
    required this.onDelete,
  });
  final ShoppingItem item;
  final String member;
  final bool unclassified;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Material(
        color: unclassified ? const Color(0xFFFFF5DF) : Colors.white,
        child: InkWell(
          onTap: onEdit,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE6EAE3))),
            ),
            padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          if (item.priority != ShoppingPriority.normal) ...[
                            const SizedBox(width: 6),
                            Semantics(
                              label: '優先度：${item.priority.label}',
                              child: Text(
                                '優先度 ${item.priority.label}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: item.priority == ShoppingPriority.high
                                      ? const Color(0xFFA44132)
                                      : const Color(0xFF61716B),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (unclassified)
                        const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: Color(0xFF8A5800),
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'カテゴリを設定',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8A5800),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: Color(0xFF8A5800),
                            ),
                          ],
                        )
                      else
                        Text(
                          '$memberが登録',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
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
