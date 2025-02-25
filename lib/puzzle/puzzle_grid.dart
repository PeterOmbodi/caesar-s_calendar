import 'package:flutter/material.dart';

class PuzzleGrid {
  final double cellSize;
  final int rows;
  final int columns;
  final Offset origin;

  PuzzleGrid({
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

  bool isWithinBounds(Offset position) {
    final relativeX = position.dx - origin.dx;
    final relativeY = position.dy - origin.dy;

    return relativeX >= 0 &&
        relativeX <= cellSize * columns &&
        relativeY >= 0 &&
        relativeY <= cellSize * rows;
  }
}

