import 'package:caesar_puzzle/application/contracts/puzzle_history_repository.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_entry.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_period.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_scoring.dart';
import 'package:caesar_puzzle/application/leaderboard/nickname_generator.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:injectable/injectable.dart';

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
        profile: _profile(uid, displayName, {for (final level in LeaderboardScoring.levels) level: LevelStreak.empty}),
        entries: const {},
      );

  /// [displayName] is null when the player hides the name.
  static LeaderboardProfile _profile(
    final String uid,
    final String? displayName,
    final Map<PuzzleSessionDifficulty, LevelStreak> streaks,
  ) {
    final fromName = NicknameGenerator.fromName(displayName);
    return LeaderboardProfile(
      nickname: fromName ?? NicknameGenerator.fromUid(uid),
      nicknameSource: fromName == null ? LeaderboardProfile.sourceGenerated : LeaderboardProfile.sourceName,
      colorIndex: NicknameGenerator.colorIndex(uid),
      streaks: streaks,
    );
  }

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

    final profile = _profile(uid, displayName, LeaderboardScoring.streaks(sessions, today: today));

    final entries = <String, LeaderboardEntry>{};
    for (final level in LeaderboardScoring.levels) {
      for (final day in days) {
        if (day.level == level && day.date == today && day.timeMs >= _minDayTimeMs && day.timeMs <= _maxDayTimeMs) {
          entries[LeaderboardKeys.board(LeaderboardPeriod.today, today, level)] = DayEntry(
            uid: uid,
            nickname: profile.nickname,
            colorIndex: profile.colorIndex,
            reachedAt: day.firstSolvedAt,
            expireAt: today.add(_dayEntryLifetime),
            timeMs: day.timeMs,
            extraSolutions: day.extraSolutions,
          );
        }
      }
      for (final period in [LeaderboardPeriod.week, LeaderboardPeriod.month, LeaderboardPeriod.year]) {
        final result = LeaderboardScoring.periodResult(days, level, LeaderboardKeys.range(period, today));
        if (result == null) continue;
        entries[LeaderboardKeys.board(period, today, level)] = PeriodEntry(
          uid: uid,
          nickname: profile.nickname,
          colorIndex: profile.colorIndex,
          reachedAt: result.reachedAt,
          expireAt: period == LeaderboardPeriod.week ? today.add(_weekEntryLifetime) : null,
          points: result.points,
          days: result.days,
        );
      }
    }

    return LeaderboardSnapshot(profile: profile, entries: entries);
  }
}
