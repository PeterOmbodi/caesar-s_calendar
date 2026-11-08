import 'package:caesar_puzzle/application/leaderboard/leaderboard_scoring.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';

sealed class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.nickname,
    required this.colorIndex,
    required this.reachedAt,
    this.expireAt,
  });

  final String uid;
  final String nickname;
  final int colorIndex;
  final DateTime reachedAt;
  final DateTime? expireAt;
}

/// Day board: the first clean solve; lower time ranks higher.
final class DayEntry extends LeaderboardEntry {
  const DayEntry({
    required super.uid,
    required super.nickname,
    required super.colorIndex,
    required super.reachedAt,
    super.expireAt,
    required this.timeMs,
    required this.extraSolutions,
  });

  final int timeMs;
  final int extraSolutions;
}

/// Week, month or year board; more points rank higher.
final class PeriodEntry extends LeaderboardEntry {
  const PeriodEntry({
    required super.uid,
    required super.nickname,
    required super.colorIndex,
    required super.reachedAt,
    super.expireAt,
    required this.points,
    required this.days,
  });

  final int points;
  final int days;
}

class StreakEntry {
  const StreakEntry({
    required this.uid,
    required this.nickname,
    required this.colorIndex,
    required this.best,
    required this.current,
    required this.lastDay,
  });

  final String uid;
  final String nickname;
  final int colorIndex;
  final int best;

  /// As published; it is stale once [lastDay] is before yesterday.
  final int current;
  final DateTime? lastDay;
}

class LeaderboardProfile {
  const LeaderboardProfile({
    required this.nickname,
    required this.nicknameSource,
    required this.colorIndex,
    required this.streaks,
  });

  static const sourceName = 'name';
  static const sourceGenerated = 'generated';

  final String nickname;
  final String nicknameSource;
  final int colorIndex;
  final Map<PuzzleSessionDifficulty, LevelStreak> streaks;
}

class LeaderboardSnapshot {
  const LeaderboardSnapshot({required this.profile, required this.entries});

  final LeaderboardProfile profile;
  final Map<String, LeaderboardEntry> entries;

  /// Changes whenever the published data would change.
  String get key {
    final buffer = StringBuffer('${profile.nickname}|${profile.colorIndex}');
    for (final MapEntry(key: level, value: streak) in profile.streaks.entries) {
      buffer.write('|${level.name}:${streak.best}:${streak.current}:${streak.lastDay}');
    }
    for (final id in entries.keys.toList()..sort()) {
      final entry = entries[id]!;
      final values = switch (entry) {
        DayEntry(:final timeMs, :final extraSolutions) => '$timeMs:$extraSolutions',
        PeriodEntry(:final points, :final days) => '$points:$days',
      };
      buffer.write('|$id:$values:${entry.reachedAt.millisecondsSinceEpoch}');
    }
    return buffer.toString();
  }
}
