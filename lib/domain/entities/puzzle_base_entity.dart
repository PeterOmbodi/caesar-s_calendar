import 'package:flutter/material.dart';

abstract class PuzzleBaseEntity {
  const PuzzleBaseEntity({required this.cellSize, required this.rows, required this.columns, required this.origin});

  final double cellSize;
  final int rows;
  final int columns;
  final Offset origin;

  Offset get topLeft => origin;
}
