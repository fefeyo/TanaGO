import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../map_editor/domain/map_object.dart';
import '../../map_editor/presentation/map_editor_controller.dart';
import '../../household/presentation/household_controller.dart';
import '../../shopping_list/domain/shopping_item.dart';
import '../../shopping_list/presentation/shopping_list_controller.dart';
import '../domain/shopping_map_matcher.dart';

class ShoppingMapPage extends ConsumerStatefulWidget {
  const ShoppingMapPage({
    required this.storeId,
    super.key,
  });

  final String storeId;

  @override
  ConsumerState<ShoppingMapPage> createState() => _ShoppingMapPageState();
}

class _ShoppingMapPageState extends ConsumerState<ShoppingMapPage> {
  static const _columns = 12;
  static const _rows = 16;

  String? _selectedShelfId;

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(householdProvider);
    final objects = ref.watch(mapEditorProvider(widget.storeId));
    final shoppingItems = ref.watch(shoppingListProvider(household.id));
    final pendingItems = shoppingItems
        .where((item) => !item.isPurchased && item.categoryId != null)
        .toList();

    final highlightedShelfIds = requiredShelfIds(
      objects: objects,
      shoppingItems: shoppingItems,
    );

    final selectedShelf = objects
        .where((object) => object.id == _selectedShelfId)
        .firstOrNull;

    final selectedItems = selectedShelf == null
        ? const <ShoppingItem>[]
        : itemsForShelf(
            shelf: selectedShelf,
            shoppingItems: shoppingItems,
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('店内マップ'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '買うものがある棚を確認',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  _SummaryChip(
                    icon: Icons.shopping_basket_outlined,
                    label: '${pendingItems.length}点',
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    icon: Icons.view_agenda_outlined,
                    label: '${highlightedShelfIds.length}か所',
                  ),
                ],
              ),
            ),
            Expanded(
              child: objects.isEmpty
                  ? const _EmptyMap()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final mapWidth = constraints.maxWidth - 32;
                        final cellSize = mapWidth / _columns;
                        final mapHeight = cellSize * _rows;

                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            width: mapWidth,
                            height: mapHeight,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outlineVariant,
                                      ),
                                    ),
                                  ),
                                ),
                                for (final object in objects)
                                  Positioned(
                                    left: object.x * cellSize,
                                    top: object.y * cellSize,
                                    width: object.width * cellSize,
                                    height: object.height * cellSize,
                                    child: _ShoppingMapObject(
                                      object: object,
                                      isRequired:
                                          highlightedShelfIds.contains(object.id),
                                      isSelected:
                                          _selectedShelfId == object.id,
                                      onTap: object.type == MapObjectType.shelf
                                          ? () => setState(
                                                () => _selectedShelfId =
                                                    object.id,
                                              )
                                          : null,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            _ShelfItemsPanel(
              shelf: selectedShelf,
              items: selectedItems,
              hasRequiredShelves: highlightedShelfIds.isNotEmpty,
              onTogglePurchased: (id) => ref
                  .read(shoppingListProvider(household.id).notifier)
                  .togglePurchased(id),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
    );
  }
}

class _ShoppingMapObject extends StatelessWidget {
  const _ShoppingMapObject({
    required this.object,
    required this.isRequired,
    required this.isSelected,
    required this.onTap,
  });

  final MapObject object;
  final bool isRequired;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final baseColor = switch (object.type) {
      MapObjectType.shelf => scheme.surfaceContainerHigh,
      MapObjectType.wall => scheme.outlineVariant,
      MapObjectType.entrance => scheme.tertiaryContainer,
      MapObjectType.exit => scheme.tertiaryContainer,
      MapObjectType.register => scheme.secondaryContainer,
    };

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isRequired ? scheme.primaryContainer : baseColor,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isSelected
                ? scheme.primary
                : isRequired
                    ? scheme.primary.withValues(alpha: 0.65)
                    : scheme.outlineVariant,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isRequired
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(
                      alpha: isSelected ? 0.34 : 0.18,
                    ),
                    blurRadius: isSelected ? 14 : 8,
                    spreadRadius: isSelected ? 3 : 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            switch (object.type) {
              MapObjectType.shelf => Icons.view_agenda_outlined,
              MapObjectType.wall => Icons.horizontal_rule,
              MapObjectType.entrance => Icons.login,
              MapObjectType.exit => Icons.logout,
              MapObjectType.register => Icons.point_of_sale,
            },
            size: 17,
            color: isRequired ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ShelfItemsPanel extends StatelessWidget {
  const _ShelfItemsPanel({
    required this.shelf,
    required this.items,
    required this.hasRequiredShelves,
    required this.onTogglePurchased,
  });

  final MapObject? shelf;
  final List<ShoppingItem> items;
  final bool hasRequiredShelves;
  final ValueChanged<String> onTogglePurchased;

  @override
  Widget build(BuildContext context) {
    final title = shelf == null
        ? 'このお店で買うもの'
        : shelf!.label?.isNotEmpty == true
            ? '${shelf!.label}で買うもの'
            : 'この棚で買うもの';

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 230),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (shelf != null)
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (shelf == null)
            Text(
              hasRequiredShelves
                  ? '光っている棚をタップすると、ここに商品が表示されます。'
                  : '売り場が設定された未購入の商品はありません。',
            )
          else if (items.isEmpty)
            const Text('この棚で買うものはありません。')
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: item.isPurchased,
                    title: Text(item.name),
                    onChanged: (_) => onTogglePurchased(item.id),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyMap extends StatelessWidget {
  const _EmptyMap();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'この店舗にはまだ店内マップがありません。\n先にマップを作成してください。',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
