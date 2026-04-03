# exact_cover_dlx

A generic exact cover solver for Dart based on Knuth's Dancing Links (DLX).

This package solves exact cover problems. It does not know anything about Sudoku, tiling puzzles, polyominoes, or other domains directly. Those problems are modeled outside the package and translated into an `ExactCoverProblem<C, R>`.

## Features

- Generic API with typed column and row identifiers
- DLX-based solver implementation
- Support for primary and secondary columns
- Optional solution limit via `maxSolutions`
- Callback-based solving to avoid collecting every solution in memory
- Pure Dart package with no Flutter dependency

## When to use this package

Use `exact_cover_dlx` when your problem can be modeled as:

- a set of constraints that must be covered exactly once
- a set of candidate rows
- each row covering a subset of constraints

Typical examples:

- Sudoku
- polyomino and pentomino tiling
- exact cover variants of placement puzzles
- configuration and scheduling problems that map cleanly to exact cover

## Installation

```yaml
dependencies:
  exact_cover_dlx: ^0.1.0
```

## Core API

The package exposes:

- `ExactCoverProblem<C, R>`
- `ExactCoverSolution<R>`
- `ExactCoverResult<R>`
- `ExactCoverSolver<C, R>`
- `DlxExactCoverSolver<C, R>`

### ExactCoverProblem

`ExactCoverProblem<C, R>` describes the full search space:

- `C` is the column identifier type
- `R` is the row identifier type
- `primaryColumns` are required constraints
- `secondaryColumns` are optional constraints that may be covered at most once
- `rows` maps each candidate row to the set of columns it covers

If you do not need secondary columns, use `ExactCoverProblem.withPrimaryColumns(...)`.

## Quick start

```dart
import 'package:exact_cover_dlx/exact_cover_dlx.dart';

void main() {
  final problem = ExactCoverProblem.withPrimaryColumns(
    columns: {'A', 'B', 'C', 'D'},
    rows: {
      'row_1': {'A', 'D'},
      'row_2': {'B', 'C'},
      'row_3': {'A', 'C'},
      'row_4': {'B', 'D'},
    },
  );

  const solver = DlxExactCoverSolver<String, String>();
  final result = solver.solve(problem);

  for (final solution in result.solutions) {
    print(solution.selectedRows);
  }
}
```

This finds two exact-cover solutions:

```text
[row_1, row_2]
[row_3, row_4]
```

You can also run the package example:

```bash
dart run example/main.dart
```

Or run the Sudoku example:

```bash
dart run example/sudoku_example.dart
```

## Limiting the number of solutions

Use `maxSolutions` when you only need the first solution or the first few:

```dart
const solver = DlxExactCoverSolver<String, String>();
final result = solver.solve(problem, maxSolutions: 1);

print(result.reachedLimit); // true when the requested limit was reached
print(result.solutions.single.selectedRows);
```

## Streaming solutions with a callback

If you want to process solutions as they are found instead of collecting all of them:

```dart
const solver = DlxExactCoverSolver<String, String>();

solver.solveWithCallback(
  problem,
  maxSolutions: 10,
  onSolution: (solution) {
    print(solution.selectedRows);
  },
);
```

## Secondary columns

Secondary columns are optional constraints. They are useful when a constraint may be covered at most once, but does not have to appear in every complete solution.

```dart
final problem = ExactCoverProblem(
  primaryColumns: {'A', 'B'},
  secondaryColumns: {'tag:x'},
  rows: {
    'row_1': {'A', 'tag:x'},
    'row_2': {'B'},
    'row_3': {'A'},
    'row_4': {'B', 'tag:x'},
  },
);

const solver = DlxExactCoverSolver<String, String>();
final result = solver.solve(problem);
```

This produces two valid solutions:

```text
[row_1, row_2]
[row_3, row_4]
```

## Sudoku example

Sudoku is not built into the package, but it maps naturally to exact cover.

One common modeling approach is:

- each possible placement `(row, column, digit)` becomes a candidate row
- each candidate row covers 4 primary constraints:
- one digit per cell
- one occurrence of each digit per row
- one occurrence of each digit per column
- one occurrence of each digit per box

For example, you might model the domain types like this:

```dart
sealed class SudokuConstraint {
  const SudokuConstraint();
}

class CellConstraint extends SudokuConstraint {
  const CellConstraint(this.row, this.column);

  final int row;
  final int column;
}

class RowDigitConstraint extends SudokuConstraint {
  const RowDigitConstraint(this.row, this.digit);

  final int row;
  final int digit;
}

class SudokuPlacement {
  const SudokuPlacement(this.row, this.column, this.digit);

  final int row;
  final int column;
  final int digit;
}
```

After building that matrix, solve it with the same API:

```dart
final problem = ExactCoverProblem.withPrimaryColumns(
  columns: sudokuConstraints,
  rows: sudokuCandidates,
);

const solver = DlxExactCoverSolver<SudokuConstraint, SudokuPlacement>();
final result = solver.solve(problem, maxSolutions: 1);
```

The package stays generic. The Sudoku-specific mapping lives in your own code.

A complete runnable Sudoku example is included in:

- `example/sudoku_example.dart`

## Design notes

- The public API is intentionally expressed in terms of exact cover, not linked-list internals.
- `DlxExactCoverSolver` is the current solving strategy.
- `DlxNode` and related implementation details are private.
- Column and row identifiers can be strings, ints, enums, records, or custom value objects.

## Validation

`ExactCoverProblem` performs basic validation:

- primary and secondary columns must be disjoint
- every row must cover at least one declared column
- rows may only reference declared columns

## Limitations

- The solver is currently synchronous.
- Solution ordering depends on the row and column iteration order in the input data.
- Large search spaces can still be expensive even with DLX.

## License

This package is licensed under the MIT License.
