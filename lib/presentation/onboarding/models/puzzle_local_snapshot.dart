import 'package:caesar_puzzle/application/models/puzzle_piece_snapshot.dart';
import 'package:caesar_puzzle/core/models/move.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';

class PuzzleLocalSnapshot {
  const PuzzleLocalSnapshot({
    required this.selectedDate,
    required this.status,
    required this.pieces,
    required this.moveHistory,
    required this.moveIndex,
    required this.firstMoveAt,
    required this.lastResumedAt,
    required this.activeElapsedMs,
    required this.hasShownSolvedDialog,
    required this.isRestoredSolvedSession,
  });

  final DateTime selectedDate;
  final GameStatus status;
  final List<PuzzlePieceSnapshot> pieces;
  final List<Move> moveHistory;
  final int moveIndex;
  final int? firstMoveAt;
  final int? lastResumedAt;
  final int activeElapsedMs;
  final bool hasShownSolvedDialog;
  final bool isRestoredSolvedSession;
}
