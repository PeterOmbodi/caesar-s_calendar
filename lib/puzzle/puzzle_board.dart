import 'package:flutter/material.dart';

class PuzzleBoard {
  final double cellSize;
  final int rows;
  final int columns;
  final Offset origin;

  PuzzleBoard({
    required this.cellSize,
    required this.rows,
    required this.columns,
    required this.origin,
  });

  Offset snapToGrid(Offset position) {
    final relativeX = position.dx - origin.dx;
    final relativeY = position.dy - origin.dy;

    final snappedX = (relativeX / cellSize).round() * cellSize + origin.dx;
    final snappedY = (relativeY / cellSize).round() * cellSize + origin.dy;

    return Offset(snappedX, snappedY);
  }

  bool isWithinBounds(Offset position, Size pieceSize) {
    final relativeX = position.dx - origin.dx;
    final relativeY = position.dy - origin.dy;

    return relativeX >= 0 &&
        relativeX + pieceSize.width <= cellSize * columns &&
        relativeY >= 0 &&
        relativeY + pieceSize.height <= cellSize * rows;
  }

  Rect getBounds() {
    return Rect.fromLTWH(
      origin.dx,
      origin.dy,
      cellSize * columns,
      cellSize * rows,
    );
  }
}