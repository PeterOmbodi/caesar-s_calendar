import 'package:caesar_puzzle/application/models/puzzle_piece_snapshot.dart';
import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/presentation/onboarding/models/puzzle_local_snapshot.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';

PuzzleLocalSnapshot buildPuzzleLocalSnapshot(final PuzzleState state) =>
    PuzzleLocalSnapshot(
      selectedDate: state.selectedDate,
      status: state.status,
      pieces: state.pieces
          .map(
            (final piece) => PuzzlePieceSnapshot(
              id: piece.id,
              placeZone: piece.placeZone,
              position: Position(dx: piece.position.dx, dy: piece.position.dy),
              rotation: piece.rotation,
              isFlipped: piece.isFlipped,
              isUsersItem: piece.isUsersItem,
              isConfigItem: piece.isConfigItem,
            ),
          )
          .toList(growable: false),
      moveHistory: List.of(state.moveHistory),
      moveIndex: state.moveIndex,
      firstMoveAt: state.firstMoveAt,
      lastResumedAt: state.lastResumedAt,
      activeElapsedMs: state.activeElapsedMs,
      hasShownSolvedDialog: state.hasShownSolvedDialog,
      isRestoredSolvedSession: state.isRestoredSolvedSession,
    );
