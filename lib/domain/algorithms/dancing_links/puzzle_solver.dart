import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/dancing_links.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/models/solver_piece.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/models/solver_placement.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';

/// A solver class for Caesar's calendar puzzle.
/// This class builds an exact cover matrix based on the configuration:
/// - grid: the grid configuration
/// - pieces: the list of available puzzle pieces (boardPieces),
/// - currentDate: the date whose cells should remain free
class PuzzleSolver {
  PuzzleSolver({required this.grid, required this.pieces, required this.date})
    : forbiddenCells = pieces
          .where((final e) => e.isForbidden)
          .map((final e) => e.cells)
          .expand((final e) => e)
          .toSet(),
      unmovableCells = pieces
          .where((final e) => e.isImmovable)
          .map((final e) => e.cells)
          .expand((final e) => e)
          .toSet() {
    forbiddenCellKeys = {for (final cell in forbiddenCells) _cellKey(cell.row, cell.col)};
    unmovableCellKeys = {for (final cell in unmovableCells) _cellKey(cell.row, cell.col)};
  }

  factory PuzzleSolver.fromSerializable(final Map<String, dynamic> map) => PuzzleSolver(
    grid: PuzzleGridEntity.fromSerializable(map['grid']),
    pieces: (map['pieces'] as List)
        .map((final e) => SolverPiece.fromSerializable(Map<String, dynamic>.from(e as Map)))
        .toList(),
    date: DateTime.parse(map['currentDate']),
  );

  final PuzzleGridEntity grid;
  final Iterable<SolverPiece> pieces;
  final DateTime date;
  late Set<Cell> forbiddenCells;
  late Set<Cell> unmovableCells;
  late final Set<int> forbiddenCellKeys;
  late final Set<int> unmovableCellKeys;

  /// Build the list of constraints (columns) for the exact cover problem.
  /// Here we assume that each grid cell (except those that must remain free) gets an identifier
  /// in the format "cell_r_c". Also, for each piece we add a constraint "piece_{id}".
  List<String> buildConstraints() {
    final constraints = <String>[];
    var cellIndex = 0;
    for (var row = 0; row < grid.rows; row++) {
      for (var column = 0; column < grid.columns; column++) {
        if (_isForbidden(row, column)) {
          continue;
        }
        final isTodayLabel = (cellIndex < 12 && date.month == cellIndex + 1) || (cellIndex - 11 == date.day);
        if (!isTodayLabel && !_isUnmovable(row, column)) {
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
    return constraints;
  }

  /// Generate candidate placements for a given puzzle piece.
  List<SolverPlacement> generatePlacementsForPiece(final SolverPiece piece) {
    final placements = <SolverPlacement>[];
    final forbidden = forbiddenCells;
    final dateCells = buildDateCells();
    final placementSignatures = <String>{};
    for (var rot = 0; rot < 4; rot++) {
      for (final flip in [false, true]) {
        for (var row = 0; row < grid.rows; row++) {
          for (var col = 0; col < grid.columns; col++) {
            final placement = SolverPlacement(piece: piece, row: row, col: col, rotationSteps: rot, isFlipped: flip);
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
        if (_isForbidden(row, column)) {
          continue;
        }
        final isTodayLabel = (cellIndex < 12 && date.month == cellIndex + 1) || (cellIndex - 11 == date.day);
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
    final idToPlacement = <String, SolverPlacement>{};
    for (final piece in pieces.where((final item) => !item.isForbidden && !item.isImmovable)) {
      final placements = generatePlacementsForPiece(piece);
      for (final placement in placements) {
        idToPlacement[placement.id] = placement;
        final rowConstraints = <String>[
          for (final cell in placement.coveredCells) 'cell_${cell.row}_${cell.col}',
          'piece_${placement.piece.id}',
        ];
        universe.addRow(placement.id, rowConstraints);
      }
    }

    universe.search();
    return universe.solutions;
  }

  Map<String, dynamic> toSerializable() => {
    'grid': grid.toSerializable(),
    'pieces': pieces.map((final e) => e.toMap()).toList(),
    'currentDate': date.toIso8601String(),
  };

  static Iterable<List<String>> solveEntryPoint(final Map<String, dynamic> data) {
    final solver = PuzzleSolver.fromSerializable(data);
    return solver.solve();
  }

  int _cellKey(final int row, final int col) => row * grid.columns + col;

  bool _isForbidden(final int row, final int col) => forbiddenCellKeys.contains(_cellKey(row, col));

  bool _isUnmovable(final int row, final int col) => unmovableCellKeys.contains(_cellKey(row, col));
}
