import 'dart:math' as math;
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

  // bool isWithinBounds(Offset position, Path path) {
  //   final transformedPath = Path()
  //     ..addPath(path, position);
  //   final bounds = transformedPath.getBounds();
  //
  //   final boardRect = Rect.fromLTWH(
  //     origin.dx,
  //     origin.dy,
  //     cellSize * columns,
  //     cellSize * rows,
  //   );
  //
  //   // Add some tolerance for edge pieces
  //   final expandedBoard = Rect.fromLTRB(
  //       boardRect.left - 5,
  //       boardRect.top - 5,
  //       boardRect.right + 5,
  //       boardRect.bottom + 5
  //   );
  //
  //   // Check if the piece is largely within the expanded board
  //   final areaOverlap = _getOverlapArea(bounds, expandedBoard);
  //   final pieceArea = bounds.width * bounds.height;
  //
  //   // If more than 75% of the piece is within bounds, consider it valid
  //   return areaOverlap / pieceArea > 0.75;
  // }

  // double _getOverlapArea(Rect a, Rect b) {
  //   final overlapLeft = math.max(a.left, b.left);
  //   final overlapTop = math.max(a.top, b.top);
  //   final overlapRight = math.min(a.right, b.right);
  //   final overlapBottom = math.min(a.bottom, b.bottom);
  //
  //   if (overlapLeft >= overlapRight || overlapTop >= overlapBottom) {
  //     return 0;
  //   }
  //
  //   return (overlapRight - overlapLeft) * (overlapBottom - overlapTop);
  // }

  Rect getBounds() {
    return Rect.fromLTWH(
      origin.dx,
      origin.dy,
      cellSize * columns,
      cellSize * rows,
    );
  }
}