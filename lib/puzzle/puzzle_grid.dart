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

    // Calculate the closest cell coordinates
    final cellX = (relativeX / cellSize).round();
    final cellY = (relativeY / cellSize).round();

    // Make sure we're within grid bounds
    final boundedCellX = cellX.clamp(0, columns - 1);
    final boundedCellY = cellY.clamp(0, rows - 1);

    // Convert back to absolute coordinates
    final snappedX = boundedCellX * cellSize + origin.dx;
    final snappedY = boundedCellY * cellSize + origin.dy;

    return Offset(snappedX, snappedY);
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