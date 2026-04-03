import 'package:exact_cover_dlx/exact_cover_dlx.dart';

void main() {
  final problem = ExactCoverProblem(
    primaryColumns: {'A', 'B', 'C', 'D'},
    secondaryColumns: {'tag:x'},
    rows: {
      'row_1': {'A', 'D'},
      'row_2': {'B', 'C'},
      'row_3': {'A', 'C', 'tag:x'},
      'row_4': {'B', 'D'},
    },
  );

  const solver = DlxExactCoverSolver<String, String>();
  final result = solver.solve(problem, maxSolutions: 10);

  for (final solution in result.solutions) {
    print(solution.selectedRows);
  }
}
