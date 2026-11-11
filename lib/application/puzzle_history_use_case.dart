import 'dart:async';

import 'package:caesar_puzzle/application/contracts/puzzle_history_repository.dart';
import 'package:caesar_puzzle/application/models/achievement_stats.dart';
import 'package:caesar_puzzle/application/models/calendar_day_stats.dart';
import 'package:caesar_puzzle/application/models/period_range_resolver.dart';
import 'package:caesar_puzzle/application/models/period_stats.dart';
import 'package:caesar_puzzle/application/models/puzzle_history_input.dart';
import 'package:caesar_puzzle/application/models/puzzle_piece_snapshot.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_status.dart';
import 'package:caesar_puzzle/application/models/stats_period.dart';
import 'package:caesar_puzzle/application/puzzle_config_json.dart';
import 'package:caesar_puzzle/core/constants/standard_puzzle_config.dart';
import 'package:caesar_puzzle/core/models/move.dart';
import 'package:caesar_puzzle/core/models/placement.dart';
import 'package:caesar_puzzle/core/utils/combine_latest.dart';
import 'package:caesar_puzzle/infrastructure/sync/sync_runner.dart';
import 'package:caesar_puzzle/injection.dart';
import 'package:injectable/injectable.dart';

@LazySingleton()
class PuzzleHistoryUseCase {
  PuzzleHistoryUseCase(this._historyRepository);

  final PuzzleHistoryRepository _historyRepository;

  String? _currentSessionId;
  int? _currentSessionStartedAt;
  PuzzleSessionDifficulty? _currentSessionDifficulty;
  bool _currentSessionLockedAfterSolved = false;

  void resetSession() {
    _currentSessionId = null;
    _currentSessionStartedAt = null;
    _currentSessionDifficulty = null;
    _currentSessionLockedAfterSolved = false;
  }

  void activateSession(final PuzzleSessionData session) {
    _currentSessionId = session.id;
    _currentSessionStartedAt = session.startedAt;
    _currentSessionDifficulty = session.difficulty;
    _currentSessionLockedAfterSolved = session.status == PuzzleSessionStatus.solved || session.completedAt != null;
  }

  void setCurrentSessionDifficulty(final PuzzleSessionDifficulty difficulty) {
    _currentSessionDifficulty = _coalesceDifficulty(_currentSessionDifficulty, difficulty);
  }

  void markCurrentSessionDifficulty(final PuzzleSessionDifficulty difficulty) {
    _currentSessionDifficulty = _coalesceDifficulty(_currentSessionDifficulty, difficulty);
  }

  Future<void> markPuzzleAssisted({
    required final DateTime puzzleDate,
    required final List<PlacementParams> configPlacements,
  }) async => _historyRepository.markPuzzleAssisted(
    puzzleDate: puzzleDate,
    configId: await _configId(configPlacements),
  );

  Future<bool> isPuzzleAssisted({
    required final DateTime puzzleDate,
    required final List<PlacementParams> configPlacements,
  }) async => _historyRepository.isPuzzleAssisted(
    puzzleDate: puzzleDate,
    configId: await _configId(configPlacements),
  );

  Future<String> _configId(final List<PlacementParams> configPlacements) =>
      _historyRepository.upsertConfig(configJson: PuzzleConfigJson.encode(configPlacements));

  Stream<List<CalendarDayStats>> watchCalendarStats(final DateTime from, final DateTime to) =>
      _historyRepository.watchCalendarStats(from: from, to: to);

  Stream<List<PuzzleSessionData>> watchSessionsByDate(final DateTime date) =>
      _historyRepository.watchSessionsByDate(puzzleDate: DateTime(date.year, date.month, date.day));

  Stream<List<PuzzleSessionData>> watchSessionsByMonthDay(final DateTime date) =>
      _historyRepository.watchSessionsByMonthDay(puzzleDate: DateTime(date.year, date.month, date.day));

  static final DateTime _historyRangeStart = DateTime(2020);
  static final DateTime _historyRangeEnd = DateTime(2100, 12, 31);

  Stream<PeriodStats> watchPeriodStats({
    required final StatsPeriod period,
    required final StatsYearScope yearScope,
    required final DateTime referenceDate,
  }) {
    final queryRange = _queryRangeFor(period, yearScope, referenceDate);
    return _historyRepository
        .watchSessionsInPuzzleDateRange(from: queryRange.start, to: queryRange.end)
        .map((final sessions) => _aggregatePeriodStats(sessions, period, yearScope, referenceDate));
  }

