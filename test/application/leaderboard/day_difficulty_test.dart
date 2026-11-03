import 'package:caesar_puzzle/application/leaderboard/day_difficulty.dart';
import 'package:caesar_puzzle/application/leaderboard/standard_day_solutions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('table covers every date of a leap year', () {
    expect(standardDaySolutions, hasLength(366));
    expect(standardDaySolutions.every((final count) => count > 0), isTrue);
    expect(DayDifficulty.solutionCount(2, 29), greaterThan(0));
    expect(DayDifficulty.solutionCount(12, 31), standardDaySolutions.last);
  });

  test('known dates', () {
    expect(DayDifficulty.solutionCount(10, 8), 50);
    expect(DayDifficulty.tier(10, 8), 4);
    expect(DayDifficulty.tier(10, 6), 5);
    expect(DayDifficulty.tier(1, 25), 1);
  });

  test('tiers split the year into roughly equal parts', () {
    final sizes = <int, int>{};
    for (var date = DateTime.utc(2024); date.year == 2024; date = date.add(const Duration(days: 1))) {
      final tier = DayDifficulty.tier(date.month, date.day);
      sizes[tier] = (sizes[tier] ?? 0) + 1;
    }
    expect(sizes.keys.toSet(), {1, 2, 3, 4, 5});
    for (final size in sizes.values) {
      expect(size, inInclusiveRange(60, 90));
    }
  });

  test('day points grow with the tier and cap extra solutions', () {
    final firstSolve = [for (var tier = 1; tier <= 5; tier++) DayDifficulty.dayPoints(tier: tier, extraSolutions: 0)];
    expect(firstSolve, [10, 12, 14, 17, 20]);
    expect(DayDifficulty.dayPoints(tier: 5, extraSolutions: 25), DayDifficulty.maxDayPoints);
    expect(DayDifficulty.maxDayPoints, 30);
  });
}
