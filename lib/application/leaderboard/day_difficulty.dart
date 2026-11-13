import 'dart:math' as math;

import 'package:caesar_puzzle/application/leaderboard/standard_day_solutions.dart';
import 'package:caesar_puzzle/application/models/period_range_resolver.dart';

/// Difficulty tier (1 easiest .. 5 hardest) of a date on the Standard layout.
class DayDifficulty {
  const DayDifficulty._();

  static const int minTier = 1;
  static const int maxTier = 5;
  static const int maxExtraSolutions = 10;

  /// Highest solution count of tiers 5, 4, 3 and 2; quintiles of the year.
  static const List<int> _tierBounds = [36, 51, 68, 88];

  static const List<int> _firstSolvePoints = [10, 12, 14, 17, 20];

  static int get maxDayPoints => _firstSolvePoints.last + maxExtraSolutions;

  static int solutionCount(final int month, final int day) => standardDaySolutions[_dayIndex(month, day)];

  static int tier(final int month, final int day) {
    final count = solutionCount(month, day);
    final index = _tierBounds.indexWhere((final bound) => count <= bound);
    return index == -1 ? minTier : maxTier - index;
  }

  static int dayPoints({required final int tier, required final int extraSolutions}) =>
      _firstSolvePoints[tier - minTier] + math.min(extraSolutions, maxExtraSolutions);

  static int _dayIndex(final int month, final int day) {
    const year = PeriodRangeResolver.gridTemplateYear;
    final date = DateTime.utc(year, month, day);
    assert(date.month == month && date.day == day, 'invalid date $month/$day');
    return date.difference(DateTime.utc(year)).inDays;
  }
}
