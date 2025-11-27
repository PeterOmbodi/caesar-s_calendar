import 'dart:math' as math;

import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/animated_pieces_overlay.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/piece_paint_helper.dart';
import 'package:flutter/material.dart';

class PiecesTweenPainter extends CustomPainter {

  PiecesTweenPainter({
    required this.tweens,
    required this.t,
    required this.borderColorMode,
    required this.selectedPieceId,
  });
  final Map<PieceId, PieceTween> tweens;
  final double t;
  final bool borderColorMode;
  final String? selectedPieceId;

  @override
  void paint(final Canvas canvas, final Size size) {
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

      final squash = flipping ? 1.0 - 0.12 * (math.sin(t * math.pi)) : 1.0;

      final centerWorld = pos + tw.to.centerPoint;
      canvas
        ..save()
        ..translate(centerWorld.dx, centerWorld.dy)
        ..scale(sx, squash)
        ..translate(-centerWorld.dx, -centerWorld.dy);

      final piece = tw.to.copyWith(position: pos, rotation: rot, isFlipped: false);
      final isSelected = piece.id == selectedPieceId;
      PiecePaintHelper.drawPiece(canvas, piece, isSelected, borderColorMode);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant final PiecesTweenPainter old) =>
      old.tweens != tweens ||
      old.t != t ||
      old.borderColorMode != borderColorMode ||
      old.selectedPieceId != selectedPieceId;
}
