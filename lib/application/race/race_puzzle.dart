import 'package:caesar_puzzle/application/leaderboard/day_difficulty.dart';
import 'package:caesar_puzzle/application/models/period_range_resolver.dart';
import 'package:caesar_puzzle/application/race/race_rng.dart';

/// Which dates a room may draw, by their difficulty on the Standard layout.
enum RaceDateTier {
  any(DayDifficulty.minTier, DayDifficulty.maxTier),
  easy(DayDifficulty.minTier, 2),
  hard(4, DayDifficulty.maxTier);

  const RaceDateTier(this.minTier, this.maxTier);

  final int minTier;
  final int maxTier;

  bool allows(final int month, final int day) {
    final tier = DayDifficulty.tier(month, day);
    return tier >= minTier && tier <= maxTier;
  }
}

abstract final class RacePuzzle {
  static const int year = PeriodRangeResolver.gridTemplateYear;

  /// The same for every client of the room, in whatever order it sees the players.
  static int seedOf(final Iterable<int> nonces, final int round) {
    final sorted = [for (final nonce in nonces) nonce & 0xFFFFFFFF]..sort();
    var hash = 0x811C9DC5;
    for (final value in [round, ...sorted]) {
      for (var shift = 0; shift < 32; shift += 8) {
        hash = imul32(hash ^ ((value >>> shift) & 0xFF), 0x01000193);
      }
    }
    return hash;
  }

  /// [serverNow] must be the room's server time, so that every client excludes the same days: the UTC day and
  /// its neighbours, which covers "today" in every time zone.
  static DateTime dateFor(final int seed, final DateTime serverNow, {final RaceDateTier tier = RaceDateTier.any}) {
    final now = serverNow.toUtc();
    final excluded = {
      for (final offset in const [-1, 0, 1]) _key(DateTime.utc(now.year, now.month, now.day + offset)),
    };
    final first = DateTime.utc(year);
    final dates = [
      for (var date = first; date.year == year; date = date.add(const Duration(days: 1)))
        if (!excluded.contains(_key(date)) && tier.allows(date.month, date.day)) date,
    ];
    final picked = dates[RaceRng(seed).nextInt(dates.length)];
    return DateTime(year, picked.month, picked.day);
  }

  static int _key(final DateTime date) => date.month * 100 + date.day;
}
