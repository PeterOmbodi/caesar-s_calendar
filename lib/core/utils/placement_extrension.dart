import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/infrastructure/dto/placement_dto.dart';

import '../../domain/entities/puzzle_base_entity.dart';

extension PlacementX on PlacementDto {
  List<Cell> get coveredCells {
    List<Cell> cells = [];
    for (var rel in piece.relativeCells) {
      int r = rel[0];
      int c = rel[1];
      for (int i = 0; i < rotationSteps; i++) {
        int temp = r;
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

  bool fitsInBoard(PuzzleBaseEntity grid) {
    for (var cell in coveredCells) {
      if (cell.row < 0 || cell.row >= grid.rows || cell.col < 0 || cell.col >= grid.columns) {
        return false;
      }
    }
    return true;
  }

  bool doesNotOverlapForbiddenZones(Set<Cell> forbiddenCells) {
    for (var cell in coveredCells) {
      if (forbiddenCells.contains(cell)) return false;
    }
    return true;
  }

  bool doesNotCoverFreeCells(Set<Cell> freeCells) {
    for (var cell in coveredCells) {
      if (freeCells.contains(cell)) return false;
    }
    return true;
  }
}