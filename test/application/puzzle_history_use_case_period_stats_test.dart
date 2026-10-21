import 'dart:async';

import 'package:caesar_puzzle/application/contracts/puzzle_history_repository.dart';
import 'package:caesar_puzzle/application/models/calendar_day_stats.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_status.dart';
import 'package:caesar_puzzle/application/models/stats_period.dart';
import 'package:caesar_puzzle/application/puzzle_history_use_case.dart';
import 'package:caesar_puzzle/core/models/move.dart';
import 'package:caesar_puzzle/core/models/position.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePuzzleHistoryRepository implements PuzzleHistoryRepository {
  _FakePuzzleHistoryRepository(this.sessions, {final Stream<int>? solutionCount})
    : solutionCount = solutionCount ?? Stream.value(0);

  final List<PuzzleSessionData> sessions;
  final Stream<int> solutionCount;

  @override
  Stream<List<PuzzleSessionData>> watchSessionsInPuzzleDateRange({
    required final DateTime from,
    required final DateTime to,
  }) => Stream.value(sessions);

  @override
  Future<void> clearLocalData() async {}

  @override
  Future<String> createSession(final PuzzleSessionData session) async => 'session-id';

  @override
  Future<PuzzleSessionData?> getLatestUnsolvedSession({required final DateTime puzzleDate}) async => null;

  @override
  Future<bool> hasAnyLocalSessions() async => false;

  @override
  Stream<int> watchSolvedSolutionCount() => solutionCount;

  @override
  Future<String?> getConfigJson(final String configId) async => null;

  @override
  Future<void> markSessionSolved({
    required final String sessionId,
    required final DateTime puzzleDate,
    required final String configId,
    required final Iterable<String> solutionSignatures,
    final DateTime? completedAt,
  }) async {}

  @override
  Future<void> updateSession(final PuzzleSessionData session) async {}

  @override
  Future<void> upsertSolutionCount({
    required final DateTime puzzleDate,
    required final String configId,
    required final int totalSolutions,
    final DateTime? computedAt,
  }) async {}

  @override
  Future<String> upsertConfig({required final String configJson, final DateTime? createdAt}) async => 'cfg';

  @override
  Stream<List<CalendarDayStats>> watchCalendarStats({required final DateTime from, required final DateTime to}) =>
      const Stream.empty();

  @override
  Stream<List<PuzzleSessionData>> watchSessionsByDate({required final DateTime puzzleDate}) => const Stream.empty();

  @override
  Stream<List<PuzzleSessionData>> watchSessionsByMonthDay({required final DateTime puzzleDate}) =>
      const Stream.empty();
}

int _sessionCounter = 0;

final _defaultRealTimestamp = DateTime(2000, 1, 1);

PuzzleSessionData _session({
  required final DateTime puzzleDate,
  final bool solved = false,
  final bool started = true,
  final PuzzleSessionDifficulty difficulty = PuzzleSessionDifficulty.medium,
  final int hints = 0,
  final DateTime? startedAt,
  final DateTime? completedAt,
  final int activeElapsedMs = 0,
  final int moveIndex = 0,
}) {
  _sessionCounter += 1;
  final effectiveStartedAt = startedAt ?? _defaultRealTimestamp;
  final effectiveCompletedAt = solved ? (completedAt ?? _defaultRealTimestamp) : null;
  return PuzzleSessionData(
    id: 'session-$_sessionCounter',
    puzzleDate: puzzleDate,
    configId: 'cfg',
    difficulty: difficulty,
    status: solved ? PuzzleSessionStatus.solved : PuzzleSessionStatus.unsolved,
    startedAt: effectiveStartedAt.millisecondsSinceEpoch,
    firstMoveAt: started ? effectiveStartedAt.millisecondsSinceEpoch : null,
    lastResumedAt: null,
    activeElapsedMs: activeElapsedMs,
    updatedAt: effectiveStartedAt.millisecondsSinceEpoch,
    completedAt: effectiveCompletedAt?.millisecondsSinceEpoch,
    moveIndex: moveIndex,
    moveHistoryVersion: 1,
    pieces: const [],
    moveHistory: List.generate(hints, (_) => _hintMove()),
  );
}

Move _hintMove() => HintMove(
  'piece',
  from: MovePlacement(position: const Position.zero()),
  to: MovePlacement(position: const Position.zero()),
  rotationFrom: 0,
  rotationTo: 0,
  flippedFrom: false,
  flippedTo: false,
);

