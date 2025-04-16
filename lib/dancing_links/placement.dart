import 'package:caesar_puzzle/dancing_links/cell.dart';
import 'package:caesar_puzzle/dancing_links/puzzle_piece_extensions.dart';
import 'package:caesar_puzzle/puzzle/puzzle_grid.dart';
import 'package:caesar_puzzle/puzzle/puzzle_piece.dart';

/// Represents a candidate placement for a puzzle piece.
/// A placement is defined by:
///  - the puzzle piece to place,
///  - the grid position (row, col) of its anchor point,
///  - the rotation in multiples of 90° (0, 1, 2, or 3),
///  - whether the piece is flipped horizontally.
class Placement {
  final PuzzlePiece piece;
  final int row;
  final int col;
  final int rotationSteps; // 0 = no rotation, 1 = 90°, 2 = 180°, 3 = 270°
  final bool isFlipped;

  Placement(this.piece, this.row, this.col, this.rotationSteps, this.isFlipped);

  /// Returns a list of grid cells that would be covered by the piece
  /// when placed at (row, col) with the given rotation and flip.
  ///
  /// Note: The actual implementation depends on how the piece shape is defined.
  /// Here, it is assumed that the piece provides a method or property
  /// that returns a list of relative cell coordinates (e.g. [Cell]) for its default orientation.
  List<Cell> get coveredCells {
    // Assume that piece.relativeCells returns List<Cell> for the piece's default orientation.
    // Then, apply rotation and flip to these cells and offset by (row, col).
    List<Cell> cells = [];
    for (var rel in piece.relativeCells) {
      // Apply rotation. For each 90° rotation, the transformation is:
      // (r, c) -> (c, -r)
      int r = rel.row;
      int c = rel.col;
      for (int i = 0; i < rotationSteps; i++) {
        int temp = r;
        r = c;
        c = -temp;
      }
      // Apply flip horizontally if needed.
      if (isFlipped) {
        c = -c;
      }
      // Offset by the placement position.
      cells.add(Cell(row + r, col + c));
    }
    return cells;
  }

  /// Checks whether this placement fits entirely within the given board.
  /// It iterates through all covered cells and verifies that each one is inside board bounds.
  bool fitsInBoard(PuzzleGrid grid) {
    for (var cell in coveredCells) {
      if (cell.row < 0 ||
          cell.row >= grid.rows ||
          cell.col < 0 ||
          cell.col >= grid.columns) {
        return false;
      }
    }
    return true;
  }

  /// Checks that this placement does not overlap forbidden zones.
  /// [forbiddenZones] can be a list of Placements or a list of cells that must remain free.
  bool doesNotOverlapForbiddenZones(Set<Cell> forbiddenCells) {
    for (var cell in coveredCells) {
      if (forbiddenCells.contains(cell)) return false;
    }
    return true;
  }

  /// Checks that the placement does not cover any cells that must remain free,
  /// for example, cells corresponding to the current month or day.
  bool doesNotCoverFreeCells(Set<Cell> freeCells) {
    for (var cell in coveredCells) {
      if (freeCells.contains(cell)) return false;
    }
    return true;
  }

  /// Generates a unique ID for this placement.
  /// This can be used when adding rows to the DLX matrix.
  String get id {
    return '${piece.id}_r${row}_c${col}_rot$rotationSteps${isFlipped ? "_F" : ""}';
  }

  @override
  String toString() {
    return 'Placement(${piece.id}, row: $row, col: $col, rotation: ${rotationSteps * 90}°, flipped: $isFlipped)';
  }
}
