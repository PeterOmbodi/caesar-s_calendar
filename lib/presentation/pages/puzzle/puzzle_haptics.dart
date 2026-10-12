import 'package:caesar_puzzle/core/models/move.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:flutter/services.dart';

enum PuzzleHaptic { piecePlaced, pieceTurned, solved }

PuzzleHaptic? hapticFor(final PuzzleState prev, final PuzzleState next) {
  if (next.isSolved && !prev.isSolved && !next.isRestoredSolvedSession) {
    return PuzzleHaptic.solved;
  }
  final index = next.moveIndex - 1;
  if (index != prev.moveIndex || next.moveIndex != next.moveHistory.length) {
    return null;
  }
  // Redo moves forward over the same move object; a new move replaces it.
  if (index < prev.moveHistory.length && identical(prev.moveHistory[index], next.moveHistory[index])) {
    return null;
  }
  return switch (next.moveHistory.last) {
    MovePiece(:final to) || HintMove(:final to) => to.zone == PlaceZone.grid ? PuzzleHaptic.piecePlaced : null,
    RotatePiece() || FlipPiece() => PuzzleHaptic.pieceTurned,
  };
}

Future<void> playHaptic(final PuzzleHaptic haptic) => switch (haptic) {
  PuzzleHaptic.piecePlaced || PuzzleHaptic.pieceTurned => HapticFeedback.lightImpact(),
  PuzzleHaptic.solved => HapticFeedback.heavyImpact(),
};

Future<void> playClick() => SystemSound.play(SystemSoundType.click);
