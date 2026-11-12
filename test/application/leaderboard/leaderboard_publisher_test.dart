import 'package:caesar_puzzle/application/contracts/puzzle_history_repository.dart';
import 'package:caesar_puzzle/application/leaderboard/day_difficulty.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_entry.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_publisher.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_status.dart';
import 'package:caesar_puzzle/application/models/solved_solution_record.dart';
import 'package:caesar_puzzle/core/constants/standard_puzzle_config.dart';
import 'package:flutter_test/flutter_test.dart';

class _History implements PuzzleHistoryRepository {
  _History(this.sessions);

  final List<PuzzleSessionData> sessions;

  @override
  Future<List<PuzzleSessionData>> getSolvedStandardSessions({
    required final DateTime from,
    required final DateTime to,
  }) async => sessions;

  @override
  Future<List<SolvedSolutionRecord>> getSolvedSolutions({
    required final DateTime from,
    required final DateTime to,
  }) async => const [];

  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

int _counter = 0;

PuzzleSessionData _solved(
  final DateTime date, {
  final PuzzleSessionDifficulty level = PuzzleSessionDifficulty.hard,
  final int timeMs = 90000,
}) {
  final completed = DateTime(date.year, date.month, date.day, 12).millisecondsSinceEpoch;
  return PuzzleSessionData(
    id: 's${_counter++}',
    puzzleDate: date,
    configId: StandardPuzzleConfig.id,
    difficulty: level,
    status: PuzzleSessionStatus.solved,
    startedAt: completed - timeMs,
    firstMoveAt: null,
    lastResumedAt: null,
    activeElapsedMs: timeMs,
    updatedAt: completed,
    completedAt: completed,
    moveIndex: 0,
    moveHistoryVersion: 1,
    pieces: const [],
    moveHistory: const [],
  );
}

int _points(final int month, final int day) =>
    DayDifficulty.dayPoints(tier: DayDifficulty.tier(month, day), extraSolutions: 0);

void main() {
  final now = DateTime(2026, 10, 30, 21);

  Future<LeaderboardSnapshot> build(
    final List<PuzzleSessionData> sessions, {
    final String? displayName = 'Peter Ombodi',
  }) => LeaderboardPublisher(_History(sessions)).build(uid: 'u1', displayName: displayName, now: now);

  test('publishes today and the current week, month and year per level', () async {
    final snapshot = await build([
      _solved(DateTime(2026, 10, 30)),
      _solved(DateTime(2026, 10, 29)),
      _solved(DateTime(2026, 10, 28), level: PuzzleSessionDifficulty.medium),
      _solved(DateTime(2026, 10, 30), level: PuzzleSessionDifficulty.easy),
      _solved(DateTime(2026, 9, 1)),
    ]);

    expect(
      snapshot.entries.keys,
      unorderedEquals([
        'd2026-10-30_hard',
        'w2026-44_hard',
        'm2026-10_hard',
        'y2026_hard',
        'w2026-44_medium',
        'm2026-10_medium',
        'y2026_medium',
      ]),
    );

    final day = snapshot.entries['d2026-10-30_hard']! as DayEntry;
    expect(day.timeMs, 90000);
    expect(day.extraSolutions, 0);
    expect(day.nickname, 'Peter O.');
    expect(day.expireAt, DateTime(2026, 11, 29));

    final week = snapshot.entries['w2026-44_hard']! as PeriodEntry;
    expect(week.points, _points(10, 29) + _points(10, 30));
    expect(week.days, 2);
    expect(week.expireAt, isNotNull);

    final year = snapshot.entries['y2026_hard']! as PeriodEntry;
    expect(year.points, _points(9, 1) + _points(10, 29) + _points(10, 30));
    expect(year.expireAt, isNull);
  });

  test('profile carries the nickname and streaks', () async {
    final snapshot = await build([
      _solved(DateTime(2026, 10, 29)),
      _solved(DateTime(2026, 10, 30)),
    ], displayName: null);

    expect(snapshot.profile.nickname, matches(RegExp(r'^\w+ \w+ \d\d$')));
    expect(snapshot.profile.nicknameSource, LeaderboardProfile.sourceGenerated);
    expect(snapshot.profile.streaks[PuzzleSessionDifficulty.hard]!.current, 2);
    expect(snapshot.profile.streaks[PuzzleSessionDifficulty.medium]!.best, 2);
  });

  test('last year counts for streaks only', () async {
    final snapshot = await build([_solved(DateTime(2025, 12, 31))]);

    expect(snapshot.entries, isEmpty);
    expect(snapshot.profile.streaks[PuzzleSessionDifficulty.hard]!.best, 1);
  });

  test('implausible time skips only the day entry', () async {
    final snapshot = await build([_solved(DateTime(2026, 10, 30), timeMs: 3000)]);

    expect(snapshot.entries.keys, isNot(contains('d2026-10-30_hard')));
    expect(snapshot.entries.keys, contains('w2026-44_hard'));
  });

  test('key follows the published data', () async {
    final a = await build([_solved(DateTime(2026, 10, 30))]);
    final b = await build([_solved(DateTime(2026, 10, 30))]);
    final c = await build([_solved(DateTime(2026, 10, 30), timeMs: 80000)]);

    expect(a.key, b.key);
    expect(a.key, isNot(c.key));
  });

  test('empty snapshot has zero streaks for both levels and no entries', () {
    final snapshot = LeaderboardPublisher(_History(const [])).emptySnapshot(uid: 'u1', displayName: 'Peter Ombodi');

    expect(snapshot.entries, isEmpty);
    expect(snapshot.profile.nickname, 'Peter O.');
    expect(snapshot.profile.nicknameSource, LeaderboardProfile.sourceName);
    final levels = [PuzzleSessionDifficulty.medium, PuzzleSessionDifficulty.hard];
    expect(snapshot.profile.streaks.keys, unorderedEquals(levels));
    expect(snapshot.profile.streaks.values.every((final s) => s.best == 0 && s.current == 0), isTrue);
  });
}
