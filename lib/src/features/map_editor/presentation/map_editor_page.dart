import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../household/presentation/household_controller.dart';
import '../../stores/domain/store.dart';
import '../../stores/presentation/store_controller.dart';
import 'draggable_map_object.dart';
import 'map_viewport.dart';

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
  bool _navigate = false;

  MapObjectType _selectedType = MapObjectType.shelf;
  String? _selectedObjectId;

  StoreMapKey get _mapKey => StoreMapKey(
        householdId: ref.read(householdProvider).valueOrNull!.id,
        storeId: widget.storeId,
      );

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(householdProvider).valueOrNull;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final mapKey = StoreMapKey(
      householdId: household.id,
      storeId: widget.storeId,
    );
    final storesAsync = ref.watch(storesProvider(household.id));
    final objectsAsync = ref.watch(mapEditorProvider(mapKey));
    final store = storesAsync.valueOrNull
        ?.where((store) => store.id == widget.storeId)
        .firstOrNull;
    if (store == null || !objectsAsync.hasValue) {
      final failed = storesAsync.hasError || objectsAsync.hasError;
      final missing = storesAsync.hasValue && store == null;
      return Scaffold(
        appBar: AppBar(title: const Text('店内マップを作る')),
        body: Center(
          child: failed || missing
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(missing ? '店舗が見つかりません' : 'マップを読み込めませんでした'),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(storesProvider(household.id));
                        ref.invalidate(mapEditorProvider(mapKey));
                      },
                      child: const Text('再読み込み'),
                    ),
                  ],
                )
              : const CircularProgressIndicator(),
        ),
      );
    }
    final controller = ref.read(mapEditorControllerProvider(mapKey));
    final objects = objectsAsync.valueOrNull ?? const <MapObject>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('店内マップを作る'),
        actions: [
          IconButton(
            tooltip: 'マス目を増やす',
            onPressed: () => _expandMap(store),
            icon: const Icon(Icons.aspect_ratio),
          ),
          IconButton(
            tooltip: 'すべて削除',
            onPressed: objects.isEmpty
                ? null
                : () {
                    _save(controller.clear());
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text('${store.mapWidth} × ${store.mapHeight} マス'),
                const Spacer(),
                FilterChip(
                  label: const Text('移動・拡大'),
                  avatar: const Icon(Icons.pan_tool_outlined, size: 18),
                  selected: _navigate,
                  onSelected: (value) => setState(() => _navigate = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: MapViewport(
              columns: store.mapWidth,
              rows: store.mapHeight,
              navigationEnabled: _navigate,
              builder: (transform) => Stack(
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: GestureDetector(
                        key: const ValueKey('map-grid'),
                        behavior: HitTestBehavior.opaque,
                        onTapUp: _navigate
                            ? null
                            : (details) => _save(
                                  controller.add(
                                    type: _selectedType,
                                    x: (details.localPosition.dx /
                                            MapViewport.cellSize)
                                        .floor(),
                                    y: (details.localPosition.dy /
                                            MapViewport.cellSize)
                                        .floor(),
                                    mapWidth: store.mapWidth,
                                    mapHeight: store.mapHeight,
                                  ),
                                ),
                        child: CustomPaint(
                          painter: _GridPainter(
                            columns: store.mapWidth,
                            rows: store.mapHeight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  for (final object in objects)
                    DraggableMapObject(
                      key: ValueKey(object.id),
                      object: object,
                      columns: store.mapWidth,
                      rows: store.mapHeight,
                      transform: transform,
                      enabled: !_navigate,
                      onMove: (x, y) async {
                        final saved = await controller.move(
                          id: object.id,
                          x: x,
                          y: y,
                          mapWidth: store.mapWidth,
                          mapHeight: store.mapHeight,
                        );
                        return saved == null
                            ? null
                            : Offset(saved.x.toDouble(), saved.y.toDouble());
                      },
                      onError: () =>
                          _showSaveError('移動を保存できませんでした。通信を確認して、もう一度移動してください。'),
                      onTap: () => _selectObject(object),
                      onLongPress: () => _confirmDelete(object),
                      child: _MapObjectTile(
                        object: object,
                        isSelected: object.id == _selectedObjectId,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              _navigate ? 'スワイプで画面移動 / ピンチで拡大・縮小' : '空きマスをタップで配置 / 棚をドラッグで移動',
            ),
          ),
        ],
      ),
    );
  }

  void _showSaveError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save(Future<void> action) async {
    try {
      await action;
    } catch (_) {
      _showSaveError('保存できませんでした。通信を確認して、もう一度お試しください。');
    }
  }

  Future<void> _expandMap(Store store) async {
    final width = TextEditingController(text: '${store.mapWidth}');
    final height = TextEditingController(text: '${store.mapHeight}');
    final form = GlobalKey<FormState>();
    final repository = ref.read(storeRepositoryProvider);
    var saving = false;
    String? error;
    final route = DialogRoute<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('マス目を増やす'),
          content: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('店舗の広さに合わせて、最大 100 × 100 マスまで広げられます。'),
                  const SizedBox(height: 16),
                  for (final entry in [
                    (width, store.mapWidth, '横'),
                    (height, store.mapHeight, '縦'),
                  ])
                    TextFormField(
                      controller: entry.$1,
                      enabled: !saving,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '${entry.$3}のマス数（${entry.$2}〜100）',
                      ),
                      validator: (value) {
                        final number = int.tryParse(value ?? '');
                        return number == null ||
                                number < entry.$2 ||
                                number > 100
                            ? '${entry.$2}〜100 の整数を入力してください'
                            : null;
                      },
                    ),
                  if (error != null)
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!form.currentState!.validate()) return;
                      update(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        await repository.expandMap(
                          store.householdId,
                          store.id,
                          width: int.parse(width.text),
                          height: int.parse(height.text),
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      } catch (_) {
                        if (context.mounted) {
                          update(() {
                            saving = false;
                            error = '保存できませんでした。もう一度お試しください。';
                          });
                        }
                      }
                    },
              child: Text(saving ? '保存中…' : '広げる'),
            ),
          ],
        ),
      ),
    );
    await Navigator.of(context).push(route);
    await route.completed;
    width.dispose();
    height.dispose();
  }

  void _selectObject(MapObject object) {
    setState(() => _selectedObjectId = object.id);
    _showObjectEditor(object.id);
  }

  Future<void> _showObjectEditor(String objectId) async {
    final mapKey = _mapKey;
    final initialObject = ref
        .read(mapEditorProvider(mapKey))
        .valueOrNull
        ?.where((object) => object.id == objectId)
        .firstOrNull;
    if (initialObject == null) return;

    final labelController =
        TextEditingController(text: initialObject.label ?? '');

    final navigator = Navigator.of(context);
    final route = ModalBottomSheetRoute<void>(
      capturedThemes:
          InheritedTheme.capture(from: context, to: navigator.context),
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final object = ref
                .watch(mapEditorProvider(mapKey))
                .valueOrNull
                ?.where((object) => object.id == objectId)
                .firstOrNull;
            final store = ref
                .watch(storesProvider(mapKey.householdId))
                .valueOrNull
                ?.where((store) => store.id == mapKey.storeId)
                .firstOrNull;
            if (object == null || store == null) return const SizedBox.shrink();

            return SingleChildScrollView(
              child: Padding(
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
                              .read(mapEditorControllerProvider(mapKey))
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
                              selected:
                                  object.categoryIds.contains(category.id),
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
                                    .read(mapEditorControllerProvider(mapKey))
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
                        ref.read(mapEditorControllerProvider(mapKey)).resize(
                              id: object.id,
                              width: width.clamp(1, store.mapWidth - object.x),
                              height:
                                  height.clamp(1, store.mapHeight - object.y),
                              mapWidth: store.mapWidth,
                              mapHeight: store.mapHeight,
                            );
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            ref
                                .read(mapEditorControllerProvider(mapKey))
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
                                  .read(mapEditorControllerProvider(mapKey))
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
              ),
            );
          },
        );
      },
    );

    await navigator.push(route);
    await route.completed;
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

    if (shouldDelete == true && mounted) {
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
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      columns != oldDelegate.columns || rows != oldDelegate.rows;
}
