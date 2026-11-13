import 'package:caesar_puzzle/application/leaderboard/day_difficulty.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_period.dart';
import 'package:caesar_puzzle/application/leaderboard/leaderboard_scoring.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_status.dart';
import 'package:caesar_puzzle/application/models/solved_solution_record.dart';
import 'package:caesar_puzzle/core/constants/standard_puzzle_config.dart';
import 'package:caesar_puzzle/core/models/move.dart';
import 'package:caesar_puzzle/core/models/position.dart';
import 'package:flutter_test/flutter_test.dart';

const _easy = PuzzleSessionDifficulty.easy;
const _medium = PuzzleSessionDifficulty.medium;
const _hard = PuzzleSessionDifficulty.hard;

int _counter = 0;

PuzzleSessionData _solved(
  final DateTime date, {
  final PuzzleSessionDifficulty level = _hard,
  final DateTime? completedAt,
  final int timeMs = 60000,
  final String configId = StandardPuzzleConfig.id,
  final bool hint = false,
  final bool assisted = false,
  final String? id,
}) {
  final completed = completedAt ?? DateTime(date.year, date.month, date.day, 12);
  return PuzzleSessionData(
    id: id ?? 's${_counter++}',
    puzzleDate: date,
    configId: configId,
    difficulty: level,
    status: PuzzleSessionStatus.solved,
    startedAt: completed.millisecondsSinceEpoch - timeMs,
    firstMoveAt: null,
    lastResumedAt: null,
    activeElapsedMs: timeMs,
    updatedAt: completed.millisecondsSinceEpoch,
    completedAt: completed.millisecondsSinceEpoch,
    moveIndex: 0,
    moveHistoryVersion: 1,
    pieces: const [],
    moveHistory: [
      if (hint)
        HintMove(
          'p',
          from: MovePlacement(position: const Position.zero()),
          to: MovePlacement(position: const Position.zero()),
          rotationFrom: 0,
          rotationTo: 0,
          flippedFrom: false,
          flippedTo: false,
        ),
    ],
    assisted: assisted,
  );
}

SolvedSolutionRecord _found(final PuzzleSessionData session, final String signature, {final DateTime? at}) =>
    SolvedSolutionRecord(
      puzzleDate: session.puzzleDate,
      configId: session.configId,
      signature: signature,
      sessionId: session.id,
      solvedAt: at?.millisecondsSinceEpoch ?? session.completedAt!,
    );

