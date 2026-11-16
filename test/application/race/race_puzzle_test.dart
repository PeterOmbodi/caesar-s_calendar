import 'package:caesar_puzzle/application/leaderboard/day_difficulty.dart';
import 'package:caesar_puzzle/application/race/race_entitlements.dart';
import 'package:caesar_puzzle/application/race/race_puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 11, 13, 17);

  group('seedOf', () {
    test('reference values', () {
      expect(RacePuzzle.seedOf([123456789, 987654321], 1), 433851801);
      expect(RacePuzzle.seedOf([4294967295, 0], 1), 2987894560);
    });

    test('does not depend on the order of players, depends on the round', () {
      expect(RacePuzzle.seedOf([987654321, 123456789], 1), RacePuzzle.seedOf([123456789, 987654321], 1));
      expect(RacePuzzle.seedOf([123456789, 987654321], 2), 110524554);
    });
  });

  group('dateFor', () {
    test('fixed seeds give fixed dates', () {
      expect(RacePuzzle.dateFor(0, now), DateTime(2024, 4, 6));
      expect(RacePuzzle.dateFor(1, now), DateTime(2024, 8, 15));
      expect(RacePuzzle.dateFor(0xDEADBEEF, now), DateTime(2024, 12, 10));
      expect(RacePuzzle.dateFor(433851801, now), DateTime(2024, 12, 18));
    });

    test('same date for clients in different time zones', () {
      final local = DateTime.fromMillisecondsSinceEpoch(now.millisecondsSinceEpoch);
      expect(RacePuzzle.dateFor(1, local), RacePuzzle.dateFor(1, now));
    });

    test('never today, in any time zone', () {
      final banned = {(11, 12), (11, 13), (11, 14)};
      final newYear = {(12, 30), (12, 31), (1, 1)};
      for (var seed = 0; seed < 5000; seed++) {
        final date = RacePuzzle.dateFor(seed * 7919, now);
        expect(banned, isNot(contains((date.month, date.day))), reason: 'seed $seed');
        final atNewYear = RacePuzzle.dateFor(seed * 7919, DateTime.utc(2026, 12, 31, 23));
        expect(newYear, isNot(contains((atNewYear.month, atNewYear.day))), reason: 'seed $seed');
      }
    });

    test('every other date of the year can come up, February 29 included', () {
      final seen = <(int, int)>{};
      for (var seed = 0; seed < 20000; seed++) {
        final date = RacePuzzle.dateFor(seed * 7919, now);
        seen.add((date.month, date.day));
      }
      expect(seen, hasLength(363));
      expect(seen, contains((2, 29)));
    });

    test('tier limits the difficulty of the date', () {
      for (var seed = 0; seed < 500; seed++) {
        final easy = RacePuzzle.dateFor(seed * 7919, now, tier: RaceDateTier.easy);
        final hard = RacePuzzle.dateFor(seed * 7919, now, tier: RaceDateTier.hard);
        expect(DayDifficulty.tier(easy.month, easy.day), lessThanOrEqualTo(2));
        expect(DayDifficulty.tier(hard.month, hard.day), greaterThanOrEqualTo(4));
      }
    });
  });

  test('a duel is two players', () {
    expect(RaceEntitlements.duel.maxPlayers, 2);
  });
}
