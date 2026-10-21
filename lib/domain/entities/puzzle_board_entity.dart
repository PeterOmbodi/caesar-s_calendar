import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_base_entity.dart';

class PuzzleBoardEntity extends PuzzleBaseEntity {
  const PuzzleBoardEntity({
    required super.cellSize,
    required super.rows,
    required super.columns,
    required super.origin,
    this.availableWidth,
    this.availableHeight,
  });

  factory PuzzleBoardEntity.initial() =>
      const PuzzleBoardEntity(cellSize: 1, rows: 1, columns: 1, origin: Position.zero());

  final double? availableWidth;
  final double? availableHeight;

  @override
  double get width => availableWidth ?? super.width;

  @override
  double get height => availableHeight ?? super.height;

  /// Stable cell coordinates are anchored to the centered group of tray pieces.
  @override
  Position get positionOrigin => Position(dx: origin.dx + (width - columns * cellSize) / 2, dy: origin.dy);
}
