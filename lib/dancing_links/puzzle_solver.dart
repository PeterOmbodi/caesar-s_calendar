import 'package:caesar_puzzle/dancing_links/cell.dart';
import 'package:caesar_puzzle/dancing_links/dancing_links.dart';
import 'package:caesar_puzzle/dancing_links/placement.dart';
import 'package:caesar_puzzle/puzzle/puzzle_grid.dart';
import 'package:caesar_puzzle/puzzle/puzzle_piece.dart';
import 'package:flutter/material.dart';

/// A solver class for Caesar's calendar puzzle.
/// This class builds an exact cover matrix based on the configuration:
/// - grid: the grid configuration (например, для свободных ячеек и запретов),
/// - pieces: the list of available puzzle pieces (boardPieces),
/// - currentDate: the date whose cells should remain free (например, текущий месяц/day).
class PuzzleSolver {
  final PuzzleGrid grid;
  final List<PuzzlePiece> pieces;
  final DateTime currentDate;

  PuzzleSolver({
    required this.grid,
    required this.pieces,
    required this.currentDate,
  });

  /// Build the list of constraints (columns) for the exact cover problem.
  /// Here we assume that each grid cell (except those that must remain free) gets an identifier
  /// in the format "cell_r_c". Also, for each piece we add a constraint "piece_<id>".
  List<String> buildConstraints() {
    List<String> constraints = [];
    final today = DateTime.now();
    var cellIndex = 0;
    for (int row = 0; row < grid.rows; row++) {
      for (int column = 0; column < grid.columns; column++) {
        if ((row == 0 && column == 6) ||
            (row == 1 && column == 6) ||
            (row == 6 && column == 3) ||
            (row == 6 && column == 4) ||
            (row == 6 && column == 5) ||
            (row == 6 && column == 6)) {
          continue;
        }
        final isTodayLabel = cellIndex < 12 && today.month == cellIndex + 1 || cellIndex - 11 == today.day;
        if (!isTodayLabel) {
          constraints.add('cell_${row}_$column');
        }
        cellIndex++;
      }
    }
    for (var piece in pieces.where((p) => p.isDraggable)) {
      constraints.add('piece_${piece.id}');
    }
    return constraints;
  }

  /// Generate candidate placements for a given puzzle piece.
  List<Placement> generatePlacementsForPiece(PuzzlePiece piece) {
    List<Placement> placements = [];
    final Set<Cell> forbidden = buildForbiddenCells();
    final Set<Cell> dateCells = buildDateCells();
    final Set<String> placementSignatures = {};
    debugPrint('generatePlacementsForPiece, forbidden: $forbidden');
    debugPrint('generatePlacementsForPiece, free: $dateCells');
    for (int rot = 0; rot < 4; rot++) {
      for (bool flip in [false, true]) {
        for (int r = 0; r < grid.rows; r++) {
          for (int c = 0; c < grid.columns; c++) {
            var placement = Placement(piece, r, c, rot, flip);
            if (placement.fitsInBoard(grid) &&
                placement.doesNotOverlapForbiddenZones(forbidden) &&
                placement.doesNotCoverFreeCells(dateCells)) {
              final cells = List<Cell>.from(placement.coveredCells);
              cells.sort((a, b) {
                if (a.row == b.row) return a.col.compareTo(b.col);
                return a.row.compareTo(b.row);
              });
              final signature = cells.map((cell) => '${cell.row}:${cell.col}').join(',');
              if (!placementSignatures.contains(signature)) {
                placementSignatures.add(signature);
                placements.add(placement);
              }
            }
          }
        }
      }
    }
    return placements;
  }

  /// Build a set of forbidden cells.
  Set<Cell> buildForbiddenCells() {
    Set<Cell> forbidden = {};
    pieces
        .where((e) => !e.isDraggable)
        .forEach((item) => forbidden.addAll(_cellsFromPath(item.getTransformedPath(), grid.origin, grid.cellSize)));
    return forbidden;
  }

