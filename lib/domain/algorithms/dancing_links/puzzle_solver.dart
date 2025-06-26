import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/core/utils/placement_extrension.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/dancing_links.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid.dart';
import 'package:caesar_puzzle/infrastructure/dto/placement_dto.dart';
import 'package:caesar_puzzle/infrastructure/dto/puzzle_piece_dto.dart';
import 'package:flutter/foundation.dart';

/// A solver class for Caesar's calendar puzzle.
/// This class builds an exact cover matrix based on the configuration:
/// - grid: the grid configuration (например, для свободных ячеек и запретов),
/// - pieces: the list of available puzzle pieces (boardPieces),
/// - currentDate: the date whose cells should remain free (например, текущий месяц/day).
class PuzzleSolver {
  final PuzzleGrid grid;
  final List<PuzzlePieceDto> pieces;
  final DateTime date;

  PuzzleSolver({
    required this.grid,
    required this.pieces,
    required this.date,
  });

  /// Build the list of constraints (columns) for the exact cover problem.
  /// Here we assume that each grid cell (except those that must remain free) gets an identifier
  /// in the format "cell_r_c". Also, for each piece we add a constraint "piece_<id>".
  List<String> buildConstraints() {
    List<String> constraints = [];

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
        final isTodayLabel = cellIndex < 12 && date.month == cellIndex + 1 || cellIndex - 11 == date.day;
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
  List<PlacementDto> generatePlacementsForPiece(PuzzlePieceDto piece) {
    List<PlacementDto> placements = [];
    final Set<Cell> forbidden = buildForbiddenCells();
    final Set<Cell> dateCells = buildDateCells();
    final Set<String> placementSignatures = {};
    // debugPrint('generatePlacementsForPiece, forbidden: $forbidden');
    // debugPrint('generatePlacementsForPiece, free: $dateCells');
    for (int rot = 0; rot < 4; rot++) {
      for (bool flip in [false, true]) {
        for (int row = 0; row < grid.rows; row++) {
          for (int col = 0; col < grid.columns; col++) {
            var placement = PlacementDto(piece, row, col, rot, flip);
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
    for (var item in pieces.where((e) => !e.isDraggable)) {
      for (var cell in item.cells) {
        forbidden.add(cell);
      }
    }
    return forbidden;
  }

  /// Build a set of cells that must remain free
  Set<Cell> buildDateCells() {
    Set<Cell> free = {};
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
        final isTodayLabel = cellIndex < 12 && date.month == cellIndex + 1 || cellIndex - 11 == date.day;
        if (isTodayLabel) {
          free.add(Cell(row, column));
        }
        cellIndex++;
      }
    }

    return free;
  }

  /// Solves the puzzle using Dancing Links.
  /// It builds the exact cover matrix from the grid configuration and candidate placements,
  /// runs the search and, if a solution is found, interprets it.
  List<String> solve() {
    // 1. Build universe (list of constraints).
    List<String> constraints = buildConstraints();
    debugPrint('Solves the puzzle using Dancing Links. constraints: $constraints');
    var universe = DlxUniverse(constraints);
    final idToPlacement = <String, PlacementDto>{};
    // 2. For each piece, generate candidate placements and add them as rows.

    for (var piece in pieces.where((item) => item.isDraggable)) {
      List<PlacementDto> placements = generatePlacementsForPiece(piece);
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
        //debugPrint('universe.addRow. ${placement.id} - rowConstraints: $rowConstraints');
      }
    }

    // 3. Run the Dancing Links search.
    debugPrint('Run the Dancing Links search. ${DateTime.now()}');

    universe.search();

    debugPrint('next step. ${DateTime.now()}');

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

  Map<String, dynamic> toSerializable() {
    return {
      'grid': grid.toSerializable(),
      'pieces': pieces.map((e) => e.toMap()).toList(),
      'currentDate': date.toIso8601String(),
    };
  }

  static PuzzleSolver fromSerializable(Map<String, dynamic> map) {
    return PuzzleSolver(
      grid: PuzzleGrid.fromSerializable(map['grid']),
      pieces: (map['pieces'] as List).map((e) => PuzzlePieceDto.fromMap(e)).toList(),
      date: DateTime.parse(map['currentDate']),
    );
  }

  Future<List<String>> solveInIsolate() async {
    return await compute(_solveEntryPoint, toSerializable());
  }

  static List<String> _solveEntryPoint(Map<String, dynamic> data) {
    final solver = PuzzleSolver.fromSerializable(data);
    return solver.solve();
  }
}
