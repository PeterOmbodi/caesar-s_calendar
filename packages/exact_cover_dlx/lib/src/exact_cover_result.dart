class ExactCoverSolution<R extends Object> {
  const ExactCoverSolution(this.selectedRows);

  final List<R> selectedRows;
}

class ExactCoverResult<R extends Object> {
  const ExactCoverResult({required this.solutions, required this.reachedLimit});

  final List<ExactCoverSolution<R>> solutions;
  final bool reachedLimit;
}
