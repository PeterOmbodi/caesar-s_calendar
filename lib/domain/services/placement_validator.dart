import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_piece_entity.dart';

class PlacementValidator {
  const PlacementValidator();

  /// Returns true when placement collides (out of bounds or overlaps).
  bool hasCollision({
    required final PuzzlePieceEntity candidate,
    required final PuzzleGridEntity grid,
    required final Iterable<PuzzlePieceEntity> others,
    required final bool preventOverlap,
  }) {
    // out of bounds
    for (final cell in candidate.absoluteCells) {
      if (cell.row < 0 || cell.row >= grid.rows || cell.col < 0 || cell.col >= grid.columns) {
        return true;
      }
    }

    if (!preventOverlap) return false;

    final occupied = <Cell>{};
    for (final other in others) {
      occupied.addAll(other.absoluteCells);
    }

    for (final cell in candidate.absoluteCells) {
      if (occupied.contains(cell)) {
        return true;
      }
    }

    return false;
  }
}
