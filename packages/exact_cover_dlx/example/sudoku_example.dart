import 'package:exact_cover_dlx/exact_cover_dlx.dart';

void main() {
  final puzzle = <List<int>>[
    [0, 0, 3, 4],
    [3, 4, 0, 0],
    [0, 0, 4, 3],
    [4, 3, 0, 0],
  ];

  final problem = buildSudokuProblem(puzzle);
  const solver = DlxExactCoverSolver<SudokuConstraint, SudokuPlacement>();
  final result = solver.solve(problem, maxSolutions: 1);

  if (result.solutions.isEmpty) {
    print('No solution found.');
    return;
  }

  final solvedGrid = applySolution(
    puzzle,
    result.solutions.single.selectedRows,
  );

  for (final row in solvedGrid) {
    print(row.join(' '));
  }
}

ExactCoverProblem<SudokuConstraint, SudokuPlacement> buildSudokuProblem(
  final List<List<int>> puzzle,
) {
  const size = 4;
  const boxSize = 2;
  final columns = <SudokuConstraint>{};
  final rows = <SudokuPlacement, Set<SudokuConstraint>>{};

  for (var row = 0; row < size; row++) {
    for (var column = 0; column < size; column++) {
      // Every cell must contain exactly one digit.
      columns.add(CellConstraint(row, column));
      for (var digit = 1; digit <= size; digit++) {
        // Each candidate placement also enforces row, column, and box uniqueness.
        columns.add(RowDigitConstraint(row, digit));
        columns.add(ColumnDigitConstraint(column, digit));
        columns.add(BoxDigitConstraint(_boxIndex(row, column, boxSize), digit));
      }
    }
  }

  for (var row = 0; row < size; row++) {
    for (var column = 0; column < size; column++) {
      final givenDigit = puzzle[row][column];
      final digits = givenDigit == 0 ? [1, 2, 3, 4] : [givenDigit];

      for (final digit in digits) {
        final placement = SudokuPlacement(row, column, digit);
        // A candidate row says: "place this digit in this cell",
        // and covers the 4 constraints that placement satisfies.
        rows[placement] = {
          CellConstraint(row, column),
          RowDigitConstraint(row, digit),
          ColumnDigitConstraint(column, digit),
          BoxDigitConstraint(_boxIndex(row, column, boxSize), digit),
        };
      }
    }
  }

  return ExactCoverProblem.withPrimaryColumns(columns: columns, rows: rows);
}

List<List<int>> applySolution(
  final List<List<int>> puzzle,
  final List<SudokuPlacement> placements,
) {
  // Copy the puzzle and fill in the chosen placements from the exact-cover solution.
  final solved = [
    for (final row in puzzle) [...row],
  ];

  for (final placement in placements) {
    solved[placement.row][placement.column] = placement.digit;
  }

  return solved;
}

int _boxIndex(final int row, final int column, final int boxSize) =>
    (row ~/ boxSize) * boxSize + (column ~/ boxSize);

sealed class SudokuConstraint {
  const SudokuConstraint();
}

class CellConstraint extends SudokuConstraint {
  const CellConstraint(this.row, this.column);

  final int row;
  final int column;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is CellConstraint &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          column == other.column;

  @override
  int get hashCode => Object.hash(runtimeType, row, column);
}

class RowDigitConstraint extends SudokuConstraint {
  const RowDigitConstraint(this.row, this.digit);

  final int row;
  final int digit;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is RowDigitConstraint &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          digit == other.digit;

  @override
  int get hashCode => Object.hash(runtimeType, row, digit);
}

class ColumnDigitConstraint extends SudokuConstraint {
  const ColumnDigitConstraint(this.column, this.digit);

  final int column;
  final int digit;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is ColumnDigitConstraint &&
          runtimeType == other.runtimeType &&
          column == other.column &&
          digit == other.digit;

  @override
  int get hashCode => Object.hash(runtimeType, column, digit);
}

class BoxDigitConstraint extends SudokuConstraint {
  const BoxDigitConstraint(this.box, this.digit);

  final int box;
  final int digit;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is BoxDigitConstraint &&
          runtimeType == other.runtimeType &&
          box == other.box &&
          digit == other.digit;

  @override
  int get hashCode => Object.hash(runtimeType, box, digit);
}

class SudokuPlacement {
  const SudokuPlacement(this.row, this.column, this.digit);

  final int row;
  final int column;
  final int digit;

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is SudokuPlacement &&
          row == other.row &&
          column == other.column &&
          digit == other.digit;

  @override
  int get hashCode => Object.hash(row, column, digit);
}
