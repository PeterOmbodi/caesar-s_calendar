import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Mouse affordances: grab cursors over pieces, right click flips, the wheel rotates.
class PointerControls extends StatefulWidget {
  const PointerControls({super.key, required this.child});

  // Trackpads send a burst of scroll events per gesture.
  static const Duration _wheelGap = Duration(milliseconds: 250);

  final Widget child;

  @override
  State<PointerControls> createState() => _PointerControlsState();
}

class _PointerControlsState extends State<PointerControls> {
  bool _overPiece = false;
  DateTime _lastWheel = DateTime.fromMillisecondsSinceEpoch(0);

  PuzzleBloc get _bloc => context.read<PuzzleBloc>();

  void _onHover(final PointerHoverEvent event) {
    final over = _bloc.pieceIdAt(event.localPosition) != null;
    if (over != _overPiece) {
      setState(() => _overPiece = over);
    }
  }

  void _act(final Offset position, final PuzzleEvent action) {
    final id = _bloc.pieceIdAt(position);
    if (id == null) {
      return;
    }
    _bloc
      ..add(PuzzleEvent.selectPiece(id))
      ..add(action);
  }

  void _onPointerDown(final PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.mouse && event.buttons == kSecondaryMouseButton) {
      _act(event.localPosition, const PuzzleEvent.flipSelected());
    }
  }

  void _onPointerSignal(final PointerSignalEvent event) {
    if (event is! PointerScrollEvent || _bloc.pieceIdAt(event.localPosition) == null) {
      return;
    }
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      final now = DateTime.now();
      if (now.difference(_lastWheel) < PointerControls._wheelGap) {
        return;
      }
      _lastWheel = now;
      _act(event.localPosition, const PuzzleEvent.rotateSelected());
    });
  }

  @override
  Widget build(final BuildContext context) {
    final dragging = context.select<PuzzleBloc, bool>((final bloc) => bloc.state.isDragging);
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerSignal: _onPointerSignal,
      child: MouseRegion(
        cursor: dragging
            ? SystemMouseCursors.grabbing
            : _overPiece
            ? SystemMouseCursors.grab
            : MouseCursor.defer,
        onHover: _onHover,
        onExit: (_) => setState(() => _overPiece = false),
        child: widget.child,
      ),
    );
  }
}
