import 'package:flutter/material.dart';

abstract class PuzzleBaseEntity {
  final double cellSize;
  final int rows;
  final int columns;
  final Offset origin;

  const PuzzleBaseEntity({
    required this.cellSize,
    required this.rows,
    required this.columns,
    required this.origin,
  });

  Offset get topLeft => origin;
}
