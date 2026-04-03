import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/models/solver_piece.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/models/solver_placement.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:exact_cover_dlx/exact_cover_dlx.dart';

class CaesarPuzzleExactCoverSolver {
  CaesarPuzzleExactCoverSolver({
    required this.grid,
    required this.pieces,
    required this.date,
    final DlxExactCoverSolver<String, SolverPlacement>? solver,
  }) : solver = solver ?? const DlxExactCoverSolver<String, SolverPlacement>(),
       forbiddenCells = pieces
           .where((final piece) => piece.isForbidden)
           .map((final piece) => piece.cells)
           .expand((final cells) => cells)
           .toSet(),
       unmovableCells = pieces
           .where((final piece) => piece.isImmovable)
           .map((final piece) => piece.cells)
           .expand((final cells) => cells)
           .toSet() {
    forbiddenCellKeys = {for (final cell in forbiddenCells) _cellKey(cell.row, cell.col)};
    unmovableCellKeys = {for (final cell in unmovableCells) _cellKey(cell.row, cell.col)};
  }

  final PuzzleGridEntity grid;
  final Iterable<SolverPiece> pieces;
  final DateTime date;
  final DlxExactCoverSolver<String, SolverPlacement> solver;
  late final Set<Cell> forbiddenCells;
  late final Set<Cell> unmovableCells;
  late final Set<int> forbiddenCellKeys;
  late final Set<int> unmovableCellKeys;

  ExactCoverProblem<String, SolverPlacement> buildProblem() {
    final rows = <SolverPlacement, Set<String>>{};

    for (final piece in pieces.where((final item) => !item.isForbidden && !item.isImmovable)) {
      final placements = generatePlacementsForPiece(piece);
      for (final placement in placements) {
        rows[placement] = {
          for (final cell in placement.coveredCells) 'cell_${cell.row}_${cell.col}',
          'piece_${piece.id}',
        };
      }
    }

    return ExactCoverProblem.withPrimaryColumns(columns: buildPrimaryConstraints(), rows: rows);
  }

  ExactCoverResult<SolverPlacement> solve({final int? maxSolutions}) {
    final problem = buildProblem();
    return solver.solve(problem, maxSolutions: maxSolutions);
  }

  Set<String> buildPrimaryConstraints() {
    final constraints = <String>{};
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

    for (final piece in pieces.where((final item) => !item.isForbidden && !item.isImmovable)) {
      constraints.add('piece_${piece.id}');
    }

    return constraints;
  }

  List<SolverPlacement> generatePlacementsForPiece(final SolverPiece piece) {
    final placements = <SolverPlacement>[];
    final dateCells = buildDateCells();
    final placementSignatures = <String>{};

    for (var rotation = 0; rotation < 4; rotation++) {
      for (final isFlipped in [false, true]) {
        for (var row = 0; row < grid.rows; row++) {
          for (var column = 0; column < grid.columns; column++) {
            final placement = SolverPlacement(
              piece: piece,
              row: row,
              col: column,
              rotationSteps: rotation,
              isFlipped: isFlipped,
            );

            if (placement.fitsInBoard(grid) &&
                placement.doesNotOverlapForbiddenZones(forbiddenCells) &&
                placement.doesNotCoverFreeCells(dateCells)) {
              final signature = _buildPlacementSignature(placement);
              if (placementSignatures.add(signature)) {
                placements.add(placement);
              }
            }
          }
        }
      }
    }

    return placements;
  }

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

  String _buildPlacementSignature(final SolverPlacement placement) {
    final cells = List<Cell>.from(placement.coveredCells)
      ..sort((final left, final right) {
        if (left.row == right.row) {
          return left.col.compareTo(right.col);
        }
        return left.row.compareTo(right.row);
      });

    return cells.map((final cell) => '${cell.row}:${cell.col}').join(',');
  }

  int _cellKey(final int row, final int col) => row * grid.columns + col;

  bool _isForbidden(final int row, final int col) => forbiddenCellKeys.contains(_cellKey(row, col));

  bool _isUnmovable(final int row, final int col) => unmovableCellKeys.contains(_cellKey(row, col));
}
