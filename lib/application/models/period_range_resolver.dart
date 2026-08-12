import 'package:caesar_puzzle/application/models/stats_period.dart';

class DateRange {
  const DateRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  bool contains(final DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return !day.isBefore(startDay) && !day.isAfter(endDay);
  }

  int get dayCount {
    final startUtc = DateTime.utc(start.year, start.month, start.day);
    final endUtc = DateTime.utc(end.year, end.month, end.day);
    return endUtc.difference(startUtc).inDays + 1;
  }
}

class PeriodRangeResolver {
  const PeriodRangeResolver._();

  static const int _gridTemplateYear = 2024;

  static DateTime referenceDateFor(final DateTime selectedDate, {final DateTime? now}) {
    final year = (now ?? DateTime.now()).year;
    return DateTime(year, selectedDate.month, _clampDay(year, selectedDate.month, selectedDate.day));
  }

  static DateTime _localDateOnly(final DateTime utc) => DateTime(utc.year, utc.month, utc.day);

  static int _lastDayOfMonth(final int year, final int month) => DateTime(year, month + 1, 0).day;

  static int _clampDay(final int year, final int month, final int day) {
    final lastDay = _lastDayOfMonth(year, month);
    return day > lastDay ? lastDay : day;
  }

  static ({int startMonth, int startDay, int endMonth, int endDay}) _weekSlot(final DateTime referenceDate) {
    final templateStart = DateTime.utc(_gridTemplateYear);
    final templateDate = DateTime.utc(_gridTemplateYear, referenceDate.month, referenceDate.day);
    final dayOfYear = templateDate.difference(templateStart).inDays;
    final weekStartUtc = templateStart.add(Duration(days: (dayOfYear ~/ 7) * 7));
    final templateEndUtc = DateTime.utc(_gridTemplateYear, 12, 31);
    final weekEndUtcRaw = weekStartUtc.add(const Duration(days: 6));
    final weekEndUtc = weekEndUtcRaw.isAfter(templateEndUtc) ? templateEndUtc : weekEndUtcRaw;
    return (
      startMonth: weekStartUtc.month,
      startDay: weekStartUtc.day,
      endMonth: weekEndUtc.month,
      endDay: weekEndUtc.day,
    );
  }

  static DateRange weekRangeInYear(final int year, final DateTime referenceDate) {
    final slot = _weekSlot(referenceDate);
    final start = DateTime(year, slot.startMonth, _clampDay(year, slot.startMonth, slot.startDay));
    final end = DateTime(year, slot.endMonth, _clampDay(year, slot.endMonth, slot.endDay));
    return DateRange(start, end);
  }

  static DateRange weekRange(final DateTime referenceDate) => weekRangeInYear(referenceDate.year, referenceDate);

  static DateRange monthRangeInYear(final int year, final int month) => DateRange(
    DateTime(year, month),
    _localDateOnly(DateTime.utc(year, month + 1).subtract(const Duration(days: 1))),
  );

  static DateRange monthRange(final DateTime date) => monthRangeInYear(date.year, date.month);

  static DateRange yearRange(final int year) => DateRange(DateTime(year), DateTime(year, 12, 31));

  static bool matches(
    final StatsPeriod period,
    final StatsYearScope yearScope,
    final DateTime referenceDate,
    final DateTime date,
  ) {
    switch (period) {
      case StatsPeriod.week:
        return switch (yearScope) {
          StatsYearScope.currentYear => weekRange(referenceDate).contains(date),
          StatsYearScope.allYears => weekRangeInYear(date.year, referenceDate).contains(date),
        };
      case StatsPeriod.month:
        return switch (yearScope) {
          StatsYearScope.currentYear => date.year == referenceDate.year && date.month == referenceDate.month,
          StatsYearScope.allYears => date.month == referenceDate.month,
        };
      case StatsPeriod.year:
        return switch (yearScope) {
          StatsYearScope.currentYear => date.year == referenceDate.year,
          StatsYearScope.allYears => true,
        };
    }
  }
}
