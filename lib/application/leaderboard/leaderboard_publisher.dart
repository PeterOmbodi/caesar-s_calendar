import 'package:caesar_puzzle/application/contracts/puzzle_history_repository.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_entry.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_period.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_scoring.dart';
import 'package:caesar_puzzle/application/leaderboard/nickname_generator.dart';
import 'package:injectable/injectable.dart';

/// Builds what a player publishes for the current day, week, month and year.
@lazySingleton
class LeaderboardPublisher {
  LeaderboardPublisher(this._history);

  static const _dayEntryLifetime = Duration(days: 30);
  static const _weekEntryLifetime = Duration(days: 365);
  static const _minDayTimeMs = 10000;
  static const _maxDayTimeMs = 24 * 60 * 60 * 1000;

  final PuzzleHistoryRepository _history;

  /// Profile with zero streaks and no entries, valid for the security rules.
  LeaderboardSnapshot emptySnapshot({required final String uid, required final String? displayName}) =>
      LeaderboardSnapshot(
        profile: LeaderboardProfile(
          nickname: NicknameGenerator.nickname(uid: uid, displayName: displayName),
          nicknameSource: 'generated',
          colorIndex: NicknameGenerator.colorIndex(uid),
          streaks: {for (final level in LeaderboardScoring.levels) level: LevelStreak.empty},
        ),
        entries: const {},
      );

  Future<LeaderboardSnapshot> build({
    required final String uid,
    required final String? displayName,
    required final DateTime now,
  }) async {
    final today = DateTime(now.year, now.month, now.day);
    final yearStart = DateTime(today.year);
    final sessions = await _history.watchSessionsInPuzzleDateRange(from: DateTime(2000), to: today).first;
    final solutions = await _history.getSolvedSolutions(from: yearStart, to: today);
    final days = LeaderboardScoring.dayResults(
      sessions.where((final s) => !s.puzzleDate.isBefore(yearStart)),
      solutions,
    );

    final nickname = NicknameGenerator.nickname(uid: uid, displayName: displayName);
    final colorIndex = NicknameGenerator.colorIndex(uid);
    LeaderboardEntry entry(
      final int score,
      final int secondary,
      final DateTime reachedAt, [
      final DateTime? expireAt,
    ]) => LeaderboardEntry(
      uid: uid,
      nickname: nickname,
      colorIndex: colorIndex,
      score: score,
      secondary: secondary,
      reachedAt: reachedAt,
      expireAt: expireAt,
    );

    final entries = <String, LeaderboardEntry>{};
    for (final level in LeaderboardScoring.levels) {
      for (final day in days) {
        if (day.level == level && day.date == today && day.timeMs >= _minDayTimeMs && day.timeMs <= _maxDayTimeMs) {
          entries[LeaderboardKeys.board(LeaderboardPeriod.today, today, level)] = entry(
            day.timeMs,
            day.extraSolutions,
            day.firstSolvedAt,
            today.add(_dayEntryLifetime),
          );
        }
      }
      for (final period in [LeaderboardPeriod.week, LeaderboardPeriod.month, LeaderboardPeriod.year]) {
        final result = LeaderboardScoring.periodResult(days, level, LeaderboardKeys.range(period, today));
        if (result == null) continue;
        entries[LeaderboardKeys.board(period, today, level)] = entry(
          result.points,
          result.days,
          result.reachedAt,
          period == LeaderboardPeriod.week ? today.add(_weekEntryLifetime) : null,
        );
      }
    }

    return LeaderboardSnapshot(
      profile: LeaderboardProfile(
        nickname: nickname,
        nicknameSource: 'generated',
        colorIndex: colorIndex,
        streaks: LeaderboardScoring.streaks(sessions, today: today),
      ),
      entries: entries,
    );
  }
}
