import 'package:caesar_puzzle/application/models/period_range_resolver.dart';
import 'package:caesar_puzzle/application/models/stats_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('referenceDateFor', () {
    test('combines the real "now" year with the grid selection\'s month/day', () {
      final selectedDate = DateTime(2024, 8, 6);
      final result = PeriodRangeResolver.referenceDateFor(selectedDate, now: DateTime(2026, 1, 15));
      expect(result, DateTime(2026, 8, 6));
    });

    test('clamps Feb 29 down to Feb 28 when "now" falls in a non-leap year', () {
      final selectedDate = DateTime(2024, 2, 29);
      final result = PeriodRangeResolver.referenceDateFor(selectedDate, now: DateTime(2026, 5));
      expect(result, DateTime(2026, 2, 28));
    });

    test('keeps Feb 29 when "now" falls in a leap year', () {
      final selectedDate = DateTime(2024, 2, 29);
      final result = PeriodRangeResolver.referenceDateFor(selectedDate, now: DateTime(2028, 5));
      expect(result, DateTime(2028, 2, 29));
    });
  });

  group('weekRange (fixed grid columns, matching DateSelector)', () {
    test('weeks start Jan 1, Jan 8, Jan 15, ...', () {
      expect(PeriodRangeResolver.weekRange(DateTime(2026, 1, 1)).start, DateTime(2026, 1, 1));
      expect(PeriodRangeResolver.weekRange(DateTime(2026, 1, 1)).end, DateTime(2026, 1, 7));
      expect(PeriodRangeResolver.weekRange(DateTime(2026, 1, 8)).start, DateTime(2026, 1, 8));
      expect(PeriodRangeResolver.weekRange(DateTime(2026, 1, 14)).start, DateTime(2026, 1, 8));
    });

    test('a day picked mid-column resolves to that column\'s start, not itself', () {
      final marchStart = PeriodRangeResolver.weekRange(DateTime(2026, 3, 25));
      expect(marchStart.start, DateTime(2026, 3, 25));
      expect(marchStart.end, DateTime(2026, 3, 31));
      final marchMid = PeriodRangeResolver.weekRange(DateTime(2026, 3, 26));
      expect(marchMid.start, DateTime(2026, 3, 25));
      expect(marchMid.end, DateTime(2026, 3, 31));
    });

    test('column boundaries are identical in a leap year and a non-leap year', () {
      final leapYearRange = PeriodRangeResolver.weekRange(DateTime(2024, 8, 6));
      final nonLeapYearRange = PeriodRangeResolver.weekRange(DateTime(2026, 8, 6));
      expect(leapYearRange.start.month, nonLeapYearRange.start.month);
      expect(leapYearRange.start.day, nonLeapYearRange.start.day);
      expect(leapYearRange.end.month, nonLeapYearRange.end.month);
      expect(leapYearRange.end.day, nonLeapYearRange.end.day);
      expect(leapYearRange.start.day, 5);
      expect(leapYearRange.end.day, 11);
    });

    test('clamps at Dec 31 when the column would spill into next year', () {
      final range = PeriodRangeResolver.weekRange(DateTime(2025, 12, 30));
      expect(range.start, DateTime(2025, 12, 30));
      expect(range.end, DateTime(2025, 12, 31));
    });

    test('the column spanning Feb 29 is Feb 26 - Mar 3, valid in any year', () {
      final leapReference = PeriodRangeResolver.weekRange(DateTime(2024, 2, 29));
      expect(leapReference.start, DateTime(2024, 2, 26));
      expect(leapReference.end, DateTime(2024, 3, 3));
      final mappedToNonLeapYear = PeriodRangeResolver.weekRangeInYear(2025, DateTime(2024, 2, 27));
      expect(mappedToNonLeapYear.start, DateTime(2025, 2, 26));
      expect(mappedToNonLeapYear.end, DateTime(2025, 3, 3));
    });

    test('weekRangeInYear keeps the month/day slot fixed while moving the year', () {
      final referenceDate = DateTime(2024, 8, 6);
      final range2020 = PeriodRangeResolver.weekRangeInYear(2020, referenceDate);
      final range2030 = PeriodRangeResolver.weekRangeInYear(2030, referenceDate);
      expect(range2020.start, DateTime(2020, 8, 5));
      expect(range2020.end, DateTime(2020, 8, 11));
      expect(range2030.start, DateTime(2030, 8, 5));
      expect(range2030.end, DateTime(2030, 8, 11));
    });
  });

  group('DateRange.dayCount', () {
    test('a full 7-day week column', () {
      expect(PeriodRangeResolver.weekRange(DateTime(2026, 3, 25)).dayCount, 7);
    });

    test('a clamped 2-day week at year end', () {
      expect(PeriodRangeResolver.weekRange(DateTime(2025, 12, 30)).dayCount, 2);
    });

    test('a full calendar month', () {
      expect(PeriodRangeResolver.monthRangeInYear(2024, 2).dayCount, 29);
      expect(PeriodRangeResolver.monthRangeInYear(2025, 2).dayCount, 28);
    });

    test('a full calendar year', () {
      expect(PeriodRangeResolver.yearRange(2024).dayCount, 366);
      expect(PeriodRangeResolver.yearRange(2025).dayCount, 365);
    });
  });

  group('monthRange / yearRange', () {
    test('February in a leap year includes the 29th', () {
      final range = PeriodRangeResolver.monthRangeInYear(2024, 2);
      expect(range.start, DateTime(2024, 2, 1));
      expect(range.end, DateTime(2024, 2, 29));
    });

    test('February in a non-leap year ends on the 28th', () {
      final range = PeriodRangeResolver.monthRangeInYear(2025, 2);
      expect(range.end, DateTime(2025, 2, 28));
    });

    test('December spans into next year internally but end is Dec 31', () {
      final range = PeriodRangeResolver.monthRangeInYear(2025, 12);
      expect(range.start, DateTime(2025, 12, 1));
      expect(range.end, DateTime(2025, 12, 31));
    });

    test('yearRange covers Jan 1 to Dec 31', () {
      final range = PeriodRangeResolver.yearRange(2025);
      expect(range.start, DateTime(2025));
      expect(range.end, DateTime(2025, 12, 31));
    });
  });

  group('matches', () {
    final referenceDate = DateTime(2025, 8, 6);

    test('week + currentYear matches only dates within the real current column', () {
      expect(
        PeriodRangeResolver.matches(StatsPeriod.week, StatsYearScope.currentYear, referenceDate, DateTime(2025, 8, 5)),
        isTrue,
      );
      expect(
        PeriodRangeResolver.matches(
          StatsPeriod.week,
          StatsYearScope.currentYear,
          referenceDate,
          DateTime(2025, 8, 11),
        ),
        isTrue,
      );
      expect(
        PeriodRangeResolver.matches(
          StatsPeriod.week,
          StatsYearScope.currentYear,
          referenceDate,
          DateTime(2025, 8, 12),
        ),
        isFalse,
      );
      expect(
        PeriodRangeResolver.matches(StatsPeriod.week, StatsYearScope.currentYear, referenceDate, DateTime(2024, 8, 6)),
        isFalse,
      );
    });

    test('week + allYears matches the same fixed column, recomputed per year', () {
      expect(
        PeriodRangeResolver.matches(StatsPeriod.week, StatsYearScope.allYears, referenceDate, DateTime(2020, 8, 5)),
        isTrue,
      );
      expect(
        PeriodRangeResolver.matches(StatsPeriod.week, StatsYearScope.allYears, referenceDate, DateTime(2020, 8, 4)),
        isFalse,
        reason: 'one day before the column start in that year',
      );
      expect(
        PeriodRangeResolver.matches(StatsPeriod.week, StatsYearScope.allYears, referenceDate, DateTime(2020, 8, 12)),
        isFalse,
        reason: 'one day after the column end in that year',
      );
    });

    test('month + currentYear requires the same year and month', () {
      expect(
        PeriodRangeResolver.matches(
          StatsPeriod.month,
          StatsYearScope.currentYear,
          referenceDate,
          DateTime(2025, 8, 1),
        ),
        isTrue,
      );
      expect(
        PeriodRangeResolver.matches(
          StatsPeriod.month,
          StatsYearScope.currentYear,
          referenceDate,
          DateTime(2024, 8, 1),
        ),
        isFalse,
      );
    });

    test('month + allYears matches the same month in any year', () {
      expect(
        PeriodRangeResolver.matches(StatsPeriod.month, StatsYearScope.allYears, referenceDate, DateTime(2019, 8, 30)),
        isTrue,
      );
    });

    test('year + currentYear requires the same year', () {
      expect(
        PeriodRangeResolver.matches(StatsPeriod.year, StatsYearScope.currentYear, referenceDate, DateTime(2025, 1, 1)),
        isTrue,
      );
      expect(
        PeriodRangeResolver.matches(StatsPeriod.year, StatsYearScope.currentYear, referenceDate, DateTime(2024, 12, 31)),
        isFalse,
      );
    });

    test('year + allYears matches everything', () {
      expect(
        PeriodRangeResolver.matches(StatsPeriod.year, StatsYearScope.allYears, referenceDate, DateTime(2000, 1, 1)),
        isTrue,
      );
    });
  });
}
