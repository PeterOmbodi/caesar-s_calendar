import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_base_entity.dart';

class PuzzleGridEntity extends PuzzleBaseEntity {
  const PuzzleGridEntity({required super.cellSize, required super.rows, required super.columns, required super.origin});

  factory PuzzleGridEntity.initial() => const PuzzleGridEntity(cellSize: 1, rows: 1, columns: 1, origin: Position.zero());

  factory PuzzleGridEntity.fromSerializable(final Map<String, dynamic> map) => PuzzleGridEntity(
    cellSize: map['cellSize'],
    rows: map['rows'],
    columns: map['columns'],
    origin: Position.fromMap(map['origin'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toSerializable() => {
    'cellSize': cellSize,
    'rows': rows,
    'columns': columns,
    'origin': origin.toMap(),
  };
}
