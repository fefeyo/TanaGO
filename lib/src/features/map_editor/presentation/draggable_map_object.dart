import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../domain/map_object.dart';
import 'map_viewport.dart';

/// Only this tile rebuilds while dragging. Saves are serialized per object,
/// and the preview survives slow/old snapshots until the latest save is echoed.
class DraggableMapObject extends StatefulWidget {
  const DraggableMapObject({
    super.key,
    required this.object,
    required this.columns,
    required this.rows,
    required this.transform,
    required this.enabled,
    required this.onMove,
    required this.onError,
    required this.onTap,
    required this.onLongPress,
    required this.child,
  });

  final MapObject object;
  final int columns;
  final int rows;
  final TransformationController transform;
  final bool enabled;
  final Future<Offset?> Function(int x, int y) onMove;
  final VoidCallback onError;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Widget child;

  @override
  State<DraggableMapObject> createState() => _DraggableMapObjectState();
}

class _DraggableMapObjectState extends State<DraggableMapObject> {
  Offset? _preview;
  Offset? _pointerOrigin;
  Offset? _dragOrigin;
  Offset? _beforeDrag;
  double _dragScale = 1;
  int _revision = 0;
  bool _saving = false;
  Future<void> _saves = Future.value();

  Offset get _remote =>
      Offset(widget.object.x.toDouble(), widget.object.y.toDouble());
  Offset get _position => _preview ?? _remote;

  @override
  void didUpdateWidget(covariant DraggableMapObject oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_saving && _pointerOrigin == null && _preview == _remote) {
      _preview = null;
    }
    if (!widget.enabled && _pointerOrigin != null) _cancel();
  }

  Offset _clamp(Offset position) => Offset(
        position.dx.clamp(0, widget.columns - widget.object.width).toDouble(),
        position.dy.clamp(0, widget.rows - widget.object.height).toDouble(),
      );

  void _cancel() {
    if (_pointerOrigin == null) return;
    setState(() {
      _preview = _beforeDrag;
      _pointerOrigin = null;
      _dragOrigin = null;
      if (!_saving && _preview == _remote) _preview = null;
    });
  }

  void _finish() {
    if (_dragOrigin == null) return;
    final target = _clamp(
      Offset(_position.dx.roundToDouble(), _position.dy.roundToDouble()),
    );
    final origin = _dragOrigin;
    _pointerOrigin = null;
    _dragOrigin = null;
    if (target == origin) {
      setState(() => _preview = _beforeDrag);
      return;
    }
    final revision = ++_revision;
    setState(() {
      _preview = target;
      _saving = true;
    });
    final save = widget.onMove;
    final reportError = widget.onError;
    _saves = _saves.then((_) async {
      try {
        final saved = await save(target.dx.toInt(), target.dy.toInt());
        if (!mounted || revision != _revision) return;
        setState(() {
          _saving = false;
          // A new drag may already be in progress while this save completes.
          if (_pointerOrigin == null) {
            _preview = saved == _remote ? null : saved;
          }
          _beforeDrag = saved == _remote ? null : saved;
        });
      } catch (_) {
        if (!mounted) return;
        if (revision == _revision) {
          setState(() {
            _saving = false;
            if (_pointerOrigin == null) _preview = null;
            _beforeDrag = null;
          });
        }
        reportError();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final position = _clamp(_position);
    return Positioned(
      left: position.dx * MapViewport.cellSize,
      top: position.dy * MapViewport.cellSize,
      width: widget.object.width * MapViewport.cellSize,
      height: widget.object.height * MapViewport.cellSize,
      child: RepaintBoundary(
        child: Listener(
          onPointerCancel: (_) => _cancel(),
          child: GestureDetector(
            key: ValueKey('map-object-${widget.object.id}'),
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onTap: widget.enabled ? widget.onTap : null,
            onLongPress: widget.enabled ? widget.onLongPress : null,
            onPanStart: !widget.enabled
                ? null
                : (details) {
                    _beforeDrag = _preview;
                    _dragOrigin = _position;
                    _pointerOrigin = details.globalPosition;
                    _dragScale = widget.transform.value.getMaxScaleOnAxis();
                  },
            onPanUpdate: !widget.enabled
                ? null
                : (details) {
                    if (_pointerOrigin == null) return;
                    setState(
                      () => _preview = _clamp(
                        _dragOrigin! +
                            (details.globalPosition - _pointerOrigin!) /
                                (_dragScale * MapViewport.cellSize),
                      ),
                    );
                  },
            onPanEnd: widget.enabled ? (_) => _finish() : null,
            onPanCancel: widget.enabled ? _cancel : null,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
