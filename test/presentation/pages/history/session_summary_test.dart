import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_status.dart';
import 'package:caesar_puzzle/presentation/pages/history/models/session_summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

PuzzleSessionData _session({
  final int startedAt = 0,
  final int activeElapsedMs = 0,
  final int? firstMoveAt,
  final int? lastResumedAt,
  final int updatedAt = 0,
  final int? completedAt,
}) => PuzzleSessionData(
  id: 's',
  puzzleDate: DateTime(2026, 10, 8),
  configId: 'cfg',
  difficulty: PuzzleSessionDifficulty.hard,
  status: PuzzleSessionStatus.unsolved,
  startedAt: startedAt,
  firstMoveAt: firstMoveAt,
  lastResumedAt: lastResumedAt,
  activeElapsedMs: activeElapsedMs,
  updatedAt: updatedAt,
  completedAt: completedAt,
  moveIndex: 0,
  moveHistoryVersion: 1,
  pieces: const [],
  moveHistory: const [],
);

void main() {
  test('durationMs adds the segment that was running when the session was saved', () {
    expect(SessionSummary.durationMs(_session(activeElapsedMs: 5000)), 5000);
    expect(SessionSummary.durationMs(_session(activeElapsedMs: 5000, lastResumedAt: 10000, updatedAt: 13000)), 8000);
    expect(SessionSummary.durationMs(_session(firstMoveAt: 1000, completedAt: 61000)), 60000);
  });

  test('formatDuration pads to mm:ss and keeps long minutes', () {
    expect(SessionSummary.formatDuration(65000), '01:05');
    expect(SessionSummary.formatDuration(125 * 60000), '125:00');
  });

  group('timeLabel', () {
    setUpAll(() => initializeDateFormatting('en'));

    final start = DateTime(2026, 10, 24, 17, 27).millisecondsSinceEpoch;

    test('shows only the start while in progress', () {
      expect(SessionSummary(_session(startedAt: start), locale: 'en').timeLabel, 'Oct 24, 2026 · 17:27');
    });

    test('adds the solve time on the same day', () {
      final end = DateTime(2026, 10, 24, 17, 45).millisecondsSinceEpoch;
      final summary = SessionSummary(
        _session(startedAt: start, completedAt: end),
        locale: 'en',
      );
      expect(summary.timeLabel, 'Oct 24, 2026 · 17:27 – 17:45');
    });

    test('adds the solve date when solved on another day', () {
      final end = DateTime(2026, 10, 25, 8, 40).millisecondsSinceEpoch;
      final summary = SessionSummary(
        _session(startedAt: start, completedAt: end),
        locale: 'en',
      );
      expect(summary.timeLabel, 'Oct 24, 2026 · 17:27 – Oct 25 · 08:40');
    });
  });
}
