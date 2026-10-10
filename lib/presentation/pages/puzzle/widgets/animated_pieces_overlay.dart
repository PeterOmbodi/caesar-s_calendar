import 'dart:math' as math;

import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/piece_paint_helper.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/pieces_tween_painter.dart';
import 'package:flutter/material.dart';

typedef PieceId = String;

class AnimatedPiecesOverlay extends StatefulWidget {

  const AnimatedPiecesOverlay({
    super.key,
    required this.pieces,
    required this.duration,
    required this.curve,
    required this.childBuilder,
    required this.cellSize,
    this.borderColorMode = false,
    this.instantIds = const {},
    this.selectedPiece,
    this.pinnedId,
    this.dimTray = false,
  });
  final Iterable<PuzzlePieceUI> pieces;
  final Duration duration;
  final Curve curve;
  final Widget Function(Set<PieceId> hiddenIds, TrayDim trayDim) childBuilder;
  final double cellSize;
  final bool borderColorMode;

  /// Pieces that follow their new position without a transition, e.g. the one being dragged.
  final Set<PieceId> instantIds;
  final PuzzlePieceUI? selectedPiece;

  /// Painted above moving pieces.
  final PieceId? pinnedId;

  final bool dimTray;

  @override
  State<AnimatedPiecesOverlay> createState() => _AnimatedPiecesOverlayState();
}

class _AnimatedPiecesOverlayState extends State<AnimatedPiecesOverlay> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late AnimationController _dim;
  PieceId? _dimExceptId;

  Map<PieceId, PuzzlePieceUI> _prevById = {};
  Map<PieceId, PieceTween> _tweens = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    _controller.addStatusListener((final status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _tweens = {});
      }
    });
    _prevById = _indexById(widget.pieces);
    _dim = AnimationController(vsync: this, duration: widget.duration, value: widget.dimTray ? 1 : 0);
    _dimExceptId = widget.selectedPiece?.id;
  }

  @override
  void didUpdateWidget(covariant final AnimatedPiecesOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.dimTray) {
      _dimExceptId = widget.selectedPiece?.id;
    }
    if (widget.dimTray != oldWidget.dimTray) {
      _dim.animateTo(widget.dimTray ? 1 : 0, curve: widget.curve);
    }

    final nextById = _indexById(widget.pieces);

    if (mounted) {
      _tweens = _buildTweens(_prevById, nextById);
      if (_tweens.isNotEmpty) {
        _controller
          ..stop()
          ..reset()
          ..forward();
      }
    } else {
      debugPrint('_AnimatedPiecesOverlayState, not mounted!!');
      _tweens = {};
      _controller
        ..stop()
        ..reset();
    }

    _prevById = nextById;
  }

  @override
  void dispose() {
    _controller.dispose();
    _dim.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([_animation, _dim]),
    builder: (_, _) {
      final trayDim = (amount: _dim.value, exceptId: _dimExceptId);
      if (_tweens.isEmpty) {
        return widget.childBuilder(const {}, trayDim);
      }
      final pinnedId = widget.pinnedId;
      final pinned = pinnedId == null || _tweens.containsKey(pinnedId)
          ? null
          : widget.pieces.where((final p) => p.id == pinnedId).firstOrNull;
      return Stack(
        fit: StackFit.passthrough,
        children: [
          widget.childBuilder({..._tweens.keys, ?pinned?.id}, trayDim),
          IgnorePointer(
            child: CustomPaint(
              painter: PiecesTweenPainter(
                tweens: _tweens,
                t: _animation.value,
                borderColorMode: widget.borderColorMode,
                cellSize: widget.cellSize,
                selectedPieceId: widget.selectedPiece?.id,
                pinned: pinned,
                trayDim: trayDim,
              ),
            ),
          ),
        ],
      );
    },
  );

  static Map<PieceId, PuzzlePieceUI> _indexById(final Iterable<PuzzlePieceUI> list) => {for (final p in list) p.id: p};

  Map<PieceId, PieceTween> _buildTweens(final Map<PieceId, PuzzlePieceUI> from, final Map<PieceId, PuzzlePieceUI> to) {
    final result = <PieceId, PieceTween>{};
    for (final entry in to.entries) {
      final id = entry.key;
      final next = entry.value;
      final prev = from[id];
      if (prev == null || widget.instantIds.contains(id)) continue;

      final hasMeaningfulChange =
          !_offsetEq(prev.position, next.position) ||
          !_doubleEq(prev.rotation, next.rotation) ||
          !_doubleEq(prev.scale, next.scale) ||
          (prev.isFlipped != next.isFlipped);

      if (!hasMeaningfulChange) continue;

      result[id] = PieceTween(from: prev, to: next);
    }
    return result;
  }

  bool _offsetEq(final Offset a, final Offset b) => (a - b).distance <= 0.01;

  bool _doubleEq(final double a, final double b) => (a - b).abs() <= 0.001;
}

class PieceTween {

  PieceTween({required this.from, required this.to});
  final PuzzlePieceUI from;
  final PuzzlePieceUI to;

  Offset lerpPos(final double t) => Offset.lerp(from.position, to.position, t)!;

  double lerpRot(final double t) => _lerpAngle(from.rotation, to.rotation, t);

  double lerpFlipScaleX(final double t) {
    final a = from.isFlipped ? -1.0 : 1.0;
    final b = to.isFlipped ? -1.0 : 1.0;
    return a + (b - a) * t;
  }

  double _lerpAngle(final double a, final double b, final double t) {
    var d = (b - a);
    while (d > math.pi) {
      d -= 2 * math.pi;
    }
    while (d < -math.pi) {
      d += 2 * math.pi;
    }
    return a + d * t;
  }
}
