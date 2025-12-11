import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_base_entity.dart';

class PuzzleBoardEntity extends PuzzleBaseEntity {
  const PuzzleBoardEntity({
    required super.cellSize,
    required super.rows,
    required super.columns,
    required super.origin,
  });

  factory PuzzleBoardEntity.initial() => const PuzzleBoardEntity(cellSize: 1, rows: 1, columns: 1, origin: Position.zero());
}
