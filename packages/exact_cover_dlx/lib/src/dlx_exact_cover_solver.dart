import 'exact_cover_problem.dart';
import 'exact_cover_result.dart';
import 'exact_cover_solver.dart';

class DlxExactCoverSolver<C extends Object, R extends Object> implements ExactCoverSolver<C, R> {
  const DlxExactCoverSolver();

  @override
  ExactCoverResult<R> solve(
    final ExactCoverProblem<C, R> problem, {
    final int? maxSolutions,
  }) {
    final solutions = <ExactCoverSolution<R>>[];
    var reachedLimit = false;

    solveWithCallback(
      problem,
      maxSolutions: maxSolutions,
      onSolution: (final solution) {
        solutions.add(solution);
        if (maxSolutions != null && solutions.length >= maxSolutions) {
          reachedLimit = true;
        }
      },
    );

    return ExactCoverResult(solutions: solutions, reachedLimit: reachedLimit);
  }

  @override
  void solveWithCallback(
    final ExactCoverProblem<C, R> problem, {
    required final void Function(ExactCoverSolution<R> solution) onSolution,
    final int? maxSolutions,
  }) {
    if (maxSolutions != null && maxSolutions <= 0) {
      return;
    }

    final state = _DlxState<C, R>.fromProblem(problem);
    final partialSolution = <R>[];
    var solutionCount = 0;

    bool search() {
      if (state.header.right == state.header) {
        onSolution(ExactCoverSolution(List<R>.unmodifiable(partialSolution)));
        solutionCount++;
        return maxSolutions != null && solutionCount >= maxSolutions;
      }

      final column = state.chooseColumn();
      if (column.size == 0) {
        return false;
      }

      state.cover(column);
      for (var row = column.down; row != column; row = row.down) {
        final rowId = row.rowId;
        if (rowId == null) {
          continue;
        }

        partialSolution.add(rowId);
        for (var node = row.right; node != row; node = node.right) {
          state.cover(node.column!);
        }

        final shouldStop = search();
        for (var node = row.left; node != row; node = node.left) {
          state.uncover(node.column!);
        }
        partialSolution.removeLast();

        if (shouldStop) {
          state.uncover(column);
          return true;
        }
      }
      state.uncover(column);
      return false;
    }

    search();
  }
}

class _DlxState<C extends Object, R extends Object> {
  _DlxState._({required this.header});

  factory _DlxState.fromProblem(final ExactCoverProblem<C, R> problem) {
    final header = _DlxColumn<C, R>(null, isPrimary: true);
    final state = _DlxState<C, R>._(header: header);
    final columnMap = <C, _DlxColumn<C, R>>{};
    var previousPrimary = header;

    for (final columnId in problem.primaryColumns) {
      final column = _DlxColumn<C, R>(columnId, isPrimary: true);
      state._linkPrimaryColumn(previousPrimary, column);
      previousPrimary = column;
      columnMap[columnId] = column;
    }

    for (final columnId in problem.secondaryColumns) {
      columnMap[columnId] = _DlxColumn<C, R>(columnId, isPrimary: false);
    }

    state.columnMap = columnMap;

    for (final entry in problem.rows.entries) {
      state.addRow(entry.key, entry.value);
    }

    return state;
  }

  final _DlxColumn<C, R> header;
  late final Map<C, _DlxColumn<C, R>> columnMap;

  void addRow(final R rowId, final Set<C> columns) {
    _DlxNode<C, R>? firstNode;
    for (final columnId in columns) {
      final column = columnMap[columnId];
      if (column == null) {
        throw StateError('Unknown column: $columnId');
      }

      final node = _DlxNode<C, R>(column: column, rowId: rowId);
      node.down = column;
      node.up = column.up;
      column.up.down = node;
      column.up = node;
      column.size++;

      if (firstNode == null) {
        firstNode = node;
      } else {
        node.right = firstNode;
        node.left = firstNode.left;
        firstNode.left.right = node;
        firstNode.left = node;
      }
    }
  }

  _DlxColumn<C, R> chooseColumn() {
    var chosen = header.right as _DlxColumn<C, R>;
    var minSize = chosen.size;

    for (var column = header.right; column != header; column = column.right) {
      final current = column as _DlxColumn<C, R>;
      if (current.size < minSize) {
        chosen = current;
        minSize = current.size;
        if (minSize == 0) {
          break;
        }
      }
    }

    return chosen;
  }

  void cover(final _DlxColumn<C, R> column) {
    if (column.isPrimary) {
      column.right.left = column.left;
      column.left.right = column.right;
    }

    for (var row = column.down; row != column; row = row.down) {
      for (var node = row.right; node != row; node = node.right) {
        node.down.up = node.up;
        node.up.down = node.down;
        node.column!.size--;
      }
    }
  }

  void uncover(final _DlxColumn<C, R> column) {
    for (var row = column.up; row != column; row = row.up) {
      for (var node = row.left; node != row; node = node.left) {
        node.column!.size++;
        node.down.up = node;
        node.up.down = node;
      }
    }

    if (column.isPrimary) {
      column.right.left = column;
      column.left.right = column;
    }
  }

  void _linkPrimaryColumn(final _DlxColumn<C, R> left, final _DlxColumn<C, R> column) {
    column.left = left;
    column.right = header;
    left.right = column;
    header.left = column;
  }
}

class _DlxNode<C extends Object, R extends Object> {
  _DlxNode({this.column, this.rowId}) {
    left = this;
    right = this;
    up = this;
    down = this;
  }

  late _DlxNode<C, R> left;
  late _DlxNode<C, R> right;
  late _DlxNode<C, R> up;
  late _DlxNode<C, R> down;
  final _DlxColumn<C, R>? column;
  final R? rowId;
}

class _DlxColumn<C extends Object, R extends Object> extends _DlxNode<C, R> {
  _DlxColumn(this.id, {required this.isPrimary});

  final C? id;
  final bool isPrimary;
  int size = 0;
}
