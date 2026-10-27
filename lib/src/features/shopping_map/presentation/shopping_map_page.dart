import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shopping_trip/presentation/shopping_trip_controller.dart';
import '../../product_categories/domain/product_category.dart';
import '../../product_categories/presentation/category_controller.dart';
import '../../map_editor/presentation/map_object_content.dart';

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
  final _viewport = MapViewportController();
  final _sheet = DraggableScrollableController();
  int _focusRequest = 0;
  ScrollController? _productScroll;

  void _selectShelf(String? id) {
    setState(() => _selectedShelfId = id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (_productScroll?.hasClients ?? false)) {
        _productScroll!.jumpTo(0);
      }
    });
  }

  @override
  void dispose() {
    _viewport.dispose();
    _sheet.dispose();
    super.dispose();
  }

  Future<void> _resizeSheet(double size) async {
    if (_sheet.isAttached) {
      await _sheet.animateTo(
        size,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _locate(ShoppingItem item, List<MapObject> objects) async {
    final shelf = objects
        .where(
          (o) =>
              o.type == MapObjectType.shelf &&
              o.categoryIds.contains(item.categoryId),
        )
        .firstOrNull;
    if (shelf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('この商品の売り場はまだ登録されていません。チェックは一覧からできます。')),
      );
      return;
    }
    final request = ++_focusRequest;
    _selectShelf(shelf.id);
    await _resizeSheet(0.32);
    if (!mounted || request != _focusRequest) return;
    _viewport.focus(
      Rect.fromLTWH(
        shelf.x * MapViewport.cellSize,
        shelf.y * MapViewport.cellSize,
        shelf.width * MapViewport.cellSize,
        shelf.height * MapViewport.cellSize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(householdProvider).valueOrNull!;
    final mapKey = StoreMapKey(
      householdId: household.id,
      storeId: widget.storeId,
    );
    final categoriesAsync = ref.watch(categoriesProvider(household.id));
    final categories = categoriesAsync.valueOrNull ?? <ProductCategory>[];
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
      shoppingItems: shoppingItems.isEmpty
          ? shoppingItemsAsync.valueOrNull ?? const <ShoppingItem>[]
          : pendingItems,
    );

    final selectedShelf =
        objects.where((object) => object.id == _selectedShelfId).firstOrNull;

    final browsing = shoppingItems.isEmpty;
    final displayedItems = browsing
        ? shoppingItemsAsync.valueOrNull ?? const <ShoppingItem>[]
        : shoppingItems;
    final selectedItems = selectedShelf == null
        ? displayedItems
        : itemsForShelf(
            shelf: selectedShelf,
            shoppingItems: displayedItems,
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(store?.name ?? '店内マップ'),
        actions: [
          TextButton(
            onPressed: () => context.push('/stores/${widget.storeId}/select'),
            child: Text(shoppingItems.isEmpty ? '買うものを選ぶ' : '商品を選び直す'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        shoppingItems.isEmpty
                            ? '売り場を確認'
                            : '残り${pendingItems.length}点',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      _SummaryChip(
                        icon: Icons.shopping_basket_outlined,
                        label: browsing
                            ? '登録 ${displayedItems.length}点'
                            : 'チェック ${shoppingItems.length - pendingItems.length}/${shoppingItems.length}',
                      ),
                      _SummaryChip(
                        icon: Icons.view_agenda_outlined,
                        label: '${highlightedShelfIds.length}か所',
                      ),
                    ],
                  ),
                  if (shoppingItems.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: (shoppingItems.length - pendingItems.length) /
                            shoppingItems.length,
                        backgroundColor: const Color(0xFFE3EBDC),
                        semanticsLabel: '購入チェックの進捗',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                shoppingItems.isEmpty
                    ? '濃い緑の棚に買いたいものがあります / 商品名で売り場へ'
                    : '濃い緑の棚に未チェックの商品があります / 商品名で売り場へ',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (categoriesAsync.hasError)
              TextButton(
                onPressed: () =>
                    ref.invalidate(categoriesProvider(household.id)),
                child: const Text('カテゴリ名を再読み込み'),
              ),
            if (shoppingItemsAsync.hasError) const Text('買うものを読み込めませんでした'),
            if (shoppingItemsAsync.isLoading) const LinearProgressIndicator(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    AnimatedBuilder(
                      animation: _sheet,
                      builder: (context, child) => Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: constraints.maxHeight *
                            (_sheet.isAttached ? _sheet.size : 0.5),
                        child: child!,
                      ),
                      child: objectsAsync.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : objectsAsync.hasError
                              ? Center(
                                  child: TextButton(
                                    onPressed: () => ref.invalidate(
                                      mapEditorProvider(mapKey),
                                    ),
                                    child: const Text('マップを再読み込み'),
                                  ),
                                )
                              : objects.isEmpty
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
                                          controller: _viewport,
                                          columns: store.mapWidth,
                                          rows: store.mapHeight,
                                          builder: (_, __) => Stack(
                                            children: [
                                              const Positioned.fill(
                                                child: RepaintBoundary(
                                                  child: CustomPaint(
                                                    painter:
                                                        _StoreFloorPainter(),
                                                  ),
                                                ),
                                              ),
                                              for (final object in objects)
                                                Positioned(
                                                  left: object.x *
                                                      MapViewport.cellSize,
                                                  top: object.y *
                                                      MapViewport.cellSize,
                                                  width: object.width *
                                                      MapViewport.cellSize,
                                                  height: object.height *
                                                      MapViewport.cellSize,
                                                  child: _ShoppingMapObject(
                                                    object: object,
                                                    categories: categories,
                                                    isRequired:
                                                        highlightedShelfIds
                                                            .contains(
                                                      object.id,
                                                    ),
                                                    isSelected:
                                                        _selectedShelfId ==
                                                            object.id,
                                                    onTap: object.type ==
                                                            MapObjectType.shelf
                                                        ? () {
                                                            _focusRequest++;
                                                            setState(
                                                              () =>
                                                                  _selectedShelfId =
                                                                      object.id,
                                                            );
                                                            _resizeSheet(
                                                              0.62,
                                                            );
                                                          }
                                                        : null,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                    ),
                    DraggableScrollableSheet(
                      controller: _sheet,
                      initialChildSize: 0.5,
                      minChildSize: 0.22,
                      maxChildSize: 0.88,
                      snap: true,
                      snapSizes: const [0.32, 0.5, 0.88],
                      builder: (context, scrollController) => _ShelfItemsPanel(
                        scrollController: scrollController,
                        shelf: selectedShelf,
                        browsing: browsing,
                        categories: categories,
                        items: selectedItems,
                        checked: trip.checked,
                        mappedCategories: objects
                            .where((o) => o.type == MapObjectType.shelf)
                            .expand((o) => o.categoryIds)
                            .toSet(),
                        onClearShelf: () =>
                            setState(() => _selectedShelfId = null),
                        onLocate: (item) => _locate(item, objects),
                        onExpand: () => _resizeSheet(0.88),
                        onCollapse: () => _resizeSheet(0.22),
                        onTogglePurchased: (id) => ref
                            .read(shoppingTripProvider(mapKey).notifier)
                            .check(id, !trip.checked.contains(id)),
                      ),
                    ),
                  ],
                ),
              ),
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
                    '購入内容を確認（${shoppingItems.where((i) => trip.checked.contains(i.id)).length}点）',
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
        color: const Color(0xFFE7EFE3),
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
    required this.categories,
    required this.isRequired,
    required this.isSelected,
    required this.onTap,
  });

  final MapObject object;
  final List<ProductCategory> categories;
  final bool isRequired;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final baseColor = switch (object.type) {
      MapObjectType.shelf => const Color(0xFFEAE6DA),
      MapObjectType.wall => scheme.outlineVariant,
      MapObjectType.entrance => scheme.tertiaryContainer,
      MapObjectType.exit => scheme.tertiaryContainer,
      MapObjectType.register => scheme.secondaryContainer,
    };

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        key: ValueKey('shopping-shelf-${object.id}'),
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isRequired ? scheme.primary : baseColor,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFCE8900)
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
        child: DefaultTextStyle.merge(
          style: TextStyle(color: isRequired ? Colors.white : scheme.onSurface),
          child: MapObjectContent(object: object, categories: categories),
        ),
      ),
    );
  }
}

