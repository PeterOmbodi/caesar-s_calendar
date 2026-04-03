import 'exact_cover_problem.dart';
import 'exact_cover_result.dart';

abstract class ExactCoverSolver<C extends Object, R extends Object> {
  ExactCoverResult<R> solve(
    final ExactCoverProblem<C, R> problem, {
    final int? maxSolutions,
  });

  void solveWithCallback(
    final ExactCoverProblem<C, R> problem, {
    required final void Function(ExactCoverSolution<R> solution) onSolution,
    final int? maxSolutions,
  });
}
