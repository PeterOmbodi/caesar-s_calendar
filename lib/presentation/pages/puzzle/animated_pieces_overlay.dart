import 'dart:math' as math;

import 'package:caesar_puzzle/core/utils/puzzle_piece_extension.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_piece.dart';
import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:flutter/material.dart';

typedef PieceId = String;

class AnimatedPiecesOverlay extends StatefulWidget {
  final List<PuzzlePiece> pieces;
  final Duration duration;
  final Curve curve;
  final Widget Function(Set<PieceId> hiddenIds) childBuilder;
  final bool borderColorMode;
  final PuzzlePiece? selectedPiece;

  const AnimatedPiecesOverlay({
    super.key,
    required this.pieces,
    required this.duration,
    required this.curve,
    required this.childBuilder,
    this.borderColorMode = false,
    this.selectedPiece,
  });

  @override
  State<AnimatedPiecesOverlay> createState() => _AnimatedPiecesOverlayState();
}

class _AnimatedPiecesOverlayState extends State<AnimatedPiecesOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  Map<PieceId, PuzzlePiece> _prevById = {};
  Map<PieceId, _PieceTween> _tweens = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    _prevById = _indexById(widget.pieces);
  }

  @override
  void didUpdateWidget(covariant AnimatedPiecesOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tweens.isEmpty) {
      return widget.childBuilder(const {});
    }
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, _) => Stack(
        fit: StackFit.passthrough,
        children: [
          widget.childBuilder(_tweens.keys.toSet()),
          IgnorePointer(
            child: CustomPaint(
              painter: _PiecesTweenPainter(
                tweens: _tweens,
                t: _animation.value,
                borderColorMode: widget.borderColorMode,
                selectedPieceId: widget.selectedPiece?.id,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Map<PieceId, PuzzlePiece> _indexById(List<PuzzlePiece> list) => {for (final p in list) p.id: p};

  Map<PieceId, _PieceTween> _buildTweens(Map<PieceId, PuzzlePiece> from, Map<PieceId, PuzzlePiece> to) {
    final result = <PieceId, _PieceTween>{};
    for (final entry in to.entries) {
      final id = entry.key;
      final next = entry.value;
      final prev = from[id];
      if (prev == null) continue;

      final hasMeaningfulChange =
          !_offsetEq(prev.position, next.position) ||
          !_doubleEq(prev.rotation, next.rotation) ||
          (prev.isFlipped != next.isFlipped);

      if (!hasMeaningfulChange) continue;

      result[id] = _PieceTween(from: prev, to: next);
    }
    return result;
  }

  bool _offsetEq(Offset a, Offset b) => (a - b).distance <= 0.01;

  bool _doubleEq(double a, double b) => (a - b).abs() <= 0.001;
}

class _PieceTween {
  final PuzzlePiece from;
  final PuzzlePiece to;

  _PieceTween({required this.from, required this.to});

  Offset lerpPos(double t) => Offset.lerp(from.position, to.position, t)!;

  double lerpRot(double t) => _lerpAngle(from.rotation, to.rotation, t);

  double lerpFlipScaleX(double t) {
    final a = from.isFlipped ? -1.0 : 1.0;
    final b = to.isFlipped ? -1.0 : 1.0;
    return a + (b - a) * t;
  }

  double _lerpAngle(double a, double b, double t) {
    double d = (b - a);
    while (d > math.pi) {
      d -= 2 * math.pi;
    }
    while (d < -math.pi) {
      d += 2 * math.pi;
    }
    return a + d * t;
  }
}

class _PiecesTweenPainter extends CustomPainter {
  final Map<PieceId, _PieceTween> tweens;
  final double t;
  final bool borderColorMode;
  final String? selectedPieceId;

  _PiecesTweenPainter({
    required this.tweens,
    required this.t,
    required this.borderColorMode,
    required this.selectedPieceId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final tw in tweens.values) {
      final pos = tw.lerpPos(t);
      final rot = tw.lerpRot(t);

      final flipping = tw.from.isFlipped != tw.to.isFlipped;
      double sx;
      if (flipping) {
        final u = (t * 2).clamp(0.0, 2.0);
        if (u < 1.0) {
          final startSign = tw.from.isFlipped ? -1.0 : 1.0;
          sx = startSign * (1.0 - u); // 1..0
        } else {
          final endSign = tw.to.isFlipped ? -1.0 : 1.0;
          sx = endSign * (u - 1.0); // 0..1
        }
        if (sx.abs() < 1e-3) sx = sx.isNegative ? -1e-3 : 1e-3;
      } else {
        sx = tw.to.isFlipped ? -1.0 : 1.0;
      }
      final ghost = tw.to.copyWith(position: pos, rotation: rot, isFlipped: false);
      final basePath = ghost.getTransformedPath();
      final centerWorld = pos + ghost.centerPoint;
      final squash = flipping ? 1.0 - 0.12 * (math.sin(t * math.pi)) : 1.0;

      canvas
        ..save()
        ..translate(centerWorld.dx, centerWorld.dy)
        ..scale(sx, squash)
        ..translate(-centerWorld.dx, -centerWorld.dy);

      final isSelected = ghost.id == selectedPieceId;

      final fill = Paint()
        ..isAntiAlias = true
        ..color = isSelected ? ghost.color().withValues(alpha: 0.9) : ghost.color()
        ..style = PaintingStyle.fill;

      final stroke = Paint()
        ..isAntiAlias = true
        ..color = isSelected ? AppColors.current.pieceBorderSelected : ghost.borderColor(borderColorMode)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3.0 : 1.5
        ..strokeJoin = StrokeJoin.round
        ..strokeMiterLimit = 2.0;

      canvas
        ..drawPath(basePath, fill)
        ..drawPath(basePath, stroke)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PiecesTweenPainter old) =>
      old.tweens != tweens ||
      old.t != t ||
      old.borderColorMode != borderColorMode ||
      old.selectedPieceId != selectedPieceId;
}
