import 'package:caesar_puzzle/domain/entities/puzzle_base_entity.dart';
import 'package:flutter/material.dart';

class PuzzleBoard extends PuzzleBaseEntity {
  const PuzzleBoard({
    required super.cellSize,
    required super.rows,
    required super.columns,
    required super.origin,
  });

  factory PuzzleBoard.initial() => const PuzzleBoard(cellSize: 1, rows: 1, columns: 1, origin: Offset.zero);
}
