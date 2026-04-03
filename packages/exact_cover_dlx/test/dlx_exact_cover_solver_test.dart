import 'package:exact_cover_dlx/exact_cover_dlx.dart';
import 'package:test/test.dart';

void main() {
  group('DlxExactCoverSolver', () {
    test('finds multiple exact-cover solutions', () {
      final problem = ExactCoverProblem.withPrimaryColumns(
        columns: {1, 2, 3, 4},
        rows: {
          'A': {1, 4},
          'B': {2, 3},
          'C': {1, 3},
          'D': {2, 4},
        },
      );

      const solver = DlxExactCoverSolver<int, String>();
      final result = solver.solve(problem);
      final solutions = result.solutions.map((final item) => item.selectedRows.toSet()).toSet();

      expect(result.reachedLimit, isFalse);
      expect(solutions, {
        {'A', 'B'},
        {'C', 'D'},
      });
    });

    test('supports secondary columns and maxSolutions', () {
      final problem = ExactCoverProblem(
        primaryColumns: {1, 2},
        secondaryColumns: {3},
        rows: {
          'A': {1, 3},
          'B': {2},
          'C': {1},
          'D': {2, 3},
        },
      );

      const solver = DlxExactCoverSolver<int, String>();
      final result = solver.solve(problem, maxSolutions: 1);

      expect(result.reachedLimit, isTrue);
      expect(result.solutions, hasLength(1));
      expect(
        result.solutions.single.selectedRows.toSet(),
        anyOf(
          {'A', 'B'},
          {'C', 'D'},
        ),
      );
    });
  });
}
