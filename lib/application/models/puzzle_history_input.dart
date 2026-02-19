import 'package:caesar_puzzle/application/models/puzzle_piece_snapshot.dart';
import 'package:caesar_puzzle/core/models/move.dart';
import 'package:caesar_puzzle/core/models/placement.dart';

class PuzzleHistoryInput {
  const PuzzleHistoryInput({
    required this.shouldPersist,
    required this.solvedTransition,
    required this.isSolved,
    required this.selectedDate,
    required this.moveHistory,
    required this.moveIndex,
    required this.firstMoveAt,
    required this.lastResumedAt,
    required this.activeElapsedMs,
    required this.configPlacements,
    required this.piecesSnapshot,
    required this.solutions,
    required this.applicableSolutions,
  });

  final bool shouldPersist;
  final bool solvedTransition;
  final bool isSolved;
  final DateTime selectedDate;
  final List<Move> moveHistory;
  final int moveIndex;
  final int? firstMoveAt;
  final int? lastResumedAt;
  final int activeElapsedMs;
  final List<PlacementParams> configPlacements;
  final List<PuzzlePieceSnapshot> piecesSnapshot;
  final List<Map<String, PlacementParams>> solutions;
  final List<Map<String, PlacementParams>> applicableSolutions;
}
