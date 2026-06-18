import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/presentation/models/drawn_group.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_grid_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_extension.dart';

class DrawnGroupService {
  const DrawnGroupService();

  DrawnGroup? start({
    required final Cell cell,
    required final PuzzleGridEntity grid,
    required final Iterable<PuzzlePieceUI> pieces,
  }) {
    if (!_isFreeCell(cell: cell, grid: grid, pieces: pieces)) {
      return null;
    }
    return DrawnGroup.start(cell);
  }

  DrawnGroup extend({
    required final DrawnGroup group,
    required final Cell cell,
    required final PuzzleGridEntity grid,
    required final Iterable<PuzzlePieceUI> pieces,
  }) {
    if (group.contains(cell)) {
      return group;
    }
    if (!_isFreeCell(cell: cell, grid: grid, pieces: pieces)) {
      return group;
    }
    if (!_sharesSideWithAny(cell, group.cellSet)) {
      return group;
    }
    return group.copyWith(
      cells: [
        ...group.cells,
        DrawnCell(cell: cell, order: group.nextOrder),
      ],
      nextOrder: group.nextOrder + 1,
    );
  }

  DrawnGroup? remove({required final DrawnGroup group, required final Cell cell}) {
    if (!group.contains(cell)) {
      return group;
    }
    final remaining = group.cells.where((final e) => e.cell != cell).toList();
    if (remaining.isEmpty) {
      return null;
    }

    final oldestComponent = _oldestConnectedComponent(remaining);
    return group.copyWith(cells: oldestComponent);
  }

  bool isOccupied({
    required final Cell cell,
    required final PuzzleGridEntity grid,
    required final Iterable<PuzzlePieceUI> pieces,
  }) {
    final occupied = pieces
        .where((final piece) => piece.placeZone == PlaceZone.grid)
        .expand((final piece) => piece.cells(grid.origin, grid.cellSize));
    return occupied.contains(cell);
  }

  bool _isFreeCell({
    required final Cell cell,
    required final PuzzleGridEntity grid,
    required final Iterable<PuzzlePieceUI> pieces,
  }) => grid.containsCell(cell) && !isOccupied(cell: cell, grid: grid, pieces: pieces);

  bool _sharesSideWithAny(final Cell cell, final Set<Cell> cells) => _neighbors(cell).any(cells.contains);

  List<DrawnCell> _oldestConnectedComponent(final List<DrawnCell> cells) {
    final byCell = {for (final item in cells) item.cell: item};
    final unvisited = byCell.keys.toSet();
    var best = <DrawnCell>[];
    var bestOldestOrder = 1 << 30;

    while (unvisited.isNotEmpty) {
      final start = unvisited.first;
      final queue = <Cell>[start];
      final component = <DrawnCell>[];
      unvisited.remove(start);

      for (var index = 0; index < queue.length; index++) {
        final current = queue[index];
        component.add(byCell[current]!);
        for (final neighbor in _neighbors(current)) {
          if (unvisited.remove(neighbor)) {
            queue.add(neighbor);
          }
        }
      }

      final oldestOrder = component.map((final e) => e.order).reduce((final a, final b) => a < b ? a : b);
      if (oldestOrder < bestOldestOrder) {
        bestOldestOrder = oldestOrder;
        best = component;
      }
    }

    best.sort((final a, final b) => a.order.compareTo(b.order));
    return best;
  }

  Iterable<Cell> _neighbors(final Cell cell) sync* {
    yield Cell(cell.row - 1, cell.col);
    yield Cell(cell.row + 1, cell.col);
    yield Cell(cell.row, cell.col - 1);
    yield Cell(cell.row, cell.col + 1);
  }
}
