import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_extension.dart';

const _calendarCellCount = 43;

/// Cells not covered by blocks, in label order: the 12 months, then days 1 to 31.
List<Cell> calendarCells({required final PuzzleGridEntity grid, required final Iterable<PuzzlePieceUI> pieces}) {
  final blocked = pieces
      .where((final p) => p.isConfigItem)
      .expand((final p) => p.cells(grid.origin, grid.cellSize))
      .toSet();
  return [
    for (var row = 0; row < grid.rows; row++)
      for (var column = 0; column < grid.columns; column++)
        if (!blocked.contains(Cell(row, column))) Cell(row, column),
  ].take(_calendarCellCount).toList();
}

/// The month and day cells of [date], which no piece may cover.
Set<Cell> dateCells({
  required final PuzzleGridEntity grid,
  required final Iterable<PuzzlePieceUI> pieces,
  required final DateTime date,
}) {
  final cells = calendarCells(grid: grid, pieces: pieces);
  final monthIndex = date.month - 1;
  final dayIndex = 11 + date.day;
  return {
    if (monthIndex < cells.length) cells[monthIndex],
    if (dayIndex < cells.length) cells[dayIndex],
  };
}
