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

  factory PuzzleBoard.initial() => PuzzleBoard(cellSize: 1, rows: 1, columns: 1, origin: Offset.zero);

}