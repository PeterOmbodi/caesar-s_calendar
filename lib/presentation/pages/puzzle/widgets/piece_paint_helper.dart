import 'dart:ui' as ui;

import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/cell_outline.dart';
import 'package:caesar_puzzle/presentation/theme/colors.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_extension.dart';
import 'package:flutter/material.dart';

enum PieceLook { normal, selected, lifted }

/// Tray fade 0..1; [exceptId] is not faded.
typedef TrayDim = ({double amount, String? exceptId});

const TrayDim noTrayDim = (amount: 0, exceptId: null);

class PiecePaintHelper {
  static const double inset = 2;
  static const double radius = 6;
  static const double trayInset = 2.5;
  static const double trayRadius = 5;
  static const double placedFillAlpha = 0.9;
  static const double selectedFillAlpha = 0.95;
  static const double selectionStroke = 2.5;
  static const double dimmedTrayAlpha = 0.45;

  /// Returns true if a layer was saved and must be restored.
  static bool saveTrayDim(final Canvas canvas, final PuzzlePieceUI piece, final TrayDim dim) {
    if (dim.amount <= 0 || piece.placeZone != PlaceZone.board || piece.id == dim.exceptId) {
      return false;
    }
    final alpha = 1 - dim.amount * (1 - dimmedTrayAlpha);
    canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, alpha));
    return true;
  }
  static const Offset selectionLift = Offset(0, -3);

  static const _hairline = Color(0x2E000000);
  static const _sheen = [Color(0x42FFFFFF), Color(0x0FFFFFFF), Color(0x1A000000)];
  static const _sheenStops = [0.0, 0.35, 1.0];
  static const _hintBadgeInk = Color(0xFFFFFFFF);
  static const _hintBadgeShadow = Color(0x59000000);
  // Badge geometry from the mockup, where the cell is 52 pt.
  static const double _mockupCell = 52;
  static const double _hintBadgeRadius = 10.25;
  static const double _hintBadgeStroke = 1.75;
  static const double _hintBadgeShadowBlur = 1.25;
  static const double _hintBadgeShadowDy = 0.5;
  static const double _hintBadgeCornerOffset = 15;
  static const double _hintIconSize = 16;

  static final Map<(PieceType, double, double), _LocalShape> _shapes = {};

  // Icons.lightbulb in a 24 × 24 box; a path because blurred glyphs render wrongly on Impeller.
  static final Path _lightBulb = Path()
    ..addOval(Rect.fromCircle(center: const Offset(12, 9), radius: 7))
    ..addRRect(RRect.fromLTRBR(8, 11, 16, 18, const Radius.circular(1)))
    ..addRRect(RRect.fromLTRBR(9, 19.5, 15, 22, const Radius.circular(1)));

  /// Visible outline of the piece at its current position: inset from the cell edges and rounded.
  static Path outlinePath(final PuzzlePieceUI piece, final double cellSize) =>
      piece.transformLocalPath(_localShape(piece, cellSize).outline);

  static void drawPiece(
    final Canvas canvas,
    final PuzzlePieceUI piece, {
    required final double cellSize,
    final PieceLook look = PieceLook.normal,
    final bool showHintBadge = false,
  }) {
    final colors = AppColors.current.game;
    final isHighlighted = look != PieceLook.normal;

    if (piece.isConfigItem) {
      final path = outlinePath(piece, cellSize);
      canvas
        ..drawPath(path, Paint()..color = colors.blockedCell)
        ..drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = isHighlighted ? selectionStroke : 1.5
            ..color = isHighlighted ? colors.selection : colors.boardBorder,
        );
      return;
    }

    final lift = look == PieceLook.selected ? selectionLift : Offset.zero;
    final path = outlinePath(piece, cellSize).shift(lift);

    final shadow = switch (look) {
      PieceLook.normal => null,
      PieceLook.selected => (dy: 8.0, sigma: 5.0),
      PieceLook.lifted => (dy: 14.0, sigma: 8.0),
    };
    if (shadow != null) {
      canvas.drawPath(
        path.shift(Offset(0, shadow.dy)),
        Paint()
          ..color = colors.shadow
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.sigma),
      );
    }

    final alpha = switch (look) {
      PieceLook.lifted => 1.0,
      _ when piece.placeZone != PlaceZone.grid => 1.0,
      PieceLook.selected => selectedFillAlpha,
      PieceLook.normal => placedFillAlpha,
    };
    final bounds = path.getBounds();
    canvas
      ..drawPath(path, Paint()..color = piece.color().withValues(alpha: alpha))
      ..drawPath(
        path,
        Paint()
          ..shader = ui.Gradient.linear(bounds.topCenter, bounds.bottomCenter, [
            for (final c in _sheen) c.withValues(alpha: c.a * alpha),
          ], _sheenStops),
      )
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = _hairline,
      );

    if (isHighlighted) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = selectionStroke
          ..strokeJoin = StrokeJoin.round
          ..color = colors.selection,
      );
    }

    if (showHintBadge) {
      _drawHintBadge(canvas, piece, cellSize, lift);
    }
  }

  static void _drawHintBadge(final Canvas canvas, final PuzzlePieceUI piece, final double cellSize, final Offset lift) {
    final centers = [for (final c in _localShape(piece, cellSize).cellCenters) piece.transformLocalPoint(c)];
    final top = centers.map((final c) => c.dy).reduce((final a, final b) => a < b ? a : b);
    final topRight = centers
        .where((final c) => (c.dy - top).abs() < 0.5)
        .reduce((final a, final b) => a.dx > b.dx ? a : b);

    final shownCell = cellSize * piece.scale;
    final scale = shownCell / _mockupCell;
    final toCorner = shownCell / 2 - _hintBadgeCornerOffset * scale;
    final center = topRight + Offset(toCorner, -toCorner) + lift;
    final badgeRadius = _hintBadgeRadius * scale;

    final shadowOffset = Offset(0, _hintBadgeShadowDy * scale);
    Paint ring(final Color color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _hintBadgeStroke * scale
      ..color = color;
    canvas
      ..drawCircle(
        center + shadowOffset,
        badgeRadius,
        ring(_hintBadgeShadow)..maskFilter = MaskFilter.blur(BlurStyle.normal, _hintBadgeShadowBlur * scale),
      )
      ..drawCircle(center, badgeRadius, ring(_hintBadgeInk));

    final iconScale = _hintIconSize * scale / 24;
    final icon = _lightBulb.transform(
      (Matrix4.translationValues(center.dx, center.dy, 0)
            ..scaleByDouble(iconScale, iconScale, 1, 1)
            ..translateByDouble(-12, -12, 0, 1))
          .storage,
    );
    canvas
      ..drawPath(
        icon.shift(shadowOffset),
        Paint()
          ..color = _hintBadgeShadow
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, _hintBadgeShadowBlur * scale),
      )
      ..drawPath(icon, Paint()..color = _hintBadgeInk);
  }

  // Tray insets are divided by the scale to stay 2.5 pt on screen.
  static _LocalShape _localShape(final PuzzlePieceUI piece, final double cellSize) =>
      _shapes.putIfAbsent((piece.type, cellSize, piece.scale), () {
        final origin = piece.originalPath.getBounds().topLeft;
        final cells = piece.relativeCells(cellSize);
        final isTray = piece.scale < 1;
        return _LocalShape(
          outline: cellOutlinePath(
            cells,
            cellSize,
            inset: isTray ? trayInset / piece.scale : inset,
            radius: isTray ? trayRadius / piece.scale : radius,
          ).shift(origin),
          cellCenters: [
            for (final c in cells) origin + Offset((c.col + 0.5) * cellSize, (c.row + 0.5) * cellSize),
          ],
        );
      });
}

class _LocalShape {
  const _LocalShape({required this.outline, required this.cellCenters});

  final Path outline;
  final List<Offset> cellCenters;
}