void main() {
  group('watchPeriodStats: week + currentYear', () {
    test('counts started/solved/solvedHard/solvedDays/hints and excludes sessions outside the week', () async {
      final referenceDate = DateTime(2025, 8, 6);
      final sessions = [
        _session(
          puzzleDate: DateTime(2025, 8, 6),
          solved: true,
          difficulty: PuzzleSessionDifficulty.hard,
          hints: 2,
          activeElapsedMs: 60000,
          moveIndex: 20,
        ),
        _session(puzzleDate: DateTime(2025, 8, 7), hints: 1, activeElapsedMs: 30000, moveIndex: 5),
        _session(
          puzzleDate: DateTime(2025, 8, 7),
          solved: true,
          difficulty: PuzzleSessionDifficulty.easy,
          activeElapsedMs: 90000,
          moveIndex: 10,
        ),
        _session(puzzleDate: DateTime(2025, 7, 30), hints: 5, activeElapsedMs: 999999, moveIndex: 999),
      ];
      final useCase = PuzzleHistoryUseCase(_FakePuzzleHistoryRepository(sessions));

      final stats = await useCase
          .watchPeriodStats(period: StatsPeriod.week, yearScope: StatsYearScope.currentYear, referenceDate: referenceDate)
          .first;

      expect(stats.started, 3);
      expect(stats.solved, 2);
      expect(stats.solvedHard, 1);
      expect(stats.solvedDays, 2);
      expect(stats.bestStreakDays, 2);
      expect(stats.hintsUsed, 3);
      expect(stats.hardRate, 0.5);
      expect(stats.totalTimePlayedMs, 180000);
      expect(stats.avgMovesPerSolve, 15.0);
    });

    test('uses puzzleDate as the reference, ignoring real startedAt/completedAt entirely', () async {
      final referenceDate = DateTime(2025, 8, 6);
      final sessions = [
        _session(
          puzzleDate: DateTime(2025, 8, 6),
          solved: true,
          startedAt: DateTime(2019, 3, 1),
          completedAt: DateTime(2023, 11, 20),
        ),
        _session(
          puzzleDate: DateTime(2025, 12, 25),
          solved: true,
          startedAt: DateTime(2025, 8, 6),
          completedAt: DateTime(2025, 8, 6),
        ),
      ];
      final useCase = PuzzleHistoryUseCase(_FakePuzzleHistoryRepository(sessions));

      final stats = await useCase
          .watchPeriodStats(period: StatsPeriod.week, yearScope: StatsYearScope.currentYear, referenceDate: referenceDate)
          .first;

      expect(stats.started, 1);
      expect(stats.solved, 1);
    });
  });

  group('watchPeriodStats: month + allYears', () {
    test('best streak treats consecutive month-days as one run regardless of which year each fell in', () async {
      final referenceDate = DateTime(2025, 8, 6);
      final sessions = [
        _session(puzzleDate: DateTime(2023, 8, 10), solved: true),
        _session(puzzleDate: DateTime(2024, 8, 11), solved: true),
        _session(puzzleDate: DateTime(2025, 8, 12), solved: true),
        _session(puzzleDate: DateTime(2022, 8, 20), solved: true),
        _session(puzzleDate: DateTime(2024, 9, 1), solved: true),
      ];
      final useCase = PuzzleHistoryUseCase(_FakePuzzleHistoryRepository(sessions));

      final stats = await useCase
          .watchPeriodStats(period: StatsPeriod.month, yearScope: StatsYearScope.allYears, referenceDate: referenceDate)
          .first;

      expect(stats.solvedDays, 4);
      expect(stats.bestStreakDays, 3);
    });
  });

  group('watchPeriodStats: week + allYears', () {
    test('reproduces the reported bug: Mar 26/2026, Mar 27/2026, Mar 28/2024 form a 3-day streak', () async {
      final referenceDate = DateTime(2026, 3, 26);
      final sessions = [
        _session(puzzleDate: DateTime(2026, 3, 26), solved: true),
        _session(puzzleDate: DateTime(2026, 3, 27), solved: true),
        _session(puzzleDate: DateTime(2024, 3, 28), solved: true),
      ];
      final useCase = PuzzleHistoryUseCase(_FakePuzzleHistoryRepository(sessions));

      final stats = await useCase
          .watchPeriodStats(period: StatsPeriod.week, yearScope: StatsYearScope.allYears, referenceDate: referenceDate)
          .first;

      expect(stats.solvedDays, 3);
      expect(stats.bestStreakDays, 3);
    });
  });

  group('watchPeriodStats: year + allYears', () {
    test('best streak is a real all-time run that can cross a calendar-year boundary', () async {
      final referenceDate = DateTime(2025, 8, 6);
      final sessions = [
        _session(puzzleDate: DateTime(2024, 1, 1), solved: true),
        _session(puzzleDate: DateTime(2024, 12, 30), solved: true),
        _session(puzzleDate: DateTime(2024, 12, 31), solved: true),
        _session(puzzleDate: DateTime(2025, 1, 1), solved: true),
        _session(puzzleDate: DateTime(2025, 1, 2), solved: true),
      ];
      final useCase = PuzzleHistoryUseCase(_FakePuzzleHistoryRepository(sessions));

      final stats = await useCase
          .watchPeriodStats(period: StatsPeriod.year, yearScope: StatsYearScope.allYears, referenceDate: referenceDate)
          .first;

      expect(stats.solvedDays, 5);
      expect(stats.bestStreakDays, 4);
    });
  });

  test('watchAchievements updates the solution count when solutions arrive after sessions', () async {
    final solutionCount = StreamController<int>();
    final useCase = PuzzleHistoryUseCase(
      _FakePuzzleHistoryRepository([_session(puzzleDate: DateTime(2026, 10, 8), solved: true)], solutionCount: solutionCount.stream),
    );
    final counts = <int>[];
    final subscription = useCase.watchAchievements().listen((final stats) => counts.add(stats.solutionsFound));

    solutionCount.add(0);
    await Future<void>.delayed(Duration.zero);
    solutionCount.add(3);
    await Future<void>.delayed(Duration.zero);

    expect(counts, [0, 3]);
    await subscription.cancel();
    await solutionCount.close();
  });
}
