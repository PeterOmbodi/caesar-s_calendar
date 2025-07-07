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

  factory PuzzleGrid.initial() => PuzzleGrid(cellSize: 1, rows: 1, columns: 1, origin: Offset.zero);

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

  Map<String, dynamic> toSerializable() => {
    'cellSize': cellSize,
    'rows': rows,
    'columns': columns,
    'origin': {'dx': origin.dx, 'dy': origin.dy},
  };

  static PuzzleGrid fromSerializable(Map<String, dynamic> map) => PuzzleGrid(
    cellSize: map['cellSize'],
    rows: map['rows'],
    columns: map['columns'],
    origin: Offset(map['origin']['dx'], map['origin']['dy']),
  );
}