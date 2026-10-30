import 'package:caesar_puzzle/application/leaderboard/leaderboard_period.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('period keys', () {
    final date = DateTime(2026, 10, 30, 23, 59);

    test('every period', () {
      expect(LeaderboardKeys.period(LeaderboardPeriod.today, date), 'd2026-10-30');
      expect(LeaderboardKeys.period(LeaderboardPeriod.week, date), 'w2026-44');
      expect(LeaderboardKeys.period(LeaderboardPeriod.month, date), 'm2026-10');
      expect(LeaderboardKeys.period(LeaderboardPeriod.year, date), 'y2026');
    });

    test('pads day, month and week', () {
      final jan1 = DateTime(2026);
      expect(LeaderboardKeys.period(LeaderboardPeriod.today, jan1), 'd2026-01-01');
      expect(LeaderboardKeys.period(LeaderboardPeriod.week, jan1), 'w2026-01');
      expect(LeaderboardKeys.period(LeaderboardPeriod.month, jan1), 'm2026-01');
    });

    test('week slots follow month-days, so leap and common years match', () {
      expect(LeaderboardKeys.period(LeaderboardPeriod.week, DateTime(2024, 2, 29)), 'w2024-09');
      expect(LeaderboardKeys.period(LeaderboardPeriod.week, DateTime(2026, 2, 28)), 'w2026-09');
      expect(LeaderboardKeys.period(LeaderboardPeriod.week, DateTime(2026, 3)), 'w2026-09');
      expect(LeaderboardKeys.period(LeaderboardPeriod.week, DateTime(2026, 3, 4)), 'w2026-10');
    });

    test('last short week of the year', () {
      expect(LeaderboardKeys.period(LeaderboardPeriod.week, DateTime(2026, 12, 29)), 'w2026-52');
      expect(LeaderboardKeys.period(LeaderboardPeriod.week, DateTime(2026, 12, 30)), 'w2026-53');
      expect(LeaderboardKeys.period(LeaderboardPeriod.week, DateTime(2026, 12, 31)), 'w2026-53');
    });
  });

  test('board id adds the level', () {
    expect(
      LeaderboardKeys.board(LeaderboardPeriod.week, DateTime(2026, 10, 30), PuzzleSessionDifficulty.hard),
      'w2026-44_hard',
    );
    expect(
      LeaderboardKeys.board(LeaderboardPeriod.today, DateTime(2026, 10, 30), PuzzleSessionDifficulty.medium),
      'd2026-10-30_medium',
    );
  });

  group('ranges', () {
    test('today is a single day', () {
      final range = LeaderboardKeys.range(LeaderboardPeriod.today, DateTime(2026, 10, 30, 18));
      expect(range.start, DateTime(2026, 10, 30));
      expect(range.dayCount, 1);
    });

    test('week has the same days as its key', () {
      final range = LeaderboardKeys.range(LeaderboardPeriod.week, DateTime(2026, 10, 30));
      expect(range.start, DateTime(2026, 10, 28));
      expect(range.end, DateTime(2026, 11, 3));
    });

    test('week over Feb 29 in a common year is one day shorter', () {
      final range = LeaderboardKeys.range(LeaderboardPeriod.week, DateTime(2026, 3));
      expect(range.start, DateTime(2026, 2, 26));
      expect(range.end, DateTime(2026, 3, 3));
      expect(range.dayCount, 6);
    });

    test('month and year', () {
      expect(LeaderboardKeys.range(LeaderboardPeriod.month, DateTime(2026, 2, 10)).dayCount, 28);
      expect(LeaderboardKeys.range(LeaderboardPeriod.year, DateTime(2024, 5)).dayCount, 366);
    });
  });
}
