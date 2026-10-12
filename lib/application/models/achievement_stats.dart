class AchievementStats {
  const AchievementStats({
    required this.solvedDates,
    required this.solvedHard,
    required this.bestStreakDays,
    required this.solutionsFound,
    required this.fastestSolveMs,
    required this.cleanSolves,
    required this.customLayoutSolves,
    required this.firstSolvedAt,
  });

  /// Every month-day, Feb 29 included.
  static const int calendarDates = 366;

  /// Solved calendar dates as (month, day), whatever the year.
  final Set<(int, int)> solvedDates;
  final int solvedHard;
  final int bestStreakDays;
  final int solutionsFound;
  final int? fastestSolveMs;

  /// Solved without hints.
  final int cleanSolves;
  final int customLayoutSolves;
  final DateTime? firstSolvedAt;
}
