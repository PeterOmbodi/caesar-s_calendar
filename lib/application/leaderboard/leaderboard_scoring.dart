import 'dart:math' as math;

import 'package:caesar_puzzle/application/leaderboard/day_difficulty.dart';
import 'package:caesar_puzzle/application/models/period_range_resolver.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_status.dart';
import 'package:caesar_puzzle/application/models/solved_solution_record.dart';
import 'package:caesar_puzzle/core/constants/standard_puzzle_config.dart';

class DayResult {
  const DayResult({
    required this.date,
    required this.level,
    required this.timeMs,
    required this.extraSolutions,
    required this.points,
    required this.firstSolvedAt,
    required this.pointsReachedAt,
  });

  final DateTime date;
  final PuzzleSessionDifficulty level;
  final int timeMs;
  final int extraSolutions;
  final int points;
  final DateTime firstSolvedAt;
  final DateTime pointsReachedAt;
}

class PeriodResult {
  const PeriodResult({required this.points, required this.days, required this.reachedAt});

  final int points;
  final int days;
  final DateTime reachedAt;
}

class LevelStreak {
  const LevelStreak({required this.best, required this.current, required this.lastDay});

  static const empty = LevelStreak(best: 0, current: 0, lastDay: null);

  final int best;
  final int current;
  final DateTime? lastDay;
}

/// Leaderboard rules: only the daily puzzle solved on its own date on the Standard layout counts.
class LeaderboardScoring {
  const LeaderboardScoring._();

  static const levels = [PuzzleSessionDifficulty.medium, PuzzleSessionDifficulty.hard];

  static List<DayResult> dayResults(
    final Iterable<PuzzleSessionData> sessions,
    final Iterable<SolvedSolutionRecord> solutions,
  ) {
    final groups = <(DateTime, PuzzleSessionDifficulty), List<PuzzleSessionData>>{};
    for (final session in sessions) {
      if (_isRecord(session) && levels.contains(session.difficulty)) {
        groups.putIfAbsent((_day(session.puzzleDate), session.difficulty), () => []).add(session);
      }
    }
    final solutionsBySession = <String, List<SolvedSolutionRecord>>{};
    for (final solution in solutions) {
      if (solution.configId == StandardPuzzleConfig.id && _sameDay(solution.solvedAt, solution.puzzleDate)) {
        solutionsBySession.putIfAbsent(solution.sessionId, () => []).add(solution);
      }
    }

    final results = <DayResult>[];
    for (final MapEntry(key: (date, level), value: group) in groups.entries) {
      group.sort((final a, final b) => a.completedAt!.compareTo(b.completedAt!));
      final first = group.first;
      final found = [for (final session in group) ...?solutionsBySession[session.id]]
        ..sort((final a, final b) => a.solvedAt.compareTo(b.solvedAt));
      final unique = <String>{};
      var reachedAt = first.completedAt!;
      for (final solution in found) {
        if (unique.length > DayDifficulty.maxExtraSolutions) break;
        if (unique.add(solution.signature)) reachedAt = math.max(reachedAt, solution.solvedAt);
      }
      final extra = math.min(math.max(unique.length - 1, 0), DayDifficulty.maxExtraSolutions);
      results.add(
        DayResult(
          date: date,
          level: level,
          timeMs: first.activeElapsedMs,
          extraSolutions: extra,
          points: DayDifficulty.dayPoints(tier: DayDifficulty.tier(date.month, date.day), extraSolutions: extra),
          firstSolvedAt: DateTime.fromMillisecondsSinceEpoch(first.completedAt!),
          pointsReachedAt: DateTime.fromMillisecondsSinceEpoch(reachedAt),
        ),
      );
    }
    results.sort((final a, final b) => a.date.compareTo(b.date));
    return results;
  }

  static PeriodResult? periodResult(
    final Iterable<DayResult> days,
    final PuzzleSessionDifficulty level,
    final DateRange range,
  ) {
    final inPeriod = days.where((final d) => d.level == level && range.contains(d.date)).toList();
    if (inPeriod.isEmpty) return null;
    return PeriodResult(
      points: inPeriod.fold(0, (final sum, final d) => sum + d.points),
      days: inPeriod.length,
      reachedAt: inPeriod.map((final d) => d.pointsReachedAt).reduce((final a, final b) => a.isAfter(b) ? a : b),
    );
  }

  /// Cumulative: Hard counts Hard days, Medium counts Medium and Hard. Hints break both.
  static Map<PuzzleSessionDifficulty, LevelStreak> streaks(
    final Iterable<PuzzleSessionData> sessions, {
    required final DateTime today,
  }) {
    final bestRankByDay = <DateTime, int>{};
    for (final session in sessions) {
      if (!_countsForLeaderboard(session)) continue;
      final rank = session.isClean ? session.difficulty.assistRank : PuzzleSessionDifficulty.easy.assistRank;
      final day = _day(session.puzzleDate);
      bestRankByDay[day] = math.min(bestRankByDay[day] ?? rank, rank);
    }
    return {
      for (final level in levels)
        level: _streak({
          for (final MapEntry(key: day, value: rank) in bestRankByDay.entries)
            if (rank <= level.assistRank) day,
        }, _day(today)),
    };
  }

  static LevelStreak _streak(final Set<DateTime> days, final DateTime today) {
    if (days.isEmpty) return LevelStreak.empty;
    final sorted = days.toList()..sort();
    var best = 1;
    var run = 1;
    for (var i = 1; i < sorted.length; i++) {
      run = _daysBetween(sorted[i - 1], sorted[i]) == 1 ? run + 1 : 1;
      best = math.max(best, run);
    }
    final last = sorted.last;
    final alive = _daysBetween(last, today) <= 1;
    return LevelStreak(best: best, current: alive ? run : 0, lastDay: last);
  }

  static bool _countsForLeaderboard(final PuzzleSessionData session) =>
      session.status == PuzzleSessionStatus.solved &&
      session.configId == StandardPuzzleConfig.id &&
      session.completedAt != null &&
      _sameDay(session.completedAt!, session.puzzleDate);

  static bool _isRecord(final PuzzleSessionData session) => _countsForLeaderboard(session) && session.isClean;

  static bool _sameDay(final int timestampMs, final DateTime date) {
    final local = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    return local.year == date.year && local.month == date.month && local.day == date.day;
  }

  static DateTime _day(final DateTime date) => DateTime(date.year, date.month, date.day);

  static int _daysBetween(final DateTime a, final DateTime b) =>
      DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
}
