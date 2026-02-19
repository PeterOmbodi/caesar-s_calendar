class CalendarDayStats {
  const CalendarDayStats({
    required this.date,
    required this.totalSolutions,
    required this.solvedVariants,
    required this.unsolvedStarted,
  });

  final DateTime date;
  final int? totalSolutions;
  final int solvedVariants;
  final int unsolvedStarted;
}
