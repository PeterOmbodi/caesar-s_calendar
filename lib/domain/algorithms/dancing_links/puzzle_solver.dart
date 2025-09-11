import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/core/utils/placement_extrension.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/dancing_links.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid.dart';
import 'package:caesar_puzzle/infrastructure/dto/placement_dto.dart';
import 'package:caesar_puzzle/infrastructure/dto/puzzle_piece_dto.dart';
import 'package:flutter/foundation.dart';

/// A solver class for Caesar's calendar puzzle.
/// This class builds an exact cover matrix based on the configuration:
/// - grid: the grid configuration
/// - pieces: the list of available puzzle pieces (boardPieces),
/// - currentDate: the date whose cells should remain free
class PuzzleSolver {
  final PuzzleGrid grid;
  final List<PuzzlePieceDto> pieces;
  final DateTime date;
  late Iterable<Cell> forbiddenCells;
  late Iterable<Cell> unmovableCells;

  PuzzleSolver({
    required this.grid,
    required this.pieces,
    required this.date,
  })  : forbiddenCells = pieces.where((e) => e.isForbidden).map((e) => e.cells).expand((e) => e),
        unmovableCells = pieces.where((e) => e.isImmovable).map((e) => e.cells).expand((e) => e);

  /// Build the list of constraints (columns) for the exact cover problem.
  /// Here we assume that each grid cell (except those that must remain free) gets an identifier
  /// in the format "cell_r_c". Also, for each piece we add a constraint "piece_<id>".
  List<String> buildConstraints() {
    List<String> constraints = [];
    var cellIndex = 0;
    for (int row = 0; row < grid.rows; row++) {
      for (int column = 0; column < grid.columns; column++) {
        if (forbiddenCells.contains(Cell(row, column))) {
          continue;
        }
        final isTodayLabel = cellIndex < 12 && date.month == cellIndex + 1 || cellIndex - 11 == date.day;
        if (!isTodayLabel && !unmovableCells.contains(Cell(row, column))) {
          constraints.add('cell_${row}_$column');
        }
        cellIndex++;
        if (cellIndex > 42) {
          break;
        }
      }
    }
    for (var piece in pieces.where((p) => !p.isForbidden && !p.isImmovable)) {
      constraints.add('piece_${piece.id}');
    }
    // debugPrint('buildConstraints: $constraints');
    return constraints;
  }

  /// Generate candidate placements for a given puzzle piece.
  List<PlacementDto> generatePlacementsForPiece(PuzzlePieceDto piece) {
    List<PlacementDto> placements = [];
    final Set<Cell> forbidden = forbiddenCells.toSet();
    final Set<Cell> dateCells = buildDateCells();
    final Set<String> placementSignatures = {};
    // debugPrint('generatePlacementsForPiece, forbidden: $forbidden');
    // debugPrint('generatePlacementsForPiece, dateCells: $dateCells');
    var cellIndex = 0;
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
            if (cellIndex > 42) {
              break;
            }
          }
        }
      }
    }
    return placements;
  }

  /// Build a set of cells that must remain free
  Set<Cell> buildDateCells() {
    Set<Cell> free = {};
    var cellIndex = 0;
    for (int row = 0; row < grid.rows; row++) {
      for (int column = 0; column < grid.columns; column++) {
        if (forbiddenCells.contains(Cell(row, column))) {
          continue;
        }
        final isTodayLabel = cellIndex < 12 && date.month == cellIndex + 1 || cellIndex - 11 == date.day;
        if (isTodayLabel) {
          free.add(Cell(row, column));
        }
        cellIndex++;
        if (cellIndex > 42) {
          break;
        }
      }
    }

    return free;
  }

  /// Solves the puzzle using Dancing Links.
  List<List<String>> solve() {
    List<String> constraints = buildConstraints();
    var universe = DlxUniverse(constraints);
    final idToPlacement = <String, PlacementDto>{};
    for (var piece in pieces.where((item) => !item.isForbidden && !item.isImmovable)) {
      List<PlacementDto> placements = generatePlacementsForPiece(piece);
      for (var placement in placements) {
        idToPlacement[placement.id] = placement;
        final rowConstraints = <String>[
          for (var cell in placement.coveredCells) 'cell_${cell.row}_${cell.col}',
          'piece_${placement.piece.id}',
        ];
        rowConstraints.add('piece_${piece.id}');
        universe.addRow(placement.id, rowConstraints);
      }
    }

    debugPrint('${DateTime.now()}, Run the Dancing Links search.');
    universe.search();
    if (universe.solutions.isNotEmpty) {
      debugPrint("${DateTime.now()}, Solution found: ${universe.solutions.first}");
      // for (var id in solution) {
      //   final placement = idToPlacement[id]!;
      //   final coordinates = placement.coveredCells.map((cell) {
      //     final rowLetter = String.fromCharCode('A'.codeUnitAt(0) + cell.row);
      //     return '$rowLetter${cell.col}';
      //   }).toList();
      //   debugPrint('---- $id covers: ${coordinates.join(', ')}');
      // }
    } else {
      debugPrint("${DateTime.now()}, No solution found.");
    }
    return universe.solutions;
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

  Future<List<List<String>>> solveInIsolate() async {
    return await compute(_solveEntryPoint, toSerializable());
  }

  static List<List<String>> _solveEntryPoint(Map<String, dynamic> data) {
    final solver = PuzzleSolver.fromSerializable(data);
    return solver.solve();
  }
}
