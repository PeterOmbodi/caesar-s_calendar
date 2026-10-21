import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_status.dart';
import 'package:caesar_puzzle/presentation/pages/history/models/session_summary.dart';
import 'package:flutter_test/flutter_test.dart';

PuzzleSessionData _session({
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
  startedAt: 0,
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
}
