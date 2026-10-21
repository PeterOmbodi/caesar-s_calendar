import 'package:caesar_puzzle/core/models/move.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_board_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_entity_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_grid_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_extension.dart';
import 'package:flutter/material.dart';

class MoveHistoryService {
  const MoveHistoryService();

  PuzzlePieceUI historyPiece({
    required final PuzzleState state,
    required final int idx,
    required final bool isUndo,
    required final double rotationStep,
    required final double fullRotation,
  }) {
    final move = state.moveHistory[idx];
    final piece = state.pieces.firstWhere((final p) => p.id == move.pieceId);

    final historyPiece = move.map(
      movePiece: (final mp) {
        final zone = isUndo ? mp.from.zone : mp.to.zone;
        final config = zone == PlaceZone.grid ? state.gridConfig : state.boardConfig;
        final pos = isUndo ? mp.from.position : mp.to.position;
        final absPos = config.absolutPositionPos(pos);
        return piece.copyWith(
          placeZone: zone,
          position: Offset(absPos.dx, absPos.dy),
          rotation: isUndo ? mp.rotationFrom : mp.rotationTo,
          isFlipped: isUndo ? mp.flippedFrom : mp.flippedTo,
        );
      },
      rotatePiece: (final rp) => piece.copyWith(
        rotation: (rp.rotation - (isUndo ? rotationStep + fullRotation : 0)) % fullRotation,
        position: snapOffset(state.gridConfig, state.boardConfig, rp.snapCorrection, isUndo),
      ),
      flipPiece: (final fp) => piece.copyWith(
        isFlipped: isUndo ? !fp.isFlipped : fp.isFlipped,
        position: snapOffset(state.gridConfig, state.boardConfig, fp.snapCorrection, isUndo),
      ),
      hintMove: (final hm) {
        final zone = isUndo ? hm.from.zone : hm.to.zone;
        final config = zone == PlaceZone.grid ? state.gridConfig : state.boardConfig;
        final pos = isUndo ? hm.from.position : hm.to.position;
        final absPos = config.absolutPositionPos(pos);
        return piece.copyWith(
          rotation: isUndo ? hm.rotationFrom : hm.rotationTo,
          isFlipped: isUndo ? hm.flippedFrom : hm.flippedTo,
          placeZone: zone,
          position: Offset(absPos.dx, absPos.dy),
        );
      },
    );

    return historyPiece;
  }

  (PuzzlePieceUI piece, MovePiece? snapMove) maybeSnap({
    required final PuzzlePieceUI selectedPiece,
    required final PuzzleGridEntity grid,
  }) {
    final snappedPos = snappedPosition(selectedPiece, grid);
    if (snappedPos == selectedPiece.position) {
      return (selectedPiece, null);
    }
    final snapped = selectedPiece.copyWith(position: snappedPos);
    final snapMove = MovePiece(
      selectedPiece.id,
      from: MovePlacement(
        position: Position(
          dx: grid.relativePosition(selectedPiece.position).dx,
          dy: grid.relativePosition(selectedPiece.position).dy,
        ),
      ),
      to: MovePlacement(
        position: Position(
          dx: grid.relativePosition(snapped.position).dx,
          dy: grid.relativePosition(snapped.position).dy,
        ),
      ),
    );
    return (snapped, snapMove);
  }

  Offset snappedPosition(final PuzzlePieceUI selectedPiece, final PuzzleGridEntity grid) {
    final preSnapped = selectedPiece.copyWith(position: grid.snapToGrid(selectedPiece.position));
    return grid.snapToGrid(preSnapped.positionInside(grid.getBounds));
  }

  /// The shift is recorded like a grid snap, so undo restores it.
  (PuzzlePieceUI piece, MovePiece? snapMove) keepInTray({
    required final PuzzlePieceUI selectedPiece,
    required final PuzzleBoardEntity tray,
  }) {
    final inside = selectedPiece.positionInside(tray.getBounds);
    if ((inside - selectedPiece.position).distance < 0.01) {
      return (selectedPiece, null);
    }
    final from = tray.relativePosition(selectedPiece.position);
    final to = tray.relativePosition(inside);
    final snapMove = MovePiece(
      selectedPiece.id,
      from: MovePlacement(zone: PlaceZone.board, position: Position(dx: from.dx, dy: from.dy)),
      to: MovePlacement(zone: PlaceZone.board, position: Position(dx: to.dx, dy: to.dy)),
    );
    return (selectedPiece.copyWith(position: inside), snapMove);
  }

  Offset? snapOffset(
    final PuzzleGridEntity grid,
    final PuzzleBoardEntity tray,
    final MovePiece? snapCorrection,
    final bool isFrom,
  ) {
    if (snapCorrection == null) return null;
    final placement = isFrom ? snapCorrection.from : snapCorrection.to;
    final config = placement.zone == PlaceZone.grid ? grid : tray;
    return config.absolutPosition(Offset(placement.position.dx, placement.position.dy));
  }
}
