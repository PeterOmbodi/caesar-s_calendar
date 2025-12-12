import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_base_entity.dart';

import 'solver_piece.dart';

class SolverPlacement {
  const SolverPlacement({
    required this.piece,
    required this.row,
    required this.col,
    required this.rotationSteps,
    required this.isFlipped,
  });

  final SolverPiece piece;
  final int row;
  final int col;
  final int rotationSteps;
  final bool isFlipped;

  String get id => '${piece.id}_r${row}_c${col}_rot$rotationSteps${isFlipped ? "_F" : ""}';

  List<Cell> get coveredCells {
    final cells = <Cell>[];
    for (final rel in piece.cells) {
      var r = rel.row;
      var c = rel.col;
      for (var i = 0; i < rotationSteps; i++) {
        final temp = r;
        r = c;
        c = -temp;
      }
      if (isFlipped) {
        c = -c;
      }
      cells.add(Cell(row + r, col + c));
    }
    return cells;
  }

  bool fitsInBoard(final PuzzleBaseEntity grid) {
    for (final cell in coveredCells) {
      if (cell.row < 0 || cell.row >= grid.rows || cell.col < 0 || cell.col >= grid.columns) {
        return false;
      }
    }
    return true;
  }

  bool doesNotOverlapForbiddenZones(final Set<Cell> forbiddenCells) {
    for (final cell in coveredCells) {
      if (forbiddenCells.contains(cell)) return false;
    }
    return true;
  }

  bool doesNotCoverFreeCells(final Set<Cell> freeCells) {
    for (final cell in coveredCells) {
      if (freeCells.contains(cell)) return false;
    }
    return true;
  }
}
