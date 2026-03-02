import 'package:caesar_puzzle/application/models/puzzle_piece_snapshot.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_status.dart';
import 'package:caesar_puzzle/core/models/move.dart';

enum PuzzleSessionDifficulty {
  easy,
  hard,
}

class PuzzleSessionData {
  const PuzzleSessionData({
    required this.id,
    required this.puzzleDate,
    required this.configId,
    required this.difficulty,
    required this.status,
    required this.startedAt,
    required this.firstMoveAt,
    required this.lastResumedAt,
    required this.activeElapsedMs,
    required this.updatedAt,
    required this.completedAt,
    required this.moveIndex,
    required this.moveHistoryVersion,
    required this.pieces,
    required this.moveHistory,
  });

  final String id;
  final DateTime puzzleDate;
  final String configId;
  final PuzzleSessionDifficulty difficulty;
  final PuzzleSessionStatus status;
  final int startedAt;
  final int? firstMoveAt;
  final int? lastResumedAt;
  final int activeElapsedMs;
  final int updatedAt;
  final int? completedAt;
  final int moveIndex;
  final int moveHistoryVersion;
  final List<PuzzlePieceSnapshot> pieces;
  final List<Move> moveHistory;
}