  /// Returns a set of grid cells (as [Cell]) that are covered by the given [path].
  /// The [origin] represents the top-left corner of the grid and [cellSize] is the size of one grid cell.
  Set<Cell> _cellsFromPath(Path path, Offset origin, double cellSize) {
    final Set<Cell> cells = {};
    final Rect bounds = path.getBounds();

    // Determine grid indices covering the path's bounding box.
    // We adjust by the grid's origin.
    final int startCol = ((bounds.left - origin.dx) / cellSize).floor();
    final int startRow = ((bounds.top - origin.dy) / cellSize).floor();
    final int endCol = ((bounds.right - origin.dx) / cellSize).ceil();
    final int endRow = ((bounds.bottom - origin.dy) / cellSize).ceil();

    // Loop over each grid cell index within the bounding box.
    for (int row = startRow; row < endRow; row++) {
      for (int col = startCol; col < endCol; col++) {
        // Compute the center point of the cell.
        final Offset cellCenter = Offset(
          origin.dx + col * cellSize + cellSize / 2,
          origin.dy + row * cellSize + cellSize / 2,
        );
        // If the cell center lies within the path, add the cell.
        if (path.contains(cellCenter)) {
          cells.add(Cell(row, col));
        }
      }
    }
    return cells;
  }

  /// Build a set of cells that must remain free
  Set<Cell> buildDateCells() {
    Set<Cell> free = {};
    final today = DateTime.now();
    var cellIndex = 0;
    for (int row = 0; row < grid.rows; row++) {
      for (int column = 0; column < grid.columns; column++) {
        if ((row == 0 && column == 6) ||
            (row == 1 && column == 6) ||
            (row == 6 && column == 3) ||
            (row == 6 && column == 4) ||
            (row == 6 && column == 5) ||
            (row == 6 && column == 6)) {
          //todo could be used instead buildForbiddenCells?
          continue;
        }
        final isTodayLabel = cellIndex < 12 && today.month == cellIndex + 1 || cellIndex - 11 == today.day;
        if (isTodayLabel) {
          free.add(Cell(row, column));
        }
        cellIndex++;
      }
    }

    return free;
  }

  /// A helper function to extract cell coordinates covered by a given rectangular area.
  // Set<Cell> _cellsFromRect(Rect rect, Offset origin, double cellSize) {
  //   Set<Cell> cells = {};
  //   int startRow = ((rect.top - origin.dy) / cellSize).floor();
  //   int startCol = ((rect.left - origin.dx) / cellSize).floor();
  //   int endRow = ((rect.bottom - origin.dy) / cellSize).ceil();
  //   int endCol = ((rect.right - origin.dx) / cellSize).ceil();
  //   for (int r = startRow; r < endRow; r++) {
  //     for (int c = startCol; c < endCol; c++) {
  //       cells.add(Cell(r, c));
  //     }
  //   }
  //   return cells;
  // }

  /// Solves the puzzle using Dancing Links.
  /// It builds the exact cover matrix from the grid configuration and candidate placements,
  /// runs the search and, if a solution is found, interprets it.
  List<String> solve() {
    // 1. Build universe (list of constraints).
    List<String> constraints = buildConstraints();

    var universe = DlxUniverse(constraints);
    final idToPlacement = <String, Placement>{};
    // 2. For each piece, generate candidate placements and add them as rows.
    for (var piece in pieces) {
      List<Placement> placements = generatePlacementsForPiece(piece);
      for (var placement in placements) {
        idToPlacement[placement.id] = placement;
        final rowConstraints = <String>[
          for (var cell in placement.coveredCells) 'cell_${cell.row}_${cell.col}',
          'piece_${placement.piece.id}',
        ];
        // add restriction for piece single using
        rowConstraints.add('piece_${piece.id}');
        // Add the row to DLX universe.
        universe.addRow(placement.id, rowConstraints);
      }
    }

    // 3. Run the Dancing Links search.
    universe.search();

    // 4. Interpret the solution.
    if (universe.solutions.isNotEmpty) {
      final solution = universe.solutions.first;
      debugPrint("---- Solution found: $solution");
      for (var id in solution) {
        final placement = idToPlacement[id]!;
        final coordinates = placement.coveredCells.map((cell) {
          final rowLetter = String.fromCharCode('A'.codeUnitAt(0) + cell.row);
          return '$rowLetter${cell.col}';
        }).toList();
        debugPrint('---- $id covers: ${coordinates.join(', ')}');
      }
      return solution;
    } else {
      debugPrint("---- No solution found.");
      return [];
    }
  }
}
