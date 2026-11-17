import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/presentation/models/drawn_group.dart';
import 'package:caesar_puzzle/presentation/services/drawn_group_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = DrawnGroupService();

  test('remove keeps oldest connected component after split', () {
    final group = DrawnGroup(
      cells: [
        DrawnCell(cell: Cell(0, 0), order: 0),
        DrawnCell(cell: Cell(0, 1), order: 1),
        DrawnCell(cell: Cell(0, 2), order: 2),
        DrawnCell(cell: Cell(0, 3), order: 3),
      ],
      nextOrder: 4,
    );

    final updated = service.remove(group: group, cell: Cell(0, 1));

    expect(updated, isNotNull);
    expect(updated!.cellSet, {Cell(0, 0)});
  });

  group('reserved cells', () {
    const grid = PuzzleGridEntity(cellSize: 10, rows: 7, columns: 7, origin: Position.zero());

    test('drawing cannot start on a reserved cell', () {
      final group = service.start(cell: Cell(1, 1), grid: grid, pieces: const [], reserved: {Cell(1, 1)});

      expect(group, isNull);
    });

    test('drawing does not extend over a reserved cell', () {
      final group = DrawnGroup.start(Cell(1, 0));

      final updated = service.extend(
        group: group,
        cell: Cell(1, 1),
        grid: grid,
        pieces: const [],
        reserved: {Cell(1, 1)},
      );

      expect(updated.cellSet, {Cell(1, 0)});
    });
  });
}