void main() {
  final oct8 = DateTime(2026, 10, 8);

  test('countsForRecords: Medium and Hard daily puzzle on its day, Standard, without help', () {
    expect(LeaderboardScoring.countsForRecords(_solved(oct8)), isTrue);
    expect(LeaderboardScoring.countsForRecords(_solved(oct8, level: _medium)), isTrue);
    expect(LeaderboardScoring.countsForRecords(_solved(oct8, level: _easy)), isFalse);
    expect(LeaderboardScoring.countsForRecords(_solved(oct8, hint: true)), isFalse);
    expect(LeaderboardScoring.countsForRecords(_solved(oct8, assisted: true)), isFalse);
    expect(LeaderboardScoring.countsForRecords(_solved(oct8, configId: 'custom')), isFalse);
    expect(LeaderboardScoring.countsForRecords(_solved(oct8, completedAt: DateTime(2026, 10, 9, 9))), isFalse);
  });

  group('dayResults', () {
    test('first clean solve gives the time; tier 4 day gives 17 points', () {
      final first = _solved(oct8, completedAt: DateTime(2026, 10, 8, 9), timeMs: 90000);
      final second = _solved(oct8, completedAt: DateTime(2026, 10, 8, 10), timeMs: 30000);

      final [result] = LeaderboardScoring.dayResults([second, first], [_found(first, 'a'), _found(second, 'b')]);

      expect(result.timeMs, 90000);
      expect(result.extraSolutions, 1);
      expect(result.points, 17 + 1);
      expect(result.firstSolvedAt, DateTime(2026, 10, 8, 9));
      expect(result.pointsReachedAt, DateTime(2026, 10, 8, 10));
    });

    test('repeated solution is not an extra', () {
      final a = _solved(oct8, completedAt: DateTime(2026, 10, 8, 9));
      final b = _solved(oct8, completedAt: DateTime(2026, 10, 8, 10));

      final [result] = LeaderboardScoring.dayResults([a, b], [_found(a, 'x'), _found(b, 'x')]);

      expect(result.extraSolutions, 0);
      expect(result.pointsReachedAt, DateTime(2026, 10, 8, 9));
    });

    test('extras are capped at 10', () {
      final sessions = [for (var i = 0; i < 15; i++) _solved(oct8, completedAt: DateTime(2026, 10, 8, 8, i))];
      final found = [for (var i = 0; i < 15; i++) _found(sessions[i], 'sig$i')];

      final [result] = LeaderboardScoring.dayResults(sessions, found);

      expect(result.extraSolutions, DayDifficulty.maxExtraSolutions);
      expect(result.points, 17 + 10);
      expect(result.pointsReachedAt, DateTime(2026, 10, 8, 8, 10));
    });

    test('archive, custom layout, hints and viewed solutions do not count', () {
      final results = LeaderboardScoring.dayResults([
        _solved(oct8, completedAt: DateTime(2026, 10, 9, 9)),
        _solved(oct8, configId: 'custom'),
        _solved(oct8, hint: true),
        _solved(oct8, assisted: true),
      ], const []);

      expect(results, isEmpty);
    });

    test('solved in advance does not count', () {
      final results = LeaderboardScoring.dayResults([_solved(oct8, completedAt: DateTime(2026, 10, 7, 20))], const []);

      expect(results, isEmpty);
    });

    test('Medium and Hard have their own results; Easy has none', () {
      final results = LeaderboardScoring.dayResults([
        _solved(oct8, level: _easy, timeMs: 1000),
        _solved(oct8, level: _medium, timeMs: 3000),
        _solved(oct8, level: _hard, timeMs: 5000),
      ], const []);

      expect({for (final r in results) r.level: r.timeMs}, {_medium: 3000, _hard: 5000});
    });

    test('extras found by another level do not count', () {
      final hard = _solved(oct8, level: _hard, completedAt: DateTime(2026, 10, 8, 9));
      final medium = _solved(oct8, level: _medium, completedAt: DateTime(2026, 10, 8, 10));

      final results = LeaderboardScoring.dayResults([hard, medium], [_found(hard, 'a'), _found(medium, 'b')]);

      expect(results.every((final r) => r.extraSolutions == 0), isTrue);
    });
  });

  group('periodResult', () {
    test('sums the level days inside the range', () {
      final days = LeaderboardScoring.dayResults([
        _solved(DateTime(2026, 10, 6)),
        _solved(oct8),
        _solved(oct8, level: _medium),
        _solved(DateTime(2026, 10, 30)),
      ], const []);
      final range = LeaderboardKeys.range(LeaderboardPeriod.month, oct8);

      final result = LeaderboardScoring.periodResult(days, _hard, range)!;

      final oct30Points = DayDifficulty.dayPoints(tier: DayDifficulty.tier(10, 30), extraSolutions: 0);
      expect(result.points, 20 + 17 + oct30Points);
      expect(result.days, 3);
      expect(result.reachedAt, DateTime(2026, 10, 30, 12));
    });

    test('null without days', () {
      expect(
        LeaderboardScoring.periodResult(const [], _hard, LeaderboardKeys.range(LeaderboardPeriod.year, oct8)),
        isNull,
      );
    });
  });

  group('streaks', () {
    Map<PuzzleSessionDifficulty, LevelStreak> streaks(final List<PuzzleSessionData> sessions, {DateTime? today}) =>
        LeaderboardScoring.streaks(sessions, today: today ?? DateTime(2026, 10, 30, 21));

    test('cumulative by level', () {
      final result = streaks([
        _solved(DateTime(2026, 10, 26), level: _easy),
        _solved(DateTime(2026, 10, 27), level: _hard),
        _solved(DateTime(2026, 10, 28), level: _medium),
        _solved(DateTime(2026, 10, 29), level: _hard),
        _solved(DateTime(2026, 10, 30), level: _easy),
      ]);

      expect(result.keys, unorderedEquals([_medium, _hard]));
      expect(result[_hard]!.best, 1);
      expect(result[_medium]!.best, 3);
      expect(result[_medium]!.current, 3);
      expect(result[_medium]!.lastDay, DateTime(2026, 10, 29));
    });

    for (final (name, help) in [('hint', (hint: true, assisted: false)), ('help', (hint: false, assisted: true))]) {
      test('$name solve breaks the streak', () {
        final result = streaks([
          _solved(DateTime(2026, 10, 28)),
          _solved(DateTime(2026, 10, 29), level: _medium, hint: help.hint, assisted: help.assisted),
          _solved(DateTime(2026, 10, 30)),
        ]);

        expect(result[_hard]!.best, 1);
        expect(result[_medium]!.best, 1);
      });
    }

    test('only Standard solved on its own date', () {
      final result = streaks([
        _solved(DateTime(2026, 10, 28)),
        _solved(DateTime(2026, 10, 29), completedAt: DateTime(2026, 10, 28, 20)),
        _solved(DateTime(2026, 10, 29), configId: 'custom'),
        _solved(DateTime(2026, 10, 30)),
      ]);

      expect(result[_hard]!.best, 1);
    });

    test('current streak ends when yesterday was missed', () {
      final result = streaks([
        _solved(DateTime(2026, 10, 26)),
        _solved(DateTime(2026, 10, 27)),
        _solved(DateTime(2026, 10, 28)),
      ]);

      expect(result[_hard]!.best, 3);
      expect(result[_hard]!.current, 0);
    });

    test('still alive today when solved yesterday', () {
      final result = streaks([_solved(DateTime(2026, 10, 28)), _solved(DateTime(2026, 10, 29))]);

      expect(result[_hard]!.current, 2);
    });

    test('runs across the new year and over DST', () {
      final result = streaks([
        _solved(DateTime(2025, 12, 31)),
        _solved(DateTime(2026)),
        _solved(DateTime(2026, 10, 24)),
        _solved(DateTime(2026, 10, 25)),
        _solved(DateTime(2026, 10, 26)),
      ]);

      expect(result[_hard]!.best, 3);
      expect(result[_hard]!.current, 0);
    });

    test('empty', () {
      expect(streaks(const [])[_hard]!.best, 0);
    });
  });
}
