import 'package:flutter/material.dart';

/// A fixed cell size keeps large maps usable; zoom changes the view, not data.
class MapViewport extends StatefulWidget {
  const MapViewport({
    super.key,
    required this.columns,
    required this.rows,
    required this.builder,
    this.navigationEnabled = true,
  });

  static const cellSize = 36.0;
  final int columns;
  final int rows;
  final bool navigationEnabled;
  final Widget Function(TransformationController transform) builder;

  @override
  State<MapViewport> createState() => _MapViewportState();
}

class _MapViewportState extends State<MapViewport> {
  final _transform = TransformationController();

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _zoom(double factor, Size viewport) {
    final scale = _transform.value.getMaxScaleOnAxis();
    final next = (scale * factor).clamp(0.02, 3.0);
    final center = viewport.center(Offset.zero);
    final scene = _transform.toScene(center);
    _transform.value = Matrix4.identity()
      ..translateByDouble(
        center.dx - scene.dx * next,
        center.dy - scene.dy * next,
        0,
        1,
      )
      ..scaleByDouble(next, next, next, 1);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                key: const ValueKey('map-viewport'),
                transformationController: _transform,
                constrained: false,
                alignment: Alignment.topLeft,
                minScale: 0.02,
                maxScale: 3,
                boundaryMargin: const EdgeInsets.all(80),
                panEnabled: widget.navigationEnabled,
                scaleEnabled: widget.navigationEnabled,
                child: SizedBox(
                  width: widget.columns * MapViewport.cellSize,
                  height: widget.rows * MapViewport.cellSize,
                  child: widget.builder(_transform),
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: '縮小',
                      onPressed: () => _zoom(1 / 1.3, size),
                      icon: const Icon(Icons.remove),
                    ),
                    IconButton(
                      tooltip: '全体を表示',
                      onPressed: () {
                        final scale = ((size.width - 24) /
                                (widget.columns * MapViewport.cellSize))
                            .clamp(0.02, 1.0);
                        final heightScale = ((size.height - 64) /
                                (widget.rows * MapViewport.cellSize))
                            .clamp(0.02, 1.0);
                        final fit = scale < heightScale ? scale : heightScale;
                        _transform.value = Matrix4.identity()
                          ..translateByDouble(12, 12, 0, 1)
                          ..scaleByDouble(fit, fit, fit, 1);
                      },
                      icon: const Icon(Icons.fit_screen),
                    ),
                    IconButton(
                      tooltip: '拡大',
                      onPressed: () => _zoom(1.3, size),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
