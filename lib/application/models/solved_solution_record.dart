class SolvedSolutionRecord {
  const SolvedSolutionRecord({
    required this.puzzleDate,
    required this.configId,
    required this.signature,
    required this.sessionId,
    required this.solvedAt,
  });

  final DateTime puzzleDate;
  final String configId;
  final String signature;
  final String sessionId;
  final int solvedAt;
}
