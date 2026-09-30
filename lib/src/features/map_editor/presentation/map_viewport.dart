import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

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
  final Widget Function(
    TransformationController transform,
    ValueListenable<bool> pinchGuard,
  ) builder;

  @override
  State<MapViewport> createState() => _MapViewportState();
}

class _MapViewportState extends State<MapViewport> {
  final _transform = TransformationController();
  final _pinchGuard = ValueNotifier(false);
  final _pointers = <int, Offset>{};
  double? _pinchDistance;
  double _pinchScale = 1;
  Offset _pinchScene = Offset.zero;

  // Raw two-finger input remains available even after a shelf's one-finger
  // drag wins the gesture arena. Only edit mode uses this path; browsing uses
  // InteractiveViewer's recognizer. A pinch never commits a shelf move.
  void _beginPinch() {
    if (_pointers.length < 2) {
      _pinchDistance = null;
      return;
    }
    _pinchGuard.value = true;
    final points = _pointers.values.take(2).toList();
    _pinchDistance = (points[1] - points[0]).distance;
    _pinchScale = _transform.value.getMaxScaleOnAxis();
    _pinchScene = _transform.toScene((points[0] + points[1]) / 2);
  }

  void _pointerDown(PointerDownEvent event) {
    if (widget.navigationEnabled) return;
    _pointers[event.pointer] = event.localPosition;
    _beginPinch();
  }

  void _pointerMove(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) return;
    _pointers[event.pointer] = event.localPosition;
    if (_pointers.length < 2 || _pinchDistance == null || _pinchDistance! < 1) {
      return;
    }
    final points = _pointers.values.take(2).toList();
    final focal = (points[0] + points[1]) / 2;
    final scale =
        (_pinchScale * (points[1] - points[0]).distance / _pinchDistance!)
            .clamp(0.02, 3.0);
    _transform.value = Matrix4.identity()
      ..translateByDouble(
        focal.dx - _pinchScene.dx * scale,
        focal.dy - _pinchScene.dy * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, scale, 1);
  }

  void _pointerEnd(PointerEvent event) {
    _pointers.remove(event.pointer);
    _beginPinch();
    if (_pointers.isEmpty) {
      // Suppress tap/end callbacks for the entire multi-touch sequence.
      Future.microtask(() {
        if (mounted && _pointers.isEmpty) _pinchGuard.value = false;
      });
    }
  }

  @override
  void dispose() {
    _pinchGuard.dispose();
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
              child: Listener(
                onPointerDown: _pointerDown,
                onPointerMove: _pointerMove,
                onPointerUp: _pointerEnd,
                onPointerCancel: _pointerEnd,
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
                    child: widget.builder(_transform, _pinchGuard),
                  ),
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
