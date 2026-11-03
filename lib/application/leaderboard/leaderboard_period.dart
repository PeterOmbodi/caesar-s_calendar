import 'package:caesar_puzzle/application/models/period_range_resolver.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';

enum LeaderboardPeriod { today, week, month, year }

/// Period and board ids shared by all players: `d2026-10-30`, `w2026-44`, `m2026-10`, `y2026`.
class LeaderboardKeys {
  const LeaderboardKeys._();

  static String period(final LeaderboardPeriod period, final DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    return switch (period) {
      LeaderboardPeriod.today => 'd$year-${_two(date.month)}-${_two(date.day)}',
      LeaderboardPeriod.week => 'w$year-${_two(PeriodRangeResolver.weekNumber(date))}',
      LeaderboardPeriod.month => 'm$year-${_two(date.month)}',
      LeaderboardPeriod.year => 'y$year',
    };
  }

  static String board(final LeaderboardPeriod period, final DateTime date, final PuzzleSessionDifficulty level) =>
      '${LeaderboardKeys.period(period, date)}_${level.name}';

  static DateRange range(final LeaderboardPeriod period, final DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return switch (period) {
      LeaderboardPeriod.today => DateRange(day, day),
      LeaderboardPeriod.week => PeriodRangeResolver.weekRange(day),
      LeaderboardPeriod.month => PeriodRangeResolver.monthRange(day),
      LeaderboardPeriod.year => PeriodRangeResolver.yearRange(day.year),
    };
  }

  static bool isDayBoard(final String boardId) => boardId.startsWith('d');

  static String _two(final int value) => value.toString().padLeft(2, '0');
}
