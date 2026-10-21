import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/animated_pieces_overlay.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/piece_paint_helper.dart';
import 'package:flutter/material.dart';

class PiecesTweenPainter extends CustomPainter {

  PiecesTweenPainter({
    required this.tweens,
    required this.t,
    required this.borderColorMode,
    required this.cellSize,
    required this.selectedPieceId,
    this.pinned,
    this.trayDim = noTrayDim,
  });
  final Map<PieceId, PieceTween> tweens;
  final double t;
  final bool borderColorMode;
  final double cellSize;
  final String? selectedPieceId;
  final PuzzlePieceUI? pinned;
  final TrayDim trayDim;

  @override
  void paint(final Canvas canvas, final Size size) {
    final ordered = [
      ...tweens.values.where((final tw) => tw.to.id != selectedPieceId),
      ...tweens.values.where((final tw) => tw.to.id == selectedPieceId),
    ];
    for (final tw in ordered) {
      final dim = PiecePaintHelper.saveTrayDim(canvas, tw.to, trayDim);
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

      final scale = ui.lerpDouble(tw.from.scale, tw.to.scale, t)! / tw.to.scale;
      final centerWorld = pos + tw.to.centerPoint * tw.to.scale;
      canvas
        ..save()
        ..translate(pos.dx, pos.dy)
        ..scale(scale)
        ..translate(-pos.dx, -pos.dy)
        ..translate(centerWorld.dx, centerWorld.dy)
        ..scale(sx, squash)
        ..translate(-centerWorld.dx, -centerWorld.dy);

      final piece = tw.to.copyWith(position: pos, rotation: rot, isFlipped: false);
      PiecePaintHelper.drawPiece(
        canvas,
        piece,
        cellSize: cellSize,
        look: piece.id == selectedPieceId ? PieceLook.selected : PieceLook.normal,
        showHintBadge: borderColorMode && !piece.isUsersItem,
      );

      canvas.restore();
      if (dim) {
        canvas.restore();
      }
    }

    final pinned = this.pinned;
    if (pinned != null) {
      PiecePaintHelper.drawPiece(
        canvas,
        pinned,
        cellSize: cellSize,
        look: pinned.id == selectedPieceId ? PieceLook.selected : PieceLook.normal,
        showHintBadge: borderColorMode && !pinned.isUsersItem,
      );
    }
  }

  @override
  bool shouldRepaint(covariant final PiecesTweenPainter old) =>
      old.tweens != tweens ||
      old.t != t ||
      old.borderColorMode != borderColorMode ||
      old.cellSize != cellSize ||
      old.selectedPieceId != selectedPieceId ||
      old.pinned != pinned ||
      old.trayDim != trayDim;
}
