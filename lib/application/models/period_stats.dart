class PeriodStats {
  const PeriodStats({
    required this.started,
    required this.solved,
    required this.solvedHard,
    required this.solvedDays,
    required this.bestStreakDays,
    required this.hintsUsed,
    required this.totalTimePlayedMs,
    required this.totalMovesSolved,
  });

  static const empty = PeriodStats(
    started: 0,
    solved: 0,
    solvedHard: 0,
    solvedDays: 0,
    bestStreakDays: 0,
    hintsUsed: 0,
    totalTimePlayedMs: 0,
    totalMovesSolved: 0,
  );

  final int started;
  final int solved;
  final int solvedHard;
  final int solvedDays;
  final int bestStreakDays;
  final int hintsUsed;
  final int totalTimePlayedMs;
  final int totalMovesSolved;

  double get progress => started == 0 ? 0 : (solved / started).clamp(0.0, 1.0);

  double get hardRate => solved == 0 ? 0 : (solvedHard / solved).clamp(0.0, 1.0);

  double get avgMovesPerSolve => solved == 0 ? 0 : totalMovesSolved / solved;
}
