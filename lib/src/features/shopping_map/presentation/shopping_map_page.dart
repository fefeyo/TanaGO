import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shopping_trip/presentation/shopping_trip_controller.dart';

import '../../map_editor/domain/map_object.dart';
import '../../map_editor/presentation/map_viewport.dart';
import '../../stores/presentation/store_controller.dart';
import '../../map_editor/domain/store_map_key.dart';
import '../../map_editor/presentation/map_editor_controller.dart';
import '../../household/presentation/household_controller.dart';
import '../../shopping_list/domain/shopping_item.dart';
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
  String? _selectedShelfId;

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(householdProvider).valueOrNull!;
    final mapKey = StoreMapKey(
      householdId: household.id,
      storeId: widget.storeId,
    );
    final storesAsync = ref.watch(storesProvider(household.id));
    final store = storesAsync.valueOrNull
        ?.where((store) => store.id == widget.storeId)
        .firstOrNull;
    final objectsAsync = ref.watch(mapEditorProvider(mapKey));
    final shoppingItemsAsync = ref.watch(storeShoppingItemsProvider(mapKey));
    final trip = ref.watch(shoppingTripProvider(mapKey));
    final objects = objectsAsync.valueOrNull ?? const <MapObject>[];
    final shoppingItems =
        (shoppingItemsAsync.valueOrNull ?? const <ShoppingItem>[])
            .where((item) => trip.selected.contains(item.id))
            .toList();
    final pendingItems =
        shoppingItems.where((item) => !trip.checked.contains(item.id)).toList();

    final highlightedShelfIds = requiredShelfIds(
      objects: objects,
      shoppingItems: pendingItems,
    );

    final selectedShelf =
        objects.where((object) => object.id == _selectedShelfId).firstOrNull;

    final selectedItems = selectedShelf == null
        ? shoppingItems
        : itemsForShelf(
            shelf: selectedShelf,
            shoppingItems: shoppingItems,
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('店内マップ'),
        actions: [
          TextButton(
            onPressed: () => context.push('/stores/${widget.storeId}/select'),
            child: const Text('商品を選び直す'),
          ),
        ],
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
                      '残り${pendingItems.length}点',
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
            if (shoppingItemsAsync.hasError) const Text('買うものを読み込めませんでした'),
            if (shoppingItemsAsync.isLoading) const LinearProgressIndicator(),
            Expanded(
              child: objects.isEmpty
                  ? const _EmptyMap()
                  : store == null
                      ? Center(
                          child: Text(
                            storesAsync.isLoading
                                ? '店舗を読み込み中…'
                                : '店舗を読み込めませんでした',
                          ),
                        )
                      : MapViewport(
                          columns: store.mapWidth,
                          rows: store.mapHeight,
                          builder: (_) => Stack(
                            children: [
                              Positioned.fill(
                                child: ColoredBox(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerLowest,
                                ),
                              ),
                              for (final object in objects)
                                Positioned(
                                  left: object.x * MapViewport.cellSize,
                                  top: object.y * MapViewport.cellSize,
                                  width: object.width * MapViewport.cellSize,
                                  height: object.height * MapViewport.cellSize,
                                  child: _ShoppingMapObject(
                                    object: object,
                                    isRequired:
                                        highlightedShelfIds.contains(object.id),
                                    isSelected: _selectedShelfId == object.id,
                                    onTap: object.type == MapObjectType.shelf
                                        ? () => setState(
                                              () =>
                                                  _selectedShelfId = object.id,
                                            )
                                        : null,
                                  ),
                                ),
                            ],
                          ),
                        ),
            ),
            _ShelfItemsPanel(
              shelf: selectedShelf,
              items: selectedItems,
              checked: trip.checked,
              onClearShelf: () => setState(() => _selectedShelfId = null),
              onTogglePurchased: (id) => ref
                  .read(shoppingTripProvider(mapKey).notifier)
                  .check(id, !trip.checked.contains(id)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: shoppingItems
                          .any((i) => trip.checked.contains(i.id))
                      ? () => context.push('/stores/${widget.storeId}/complete')
                      : null,
                  child: Text(
                    'チェックした${shoppingItems.where((i) => trip.checked.contains(i.id)).length}点の購入を完了する',
                  ),
                ),
              ),
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
    required this.onTogglePurchased,
    required this.checked,
    required this.onClearShelf,
  });

  final MapObject? shelf;
  final List<ShoppingItem> items;
  final ValueChanged<String> onTogglePurchased;
  final Set<String> checked;
  final VoidCallback onClearShelf;

  @override
  Widget build(BuildContext context) {
    final title = shelf == null
        ? '今回買うもの'
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
          if (shelf != null)
            TextButton(onPressed: onClearShelf, child: const Text('すべての商品を表示')),
          if (items.isEmpty)
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
                    value: checked.contains(item.id),
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
