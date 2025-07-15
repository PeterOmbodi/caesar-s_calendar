import 'package:caesar_puzzle/domain/entities/puzzle_base_entity.dart';
import 'package:flutter/material.dart';

class PuzzleGrid extends PuzzleBaseEntity {
  const PuzzleGrid({
    required super.cellSize,
    required super.rows,
    required super.columns,
    required super.origin,
  });

  factory PuzzleGrid.initial() => const PuzzleGrid(cellSize: 1, rows: 1, columns: 1, origin: Offset.zero);

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
