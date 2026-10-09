import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/presentation/models/drawn_group.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:flutter/foundation.dart';

enum StatusTone { neutral, ok, bad }

enum StatusMessage {
  readyToPlay,
  searching,
  solutionsCount,
  oneSolutionLeft,
  solvable,
  piecesPlaced,
  noSolutions,
  deadEnd,
  releaseToPlace,
  doesNotFit,
  keepDrawing,
  doubleTapToPlace,
  noMatchingShape,
  solved,
  viewingSolution,
}

@immutable
class PuzzleStatus {
  const PuzzleStatus(this.message, {this.tone = StatusTone.neutral, this.count, this.total});

  final StatusMessage message;
  final StatusTone tone;
  final int? count;
  final int? total;

  @override
  bool operator ==(final Object other) =>
      other is PuzzleStatus &&
      other.message == message &&
      other.tone == tone &&
      other.count == count &&
      other.total == total;

  @override
  int get hashCode => Object.hash(message, tone, count, total);

  @override
  String toString() => 'PuzzleStatus($message, $tone, count: $count, total: $total)';
}

PuzzleStatus statusFor(final PuzzleState state, final SolutionIndicator indicator) {
  if (state.isShowSolutions) {
    return PuzzleStatus(
      StatusMessage.viewingSolution,
      count: state.solutionIdx + 1,
      total: state.applicableSolutions.length,
    );
  }
  if (state.isSolved) {
    return const PuzzleStatus(StatusMessage.solved, tone: StatusTone.ok);
  }
  if (state.isDragging && state.showPreview) {
    return state.previewCollision
        ? const PuzzleStatus(StatusMessage.doesNotFit, tone: StatusTone.bad)
        : const PuzzleStatus(StatusMessage.releaseToPlace);
  }
  final group = state.drawnGroup;
  if (group != null) {
    return switch (state.drawnGroupCommitStatus) {
      DrawnGroupCommitStatus.tooSmall => PuzzleStatus(
        StatusMessage.keepDrawing,
        count: group.cells.length,
        total: PuzzleBloc.minCommittableDrawnCells,
      ),
      DrawnGroupCommitStatus.committable => const PuzzleStatus(StatusMessage.doubleTapToPlace, tone: StatusTone.ok),
      DrawnGroupCommitStatus.invalid => const PuzzleStatus(StatusMessage.noMatchingShape, tone: StatusTone.bad),
    };
  }

  final gamePieces = state.pieces.where((final p) => !p.isConfigItem);
  final placed = gamePieces.where((final p) => p.placeZone == PlaceZone.grid).length;
  final solutions = state.applicableSolutions.length;
  final isSearching = state.isSolving || state.status == GameStatus.initialized;

  switch (indicator) {
    case SolutionIndicator.countSolutions:
      if (isSearching) {
        return const PuzzleStatus(StatusMessage.searching);
      }
      return switch (solutions) {
        0 => const PuzzleStatus(StatusMessage.noSolutions, tone: StatusTone.bad),
        1 => const PuzzleStatus(StatusMessage.oneSolutionLeft, tone: StatusTone.ok),
        _ => PuzzleStatus(StatusMessage.solutionsCount, tone: StatusTone.ok, count: solutions),
      };
    case SolutionIndicator.solvability:
      if (placed == 0) {
        return const PuzzleStatus(StatusMessage.readyToPlay);
      }
      if (isSearching) {
        return const PuzzleStatus(StatusMessage.searching);
      }
      return solutions == 0
          ? const PuzzleStatus(StatusMessage.deadEnd, tone: StatusTone.bad)
          : const PuzzleStatus(StatusMessage.solvable, tone: StatusTone.ok);
    case SolutionIndicator.none:
      return placed == 0
          ? const PuzzleStatus(StatusMessage.readyToPlay)
          : PuzzleStatus(StatusMessage.piecesPlaced, count: placed, total: gamePieces.length);
  }
}
