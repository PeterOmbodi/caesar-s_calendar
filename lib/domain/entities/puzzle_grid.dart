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