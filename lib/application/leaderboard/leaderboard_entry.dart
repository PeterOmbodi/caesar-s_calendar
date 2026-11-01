import 'package:caesar_puzzle/application/leaderboard/leaderboard_scoring.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';

/// Day boards: [score] is the time in ms (lower is better), [secondary] the extra solutions.
/// Period boards: [score] is points (higher is better), [secondary] the solved days.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.nickname,
    required this.colorIndex,
    required this.score,
    required this.secondary,
    required this.reachedAt,
    this.expireAt,
  });

  final String uid;
  final String nickname;
  final int colorIndex;
  final int score;
  final int secondary;
  final DateTime reachedAt;
  final DateTime? expireAt;
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

  final String nickname;
  final String nicknameSource;
  final int colorIndex;
  final Map<PuzzleSessionDifficulty, LevelStreak> streaks;
}

/// Everything one player publishes, keyed by board id.
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
      buffer.write('|$id:${entry.score}:${entry.secondary}:${entry.reachedAt.millisecondsSinceEpoch}');
    }
    return buffer.toString();
  }
}