  Stream<AchievementStats> watchAchievements() => combineLatest2(
    _historyRepository.watchSessionsInPuzzleDateRange(from: _historyRangeStart, to: _historyRangeEnd),
    _historyRepository.watchSolvedSolutionCount(),
    _aggregateAchievements,
  );

  /// Block placements the session was played with; null if its config is not stored locally.
  Future<List<PlacementParams>?> sessionLayout(final PuzzleSessionData session) async {
    if (session.configId == StandardPuzzleConfig.id) {
      return PuzzleConfigJson.standardPlacements;
    }
    final json = await _historyRepository.getConfigJson(session.configId);
    return json == null ? null : PuzzleConfigJson.decode(json);
  }

  AchievementStats _aggregateAchievements(final List<PuzzleSessionData> sessions, final int solutionsFound) {
    final solved = sessions.where((final s) => s.status == PuzzleSessionStatus.solved).toList();
    final clean = solved.where((final s) => s.isClean).toList();
    final levelByDate = <(int, int), PuzzleSessionDifficulty>{};
    int? fastestMs;
    int? firstSolvedAt;
    for (final session in solved) {
      final date = (session.puzzleDate.month, session.puzzleDate.day);
      final level = session.isClean ? session.difficulty : PuzzleSessionDifficulty.easy;
      final best = levelByDate[date];
      if (best == null || level.assistRank < best.assistRank) {
        levelByDate[date] = level;
      }
      final elapsed = session.activeElapsedMs;
      if (session.isClean && elapsed > 0 && (fastestMs == null || elapsed < fastestMs)) {
        fastestMs = elapsed;
      }
      final completedAt = session.completedAt;
      if (completedAt != null && (firstSolvedAt == null || completedAt < firstSolvedAt)) {
        firstSolvedAt = completedAt;
      }
    }
    return AchievementStats(
      solvedDates: levelByDate,
      solvedHard: clean.where((final s) => s.difficulty == PuzzleSessionDifficulty.hard).length,
      bestStreakDays: _longestRunInRangeByMonthDay(_streakDays(clean), PeriodRangeResolver.gridTemplateYearRange),
      solutionsFound: solutionsFound,
      fastestSolveMs: fastestMs,
      cleanSolves: clean.length,
      customLayoutSolves: solved.where((final s) => s.configId != StandardPuzzleConfig.id).length,
      firstSolvedAt: firstSolvedAt == null ? null : DateTime.fromMillisecondsSinceEpoch(firstSolvedAt),
    );
  }

  DateRange _queryRangeFor(final StatsPeriod period, final StatsYearScope yearScope, final DateTime referenceDate) {
    if (yearScope == StatsYearScope.allYears) {
      return DateRange(_historyRangeStart, _historyRangeEnd);
    }
    return switch (period) {
      StatsPeriod.week => PeriodRangeResolver.weekRange(referenceDate),
      StatsPeriod.month => PeriodRangeResolver.monthRange(referenceDate),
      StatsPeriod.year => PeriodRangeResolver.yearRange(referenceDate.year),
    };
  }

  PeriodStats _aggregatePeriodStats(
    final List<PuzzleSessionData> sessions,
    final StatsPeriod period,
    final StatsYearScope yearScope,
    final DateTime referenceDate,
  ) {
    var started = 0;
    var solved = 0;
    var solvedHard = 0;
    var hintsUsed = 0;
    var totalTimePlayedMs = 0;
    var totalMovesSolved = 0;
    final solvedDays = <DateTime>{};
    final streakDays = <DateTime>{};

    for (final session in sessions) {
      if (!PeriodRangeResolver.matches(period, yearScope, referenceDate, session.puzzleDate)) {
        continue;
      }
      if (session.firstMoveAt != null) {
        started += 1;
        hintsUsed += session.moveHistory.whereType<HintMove>().length;
        totalTimePlayedMs += session.activeElapsedMs;
      }
      if (session.status == PuzzleSessionStatus.solved) {
        solved += 1;
        totalMovesSolved += session.moveIndex;
        if (session.isClean && session.difficulty == PuzzleSessionDifficulty.hard) {
          solvedHard += 1;
        }
        solvedDays.add(session.puzzleDate);
        if (session.isClean && _solvedOnItsDay(session)) {
          streakDays.add(session.puzzleDate);
        }
      }
    }

    return PeriodStats(
      started: started,
      solved: solved,
      solvedHard: solvedHard,
      solvedDays: solvedDays.length,
      bestStreakDays: _bestStreak(streakDays, period, yearScope, referenceDate),
      hintsUsed: hintsUsed,
      totalTimePlayedMs: totalTimePlayedMs,
      totalMovesSolved: totalMovesSolved,
    );
  }

