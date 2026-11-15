import 'package:caesar_puzzle/domain/algorithms/dancing_links/models/solver_placement.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/puzzle_solver.dart';

sealed class SolverStep {
  const SolverStep();
}

class PlaceStep extends SolverStep {
  const PlaceStep(this.placement);

  final SolverPlacement placement;
}

class RemoveStep extends SolverStep {
  const RemoveStep(this.pieceId);

  final String pieceId;
}

/// Depth-first search that reports every piece it puts down and takes back, so that it can be replayed as a player's
/// moves. Unlike Dancing Links it stops at the first solution.
class StepwiseSolver {
  StepwiseSolver(
    this._puzzle, {
    required this.mostConstrainedFirst,
    required this.skipDeadEnds,
  });

  final PuzzleSolver _puzzle;

  /// Fills the empty cell with the fewest fitting placements first, not the first empty cell.
  final bool mostConstrainedFirst;

  /// Takes the last piece back as soon as some empty cell can no longer be covered.
  final bool skipDeadEnds;

  late List<int> _cells;
  late Map<int, List<_Candidate>> _byCell;
  final Set<int> _occupied = {};
  final Set<String> _used = {};
  var _isSolved = false;

  /// Whether the last run of [steps] ended with a solution on the board.
  bool get isSolved => _isSolved;

  Iterable<SolverStep> steps() sync* {
    _prepare();
    yield* _fill();
  }

  void _prepare() {
    final grid = _puzzle.grid;
    int key(final int row, final int col) => row * grid.columns + col;
    final closed = {
      for (final cell in [..._puzzle.forbiddenCells, ..._puzzle.unmovableCells, ..._puzzle.buildDateCells()])
        key(cell.row, cell.col),
    };
    _cells = [
      for (var row = 0; row < grid.rows; row++)
        for (var col = 0; col < grid.columns; col++)
          if (!closed.contains(key(row, col))) key(row, col),
    ];
    _byCell = {for (final cell in _cells) cell: []};
    for (final piece in _puzzle.pieces.where((final p) => !p.isForbidden && !p.isImmovable)) {
      for (final placement in _puzzle.generatePlacementsForPiece(piece)) {
        final candidate = _Candidate(placement, {
          for (final cell in placement.coveredCells) key(cell.row, cell.col),
        });
        for (final cell in candidate.cells) {
          _byCell[cell]?.add(candidate);
        }
      }
    }
    _occupied.clear();
    _used.clear();
    _isSolved = false;
  }

  Iterable<SolverStep> _fill() sync* {
    final cell = _nextCell();
    if (cell == null) {
      _isSolved = true;
      return;
    }
    for (final candidate in _fitting(cell).toList()) {
      _occupied.addAll(candidate.cells);
      _used.add(candidate.pieceId);
      yield PlaceStep(candidate.placement);
      if (!skipDeadEnds || !_hasDeadCell()) {
        yield* _fill();
        if (_isSolved) {
          return;
        }
      }
      _occupied.removeAll(candidate.cells);
      _used.remove(candidate.pieceId);
      yield RemoveStep(candidate.pieceId);
    }
  }

  int? _nextCell() {
    final empty = _cells.where((final cell) => !_occupied.contains(cell));
    if (!mostConstrainedFirst) {
      return empty.firstOrNull;
    }
    int? best;
    var bestCount = 0;
    for (final cell in empty) {
      final count = _fitting(cell).length;
      if (best == null || count < bestCount) {
        best = cell;
        bestCount = count;
      }
    }
    return best;
  }

  bool _hasDeadCell() => _cells.any((final cell) => !_occupied.contains(cell) && _fitting(cell).isEmpty);

  Iterable<_Candidate> _fitting(final int cell) => _byCell[cell]!.where(
    (final c) => !_used.contains(c.pieceId) && !c.cells.any(_occupied.contains),
  );
}

class _Candidate {
  _Candidate(this.placement, this.cells);

  final SolverPlacement placement;
  final Set<int> cells;

  String get pieceId => placement.piece.id;
}
