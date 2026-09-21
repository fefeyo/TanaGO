import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../household/presentation/household_controller.dart';
import '../../product_categories/domain/product_categories.dart';
import '../domain/map_object.dart';
import '../domain/store_map_key.dart';
import 'map_editor_controller.dart';

class MapEditorPage extends ConsumerStatefulWidget {
  const MapEditorPage({required this.storeId, super.key});
  final String storeId;

  @override
  ConsumerState<MapEditorPage> createState() => _MapEditorPageState();
}

class _MapEditorPageState extends ConsumerState<MapEditorPage> {
  static const _columns = 12;
  static const _rows = 16;

  MapObjectType _selectedType = MapObjectType.shelf;
  String? _selectedObjectId;
  final Map<String, Offset> _dragOrigins = {};
  final Map<String, Offset> _dragDeltas = {};

  StoreMapKey get _mapKey => StoreMapKey(
        householdId: ref.read(householdProvider).valueOrNull!.id,
        storeId: widget.storeId,
      );

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(householdProvider).valueOrNull!;
    final mapKey = StoreMapKey(
      householdId: household.id,
      storeId: widget.storeId,
    );
    final objectsAsync = ref.watch(mapEditorProvider(mapKey));
    final objects = objectsAsync.valueOrNull ?? const <MapObject>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('店内マップを作る'),
        actions: [
          IconButton(
            tooltip: 'すべて削除',
            onPressed: objects.isEmpty
                ? null
                : () {
                    ref.read(mapEditorControllerProvider(_mapKey)).clear();
                    setState(() => _selectedObjectId = null);
                  },
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          _ObjectPalette(
            selectedType: _selectedType,
            onSelected: (type) => setState(() => _selectedType = type),
          ),
          const Divider(height: 1),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mapWidth = constraints.maxWidth - 24;
                final cellSize = mapWidth / _columns;
                final mapHeight = cellSize * _rows;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: mapWidth,
                    height: mapHeight,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (details) {
                              final width =
                                  _selectedType == MapObjectType.shelf ? 3 : 1;
                              final rawX =
                                  (details.localPosition.dx / cellSize).floor();
                              final y =
                                  (details.localPosition.dy / cellSize).floor();
                              final x = rawX.clamp(0, _columns - width);

                              ref
                                  .read(mapEditorControllerProvider(_mapKey))
                                  .add(
                                    type: _selectedType,
                                    x: x,
                                    y: y.clamp(0, _rows - 1),
                                  );
                            },
                            child: CustomPaint(
                              painter: const _GridPainter(
                                columns: _columns,
                                rows: _rows,
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
                            child: GestureDetector(
                              onTap: () => _selectObject(object),
                              onLongPress: () => _confirmDelete(object),
                              onPanStart: (_) {
                                _dragOrigins[object.id] = Offset(
                                  object.x.toDouble(),
                                  object.y.toDouble(),
                                );
                                _dragDeltas[object.id] = Offset.zero;
                                setState(() => _selectedObjectId = object.id);
                              },
                              onPanUpdate: (details) {
                                final origin = _dragOrigins[object.id];
                                if (origin == null) return;

                                final delta =
                                    (_dragDeltas[object.id] ?? Offset.zero) +
                                        details.delta;
                                _dragDeltas[object.id] = delta;

                                final x = (origin.dx + delta.dx / cellSize)
                                    .round()
                                    .clamp(0, _columns - object.width);
                                final y = (origin.dy + delta.dy / cellSize)
                                    .round()
                                    .clamp(0, _rows - object.height);

                                ref
                                    .read(mapEditorControllerProvider(_mapKey))
                                    .move(
                                      id: object.id,
                                      x: x,
                                      y: y,
                                    );
                              },
                              onPanEnd: (_) => _finishDrag(object.id),
                              onPanCancel: () => _finishDrag(object.id),
                              child: _MapObjectTile(
                                object: object,
                                isSelected: object.id == _selectedObjectId,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text('タップで配置 / ドラッグで移動 / オブジェクトをタップして編集'),
          ),
        ],
      ),
    );
  }

  void _finishDrag(String id) {
    _dragOrigins.remove(id);
    _dragDeltas.remove(id);
  }

  void _selectObject(MapObject object) {
    setState(() => _selectedObjectId = object.id);
    _showObjectEditor(object.id);
  }

  Future<void> _showObjectEditor(String objectId) async {
    final initialObject = ref
        .read(mapEditorProvider(_mapKey))
        .valueOrNull
        ?.where((object) => object.id == objectId)
        .firstOrNull;
    if (initialObject == null) return;

    final labelController =
        TextEditingController(text: initialObject.label ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final object = ref
                .watch(mapEditorProvider(_mapKey))
                .valueOrNull
                ?.where((object) => object.id == objectId)
                .firstOrNull;
            if (object == null) return const SizedBox.shrink();

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                20 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _objectTitle(object.type),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (object.type == MapObjectType.shelf) ...[
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(
                        labelText: '売り場名',
                        hintText: '例：乳製品、調味料',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (value) {
                        ref
                            .read(mapEditorControllerProvider(_mapKey))
                            .updateDetails(
                              id: object.id,
                              label: value,
                            );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'この棚にある商品カテゴリ',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final category in productCategories)
                          FilterChip(
                            label: Text(category.name),
                            selected: object.categoryIds.contains(category.id),
                            onSelected: (selected) {
                              final categoryIds = {
                                ...object.categoryIds,
                              };
                              if (selected) {
                                categoryIds.add(category.id);
                              } else {
                                categoryIds.remove(category.id);
                              }
                              ref
                                  .read(mapEditorControllerProvider(_mapKey))
                                  .updateDetails(
                                    id: object.id,
                                    categoryIds: categoryIds.toList(),
                                  );
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  _SizeEditor(
                    width: object.width,
                    height: object.height,
                    onResize: (width, height) {
                      ref.read(mapEditorControllerProvider(_mapKey)).resize(
                            id: object.id,
                            width: width.clamp(1, _columns - object.x),
                            height: height.clamp(1, _rows - object.y),
                          );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          ref
                              .read(mapEditorControllerProvider(_mapKey))
                              .remove(object.id);
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('削除'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          if (object.type == MapObjectType.shelf) {
                            ref
                                .read(mapEditorControllerProvider(_mapKey))
                                .updateDetails(
                                  id: object.id,
                                  label: labelController.text.trim(),
                                );
                          }
                          Navigator.of(context).pop();
                        },
                        child: const Text('完了'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    labelController.dispose();
  }

  Future<void> _confirmDelete(MapObject object) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除しますか？'),
        content: Text('${_objectTitle(object.type)}をマップから削除します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      ref.read(mapEditorControllerProvider(_mapKey)).remove(object.id);
      if (_selectedObjectId == object.id) {
        setState(() => _selectedObjectId = null);
      }
    }
  }

  String _objectTitle(MapObjectType type) {
    return switch (type) {
      MapObjectType.shelf => '棚を編集',
      MapObjectType.wall => '壁を編集',
      MapObjectType.entrance => '入口を編集',
      MapObjectType.exit => '出口を編集',
      MapObjectType.register => 'レジを編集',
    };
  }
}

class _ObjectPalette extends StatelessWidget {
  const _ObjectPalette({required this.selectedType, required this.onSelected});

  final MapObjectType selectedType;
  final ValueChanged<MapObjectType> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: SegmentedButton<MapObjectType>(
        segments: const [
          ButtonSegment(
            value: MapObjectType.shelf,
            icon: Icon(Icons.view_agenda_outlined),
            label: Text('棚'),
          ),
          ButtonSegment(
            value: MapObjectType.wall,
            icon: Icon(Icons.horizontal_rule),
            label: Text('壁'),
          ),
          ButtonSegment(
            value: MapObjectType.entrance,
            icon: Icon(Icons.login),
            label: Text('入口'),
          ),
          ButtonSegment(
            value: MapObjectType.register,
            icon: Icon(Icons.point_of_sale),
            label: Text('レジ'),
          ),
        ],
        selected: {selectedType},
        onSelectionChanged: (selection) => onSelected(selection.first),
      ),
    );
  }
}

class _SizeEditor extends StatelessWidget {
  const _SizeEditor({
    required this.width,
    required this.height,
    required this.onResize,
  });

  final int width;
  final int height;
  final void Function(int width, int height) onResize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('サイズ', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _Stepper(
                label: '横',
                value: width,
                onDecrement:
                    width > 1 ? () => onResize(width - 1, height) : null,
                onIncrement: () => onResize(width + 1, height),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Stepper(
                label: '縦',
                value: height,
                onDecrement:
                    height > 1 ? () => onResize(width, height - 1) : null,
                onIncrement: () => onResize(width, height + 1),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final int value;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(onPressed: onDecrement, icon: const Icon(Icons.remove)),
          Expanded(
            child: Text('$label $value', textAlign: TextAlign.center),
          ),
          IconButton(onPressed: onIncrement, icon: const Icon(Icons.add)),
        ],
      ),
    );
  }
}

class _MapObjectTile extends StatelessWidget {
  const _MapObjectTile({required this.object, required this.isSelected});

  final MapObject object;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final color = switch (object.type) {
      MapObjectType.shelf => Theme.of(context).colorScheme.primaryContainer,
      MapObjectType.wall =>
        Theme.of(context).colorScheme.surfaceContainerHighest,
      MapObjectType.entrance => Theme.of(context).colorScheme.tertiaryContainer,
      MapObjectType.exit => Theme.of(context).colorScheme.tertiaryContainer,
      MapObjectType.register =>
        Theme.of(context).colorScheme.secondaryContainer,
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
          width: isSelected ? 3 : 1,
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.22),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                switch (object.type) {
                  MapObjectType.shelf => Icons.view_agenda_outlined,
                  MapObjectType.wall => Icons.horizontal_rule,
                  MapObjectType.entrance => Icons.login,
                  MapObjectType.exit => Icons.logout,
                  MapObjectType.register => Icons.point_of_sale,
                },
                size: 18,
              ),
              if (object.label != null && object.label!.isNotEmpty) ...[
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    object.label!,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.columns, required this.rows});

  final int columns;
  final int rows;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;
    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;

    for (var column = 0; column <= columns; column++) {
      final x = column * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (var row = 0; row <= rows; row++) {
      final y = row * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}
