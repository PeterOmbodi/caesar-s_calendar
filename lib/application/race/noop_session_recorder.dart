import 'package:caesar_puzzle/application/contracts/session_recorder.dart';
import 'package:caesar_puzzle/application/models/puzzle_history_input.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/core/models/placement.dart';

/// A race leaves no trace in the game history and must not touch the daily session.
class NoopSessionRecorder implements SessionRecorder {
  const NoopSessionRecorder();

  @override
  void resetSession() {}

  @override
  void activateSession(final PuzzleSessionData session) {}

  @override
  Future<List<PlacementParams>?> sessionLayout(final PuzzleSessionData session) async => null;

  @override
  void setCurrentSessionDifficulty(final PuzzleSessionDifficulty difficulty) {}

  @override
  void markCurrentSessionDifficulty(final PuzzleSessionDifficulty difficulty) {}

  @override
  void persistAfterChange(final PuzzleHistoryInput input) {}

  @override
  Future<void> markPuzzleAssisted({
    required final DateTime puzzleDate,
    required final List<PlacementParams> configPlacements,
  }) async {}

  @override
  Future<bool> isPuzzleAssisted({
    required final DateTime puzzleDate,
    required final List<PlacementParams> configPlacements,
  }) async => false;
}
