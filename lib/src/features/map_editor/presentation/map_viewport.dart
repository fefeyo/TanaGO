import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;

/// Requests a view change without coupling the shopping list to map gestures.
class MapViewportController extends ChangeNotifier {
  Rect? _target;
  void focus(Rect target) {
    _target = target;
    notifyListeners();
  }
}

/// A fixed cell size keeps large maps usable; zoom changes the view, not data.
class MapViewport extends StatefulWidget {
  const MapViewport({
    super.key,
    required this.columns,
    required this.rows,
    required this.builder,
    this.editing = false,
    this.controller,
  });

  static const cellSize = 36.0;
  final int columns;
  final int rows;
  final bool editing;
  final MapViewportController? controller;
  final Widget Function(
    TransformationController transform,
    ValueListenable<bool> pinchGuard,
  ) builder;

  @override
  State<MapViewport> createState() => _MapViewportState();
}

class _MapViewportState extends State<MapViewport>
    with SingleTickerProviderStateMixin {
  final _transform = TransformationController();
  final _pinchGuard = ValueNotifier(false);
  final _pointers = <int, Offset>{};
  double? _pinchDistance;
  double _pinchScale = 1;
  Offset _pinchScene = Offset.zero;

  Size _size = Size.zero;
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  Animation<Matrix4>? _movement;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_focus);
    _animation.addListener(() {
      if (_movement != null) _transform.value = _movement!.value;
    });
  }

  @override
  void didUpdateWidget(covariant MapViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_focus);
      widget.controller?.addListener(_focus);
    }
  }

  void _focus() {
    final target = widget.controller?._target;
    if (target == null || _size.isEmpty) return;
    final scale = math
        .min(
          (_size.width - 48) / target.width,
          (_size.height - 48) / target.height,
        )
        .clamp(0.02, 2.0);
    final end = Matrix4.identity()
      ..translateByDouble(
        _size.width / 2 - target.center.dx * scale,
        _size.height / 2 - target.center.dy * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, scale, 1);
    _movement = Matrix4Tween(begin: _transform.value.clone(), end: end)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_animation);
    _animation.forward(from: 0);
  }

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
    _animation.stop();
    if (!widget.editing) return;
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
    widget.controller?.removeListener(_focus);
    _animation.dispose();
    _pinchGuard.dispose();
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        _size = size;
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
                  panEnabled: !widget.editing,
                  scaleEnabled: !widget.editing,
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
                      tooltip: '全体を表示',
                      onPressed: () {
                        _animation.stop();
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