  static Set<DateTime> _streakDays(final Iterable<PuzzleSessionData> solved) => {
    for (final session in solved)
      if (_solvedOnItsDay(session)) session.puzzleDate,
  };

  static bool _solvedOnItsDay(final PuzzleSessionData session) {
    final completedAt = session.completedAt;
    if (completedAt == null) return false;
    final completed = DateTime.fromMillisecondsSinceEpoch(completedAt);
    final date = session.puzzleDate;
    return completed.year == date.year && completed.month == date.month && completed.day == date.day;
  }

  int _bestStreak(
    final Set<DateTime> solvedDays,
    final StatsPeriod period,
    final StatsYearScope yearScope,
    final DateTime referenceDate,
  ) {
    if (solvedDays.isEmpty) {
      return 0;
    }
    if (yearScope == StatsYearScope.currentYear) {
      final range = switch (period) {
        StatsPeriod.week => PeriodRangeResolver.weekRange(referenceDate),
        StatsPeriod.month => PeriodRangeResolver.monthRange(referenceDate),
        StatsPeriod.year => PeriodRangeResolver.yearRange(referenceDate.year),
      };
      return _longestRunInRange(solvedDays, range);
    }
    const gridYear = PeriodRangeResolver.gridTemplateYear;
    final range = switch (period) {
      StatsPeriod.week => PeriodRangeResolver.weekRangeInYear(gridYear, referenceDate),
      StatsPeriod.month => PeriodRangeResolver.monthRangeInYear(gridYear, referenceDate.month),
      StatsPeriod.year => PeriodRangeResolver.gridTemplateYearRange,
    };
    return _longestRunInRangeByMonthDay(solvedDays, range);
  }

  int _longestRunInRange(final Set<DateTime> solvedDays, final DateRange range) {
    final startUtc = DateTime.utc(range.start.year, range.start.month, range.start.day);
    final endUtc = DateTime.utc(range.end.year, range.end.month, range.end.day);
    final totalDays = endUtc.difference(startUtc).inDays;

    var longest = 0;
    var current = 0;
    for (var offset = 0; offset <= totalDays; offset++) {
      final utcDay = startUtc.add(Duration(days: offset));
      final localDay = DateTime(utcDay.year, utcDay.month, utcDay.day);
      if (solvedDays.contains(localDay)) {
        current += 1;
        longest = current > longest ? current : longest;
      } else {
        current = 0;
      }
    }
    return longest;
  }

  int _longestRunInRangeByMonthDay(final Set<DateTime> solvedDays, final DateRange range) {
    final solvedMonthDays = solvedDays.map((final date) => (date.month, date.day)).toSet();
    final startUtc = DateTime.utc(range.start.year, range.start.month, range.start.day);
    final endUtc = DateTime.utc(range.end.year, range.end.month, range.end.day);
    final totalDays = endUtc.difference(startUtc).inDays;

    var longest = 0;
    var current = 0;
    for (var offset = 0; offset <= totalDays; offset++) {
      final utcDay = startUtc.add(Duration(days: offset));
      if (solvedMonthDays.contains((utcDay.month, utcDay.day))) {
        current += 1;
        longest = current > longest ? current : longest;
      } else {
        current = 0;
      }
    }
    return longest;
  }

  void persistAfterChange(final PuzzleHistoryInput input) {
    if (_currentSessionLockedAfterSolved) {
      return;
    }
    if (!input.shouldPersist) {
      return;
    }
    if (input.isSolved) {
      _currentSessionLockedAfterSolved = true;
    }
    unawaited(
      _persistSession(
        selectedDate: input.selectedDate,
        moveHistory: input.moveHistory,
        moveIndex: input.moveIndex,
        firstMoveAt: input.firstMoveAt,
        lastResumedAt: input.lastResumedAt,
        activeElapsedMs: input.activeElapsedMs,
        isSolved: input.isSolved,
        difficulty: input.difficulty,
        configPlacements: input.configPlacements,
        piecesSnapshot: input.piecesSnapshot,
        solutions: input.solutions,
        applicableSolutions: input.applicableSolutions,
        solvedTransition: input.solvedTransition,
      ),
    );
  }

