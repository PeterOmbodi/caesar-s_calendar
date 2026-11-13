import 'package:caesar_puzzle/application/models/puzzle_history_input.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/core/models/placement.dart';

/// What a running game reports about its session, and what it asks about it.
abstract interface class SessionRecorder {
  void resetSession();

  void activateSession(final PuzzleSessionData session);

  /// Block placements the session was played with; null if its config is not stored locally.
  Future<List<PlacementParams>?> sessionLayout(final PuzzleSessionData session);

  void setCurrentSessionDifficulty(final PuzzleSessionDifficulty difficulty);

  void markCurrentSessionDifficulty(final PuzzleSessionDifficulty difficulty);

  void persistAfterChange(final PuzzleHistoryInput input);

  Future<void> markPuzzleAssisted({
    required final DateTime puzzleDate,
    required final List<PlacementParams> configPlacements,
  });

  Future<bool> isPuzzleAssisted({
    required final DateTime puzzleDate,
    required final List<PlacementParams> configPlacements,
  });
}
