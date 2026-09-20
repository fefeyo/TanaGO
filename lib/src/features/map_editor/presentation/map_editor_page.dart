import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/map_object.dart';
import 'map_editor_controller.dart';

class MapEditorPage extends ConsumerStatefulWidget {
  const MapEditorPage({
    required this.storeId,
    super.key,
  });

  final String storeId;

  @override
  ConsumerState<MapEditorPage> createState() => _MapEditorPageState();
}

class _MapEditorPageState extends ConsumerState<MapEditorPage> {
  static const _columns = 12;
  static const _rows = 16;

  MapObjectType _selectedType = MapObjectType.shelf;

  @override
  Widget build(BuildContext context) {
    final objects = ref.watch(mapEditorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('店内マップを作る'),
        actions: [
          IconButton(
            tooltip: 'すべて削除',
            onPressed: objects.isEmpty
                ? null
                : ref.read(mapEditorProvider.notifier).clear,
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
                final cellSize = constraints.maxWidth / _columns;
                final mapHeight = cellSize * _rows;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: constraints.maxWidth,
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

                              ref.read(mapEditorProvider.notifier).add(
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
                            child: _MapObjectTile(
                              object: object,
                              onDelete: () => ref
                                  .read(mapEditorProvider.notifier)
                                  .remove(object.id),
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
            child: Text('グリッドをタップして配置 / オブジェクトを長押しして削除'),
          ),
        ],
      ),
    );
  }
}

class _ObjectPalette extends StatelessWidget {
  const _ObjectPalette({
    required this.selectedType,
    required this.onSelected,
  });

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

class _MapObjectTile extends StatelessWidget {
  const _MapObjectTile({
    required this.object,
    required this.onDelete,
  });

  final MapObject object;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = switch (object.type) {
      MapObjectType.shelf => Theme.of(context).colorScheme.primaryContainer,
      MapObjectType.wall =>
        Theme.of(context).colorScheme.surfaceContainerHighest,
      MapObjectType.entrance =>
        Theme.of(context).colorScheme.tertiaryContainer,
      MapObjectType.exit => Theme.of(context).colorScheme.tertiaryContainer,
      MapObjectType.register =>
        Theme.of(context).colorScheme.secondaryContainer,
    };

    return InkWell(
      onLongPress: onDelete,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(4),
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
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({
    required this.columns,
    required this.rows,
  });

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