  Future<void> _persistSession({
    required final DateTime selectedDate,
    required final List<Move> moveHistory,
    required final int moveIndex,
    required final int? firstMoveAt,
    required final int? lastResumedAt,
    required final int activeElapsedMs,
    required final bool isSolved,
    required final PuzzleSessionDifficulty difficulty,
    required final List<PlacementParams> configPlacements,
    required final List<PuzzlePieceSnapshot> piecesSnapshot,
    required final List<Map<String, PlacementParams>> solutions,
    required final List<Map<String, PlacementParams>> applicableSolutions,
    required final bool solvedTransition,
  }) async {
    final configJson = PuzzleConfigJson.encode(configPlacements);
    final configId = await _historyRepository.upsertConfig(configJson: configJson);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final startedAt = _currentSessionStartedAt ?? nowMs;
    _currentSessionStartedAt ??= startedAt;
    final sessionDifficulty = _coalesceDifficulty(_currentSessionDifficulty, difficulty);
    _currentSessionDifficulty = sessionDifficulty;

    final created = _currentSessionId == null;
    final sessionId =
        _currentSessionId ??
        await _historyRepository.createSession(
          PuzzleSessionData(
            id: '',
            puzzleDate: selectedDate,
            configId: configId,
            difficulty: sessionDifficulty,
            status: isSolved ? PuzzleSessionStatus.solved : PuzzleSessionStatus.unsolved,
            startedAt: startedAt,
            firstMoveAt: firstMoveAt,
            lastResumedAt: lastResumedAt,
            activeElapsedMs: activeElapsedMs,
            updatedAt: nowMs,
            completedAt: isSolved ? nowMs : null,
            moveIndex: moveIndex,
            moveHistoryVersion: 1,
            pieces: piecesSnapshot,
            moveHistory: moveHistory,
          ),
        );
    _currentSessionId ??= sessionId;

    if (!created) {
      await _historyRepository.updateSession(
        PuzzleSessionData(
          id: sessionId,
          puzzleDate: selectedDate,
          configId: configId,
          difficulty: sessionDifficulty,
          status: isSolved ? PuzzleSessionStatus.solved : PuzzleSessionStatus.unsolved,
          startedAt: startedAt,
          firstMoveAt: firstMoveAt,
          lastResumedAt: lastResumedAt,
          activeElapsedMs: activeElapsedMs,
          updatedAt: nowMs,
          completedAt: isSolved ? nowMs : null,
          moveIndex: moveIndex,
          moveHistoryVersion: 1,
          pieces: piecesSnapshot,
          moveHistory: moveHistory,
        ),
      );
    }

    if (solvedTransition) {
      final signatures = _solutionSignatures(applicableSolutions: applicableSolutions, solutions: solutions);
      await _historyRepository.markSessionSolved(
        sessionId: sessionId,
        puzzleDate: selectedDate,
        configId: configId,
        solutionSignatures: signatures,
        completedAt: DateTime.now(),
      );
      getIt<SyncRunner>()
        ..requestSync()
        ..publishProfileNow();
    }
  }

  List<String> _solutionSignatures({
    required final List<Map<String, PlacementParams>> solutions,
    required final List<Map<String, PlacementParams>> applicableSolutions,
  }) {
    final source = applicableSolutions.isNotEmpty ? applicableSolutions : solutions;
    return source.map(_signatureFromSolution).toList();
  }

  String _signatureFromSolution(final Map<String, PlacementParams> solution) {
    final entries = solution.entries.toList()..sort((final a, final b) => a.key.compareTo(b.key));
    return entries
        .map(
          (final entry) =>
              '${entry.key}:${entry.value.row}:${entry.value.col}:${entry.value.rotationSteps}:${entry.value.isFlipped ? 1 : 0}',
        )
        .join('|');
  }

  PuzzleSessionDifficulty _coalesceDifficulty(
    final PuzzleSessionDifficulty? previous,
    final PuzzleSessionDifficulty incoming,
  ) {
    if (previous == null) {
      return incoming;
    }
    return previous.assistRank >= incoming.assistRank ? previous : incoming;
  }
}
