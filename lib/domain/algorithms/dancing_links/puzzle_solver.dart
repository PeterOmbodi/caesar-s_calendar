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

  PuzzleSolver({
    required this.grid,
    required this.pieces,
    required this.date,
  })
      : forbiddenCells = pieces.where((final e) => e.isForbidden).map((final e) => e.cells).expand((final e) => e),
        unmovableCells = pieces.where((final e) => e.isImmovable).map((final e) => e.cells).expand((final e) => e);

  factory PuzzleSolver.fromSerializable(final Map<String, dynamic> map) =>
      PuzzleSolver(
        grid: PuzzleGrid.fromSerializable(map['grid']),
        pieces: (map['pieces'] as List).map((final e) => PuzzlePieceDto.fromMap(e)).toList(),
        date: DateTime.parse(map['currentDate']),
      );

  final PuzzleGrid grid;
  final Iterable<PuzzlePieceDto> pieces;
  final DateTime date;
  late Iterable<Cell> forbiddenCells;
  late Iterable<Cell> unmovableCells;

  /// Build the list of constraints (columns) for the exact cover problem.
  /// Here we assume that each grid cell (except those that must remain free) gets an identifier
  /// in the format "cell_r_c". Also, for each piece we add a constraint "piece_{id}".
  List<String> buildConstraints() {
    final constraints = <String>[];
    var cellIndex = 0;
    for (var row = 0; row < grid.rows; row++) {
      for (var column = 0; column < grid.columns; column++) {
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
    for (final piece in pieces.where((final p) => !p.isForbidden && !p.isImmovable)) {
      constraints.add('piece_${piece.id}');
    }
    // debugPrint('buildConstraints: $constraints');
    return constraints;
  }

  /// Generate candidate placements for a given puzzle piece.
  List<PlacementDto> generatePlacementsForPiece(final PuzzlePieceDto piece) {
    final placements = <PlacementDto>[];
    final forbidden = forbiddenCells.toSet();
    final dateCells = buildDateCells();
    final placementSignatures = <String>{};
    // debugPrint('generatePlacementsForPiece, forbidden: $forbidden');
    // debugPrint('generatePlacementsForPiece, dateCells: $dateCells');
    final cellIndex = 0;
    for (var rot = 0; rot < 4; rot++) {
      for (final flip in [false, true]) {
        for (var row = 0; row < grid.rows; row++) {
          for (var col = 0; col < grid.columns; col++) {
            final placement = PlacementDto(piece, row, col, rot, flip);
            if (placement.fitsInBoard(grid) &&
                placement.doesNotOverlapForbiddenZones(forbidden) &&
                placement.doesNotCoverFreeCells(dateCells)) {
              final cells = List<Cell>.from(placement.coveredCells);
              cells.sort((final a, final b) {
                if (a.row == b.row) return a.col.compareTo(b.col);
                return a.row.compareTo(b.row);
              });
              final signature = cells.map((final cell) => '${cell.row}:${cell.col}').join(',');
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
    final free = <Cell>{};
    var cellIndex = 0;
    for (var row = 0; row < grid.rows; row++) {
      for (var column = 0; column < grid.columns; column++) {
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
  Iterable<List<String>> solve() {
    final constraints = buildConstraints();
    final universe = DlxUniverse(constraints);
    final idToPlacement = <String, PlacementDto>{};
    for (final piece in pieces.where((final item) => !item.isForbidden && !item.isImmovable)) {
      final placements = generatePlacementsForPiece(piece);
      for (final placement in placements) {
        idToPlacement[placement.id] = placement;
        final rowConstraints = <String>[
          for (final cell in placement.coveredCells) 'cell_${cell.row}_${cell.col}',
          'piece_${placement.piece.id}',
        ];
        rowConstraints.add('piece_${piece.id}');
        universe.addRow(placement.id, rowConstraints);
      }
    }

    debugPrint('${DateTime.now()}, Run the Dancing Links search.');
    universe.search();
    if (universe.solutions.isNotEmpty) {
      debugPrint('${DateTime.now()}, Solution found: ${universe.solutions.first}');
      // for (var id in solution) {
      //   final placement = idToPlacement[id]!;
      //   final coordinates = placement.coveredCells.map((cell) {
      //     final rowLetter = String.fromCharCode('A'.codeUnitAt(0) + cell.row);
      //     return '$rowLetter${cell.col}';
      //   }).toList();
      //   debugPrint('---- $id covers: ${coordinates.join(', ')}');
      // }
    } else {
      debugPrint('${DateTime.now()}, No solution found.');
    }
    return universe.solutions;
  }

  Map<String, dynamic> toSerializable() =>
      {
      'grid': grid.toSerializable(),
        'pieces': pieces.map((final e) => e.toMap()).toList(),
      'currentDate': date.toIso8601String(),
    };

  Future<Iterable<List<String>>> solveInIsolate() async => compute(_solveEntryPoint, toSerializable());

  static Iterable<List<String>> _solveEntryPoint(final Map<String, dynamic> data) {
    final solver = PuzzleSolver.fromSerializable(data);
    return solver.solve();
  }
}
