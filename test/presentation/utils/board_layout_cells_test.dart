import 'package:caesar_puzzle/application/puzzle_config_json.dart';
import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/core/models/placement.dart';
import 'package:caesar_puzzle/presentation/utils/board_layout_cells.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Standard blocks', () {
    expect(blockedCellsOf(PuzzleConfigJson.standardPlacements), {
      Cell(0, 6),
      Cell(1, 6),
      Cell(6, 3),
      Cell(6, 4),
      Cell(6, 5),
      Cell(6, 6),
    });
  });

  test('a turned block covers the cells of the turned shape', () {
    expect(blockedCellsOf([PlacementParams('zone2', 3, 6, 1, false)]).length, 4);
    expect(blockedCellsOf([PlacementParams('zone2', 3, 6, 1, false)]).map((final c) => c.col).toSet().length, 1);
  });

  test('cellsKey ignores order', () {
    expect(cellsKey([Cell(6, 3), Cell(0, 6)]), cellsKey({Cell(0, 6), Cell(6, 3)}));
    expect(cellsKey([Cell(0, 6)]), isNot(cellsKey([Cell(6, 0)])));
  });
}