class _ShelfItemsPanel extends StatelessWidget {
  const _ShelfItemsPanel({
    required this.scrollController,
    required this.shelf,
    required this.browsing,
    required this.categories,
    required this.items,
    required this.checked,
    required this.mappedCategories,
    required this.onTogglePurchased,
    required this.onClearShelf,
    required this.onLocate,
    required this.onExpand,
    required this.onCollapse,
  });
  final ScrollController scrollController;
  final MapObject? shelf;
  final bool browsing;
  final List<ProductCategory> categories;
  final List<ShoppingItem> items;
  final Set<String> checked;
  final Set<String> mappedCategories;
  final ValueChanged<String> onTogglePurchased;
  final ValueChanged<ShoppingItem> onLocate;
  final VoidCallback onClearShelf;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final title = shelf == null
        ? (browsing ? '買いたいもの' : '今回買うもの')
        : shelf!.label?.isNotEmpty == true
            ? '${shelf!.label}で買うもの'
            : 'この棚の売り場';
    final known =
        items.where((i) => mappedCategories.contains(i.categoryId)).toList();
    final unknown =
        items.where((i) => !mappedCategories.contains(i.categoryId)).toList();
    return Material(
      color: Colors.white,
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ListView(
        key: const ValueKey('shopping-product-sheet'),
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5C8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (shelf != null)
                IconButton(
                  tooltip: 'すべての商品を表示',
                  onPressed: onClearShelf,
                  icon: const Icon(Icons.close),
                ),
              IconButton(
                tooltip: 'リストを広げる',
                onPressed: onExpand,
                icon: const Icon(Icons.keyboard_arrow_up),
              ),
              IconButton(
                tooltip: 'マップを広げる',
                onPressed: onCollapse,
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
            ],
          ),
          if (shelf != null) ...[
            Wrap(
              spacing: 6,
              children: [
                for (final name in shelfCategoryNames(shelf!, categories))
                  Chip(label: Text(name), visualDensity: VisualDensity.compact),
                if (shelf!.categoryIds.isEmpty) const Text('カテゴリ未設定'),
              ],
            ),
          ],
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                shelf == null ? '「買うものを選ぶ」から今回の商品を選べます。' : '今回この棚で買うものはありません。',
              ),
            ),
          for (final item in known) _row(context, item, true),
          if (unknown.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 12, 8, 4),
              child: Text(
                '場所未登録',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '売り場がわからなくても、ここからチェックできます。',
                style: TextStyle(fontSize: 12),
              ),
            ),
            for (final item in unknown) _row(context, item, false),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, ShoppingItem item, bool located) =>
      Container(
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          color: checked.contains(item.id)
              ? const Color(0xFFEEF3EA)
              : item.buySoon
                  ? const Color(0xFFFFE4D8)
                  : const Color(0xFFF6F6F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                key: ValueKey('map-locate-${item.id}'),
                borderRadius: BorderRadius.circular(12),
                onTap: () => onLocate(item),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 64),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            decoration: checked.contains(item.id)
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (item.shoppingDetails.isNotEmpty)
                          Text(item.shoppingDetails),
                        if (located)
                          const Text(
                            'タップで売り場へ',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF426A52),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!browsing)
              Semantics(
                label: '${item.name}の購入チェック',
                child: SizedBox(
                  width: 56,
                  height: 64,
                  child: Checkbox(
                    key: ValueKey('map-check-${item.id}'),
                    value: checked.contains(item.id),
                    onChanged: (_) => onTogglePurchased(item.id),
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                  ),
                ),
              ),
          ],
        ),
      );
}

class _EmptyMap extends StatelessWidget {
  const _EmptyMap();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'この店舗にはまだ店内マップがありません。\n下の一覧で購入チェックできます。',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _StoreFloorPainter extends CustomPainter {
  const _StoreFloorPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF1F2EB),
    );
    final grid = Paint()
      ..color = const Color(0xFFD9DFD5)
      ..strokeWidth = 0.7;
    for (double x = 0; x <= size.width; x += MapViewport.cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y <= size.height; y += MapViewport.cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  @override
  bool shouldRepaint(covariant _StoreFloorPainter oldDelegate) => false;
}
