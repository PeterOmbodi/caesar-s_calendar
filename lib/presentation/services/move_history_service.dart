import 'package:caesar_puzzle/core/models/move.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/core/models/position.dart';
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
        return piece.copyWith(placeZone: zone, position: Offset(absPos.dx, absPos.dy));
      },
      rotatePiece: (final rp) => piece.copyWith(
        rotation: (rp.rotation - (isUndo ? rotationStep + fullRotation : 0)) % fullRotation,
        position: snapOffset(state.gridConfig, rp.snapCorrection, isUndo),
      ),
      flipPiece: (final fp) => piece.copyWith(
        isFlipped: isUndo ? !fp.isFlipped : fp.isFlipped,
        position: snapOffset(state.gridConfig, fp.snapCorrection, isUndo),
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
    var targetPosition = selectedPiece.position;

    final preSnapped = grid.snapToGrid(targetPosition);
    final gridBounds = grid.getBounds;

    final testPiece = selectedPiece.copyWith(position: preSnapped);
    final pieceBounds = testPiece.getTransformedPath().getBounds();

    var dx = 0.0;
    var dy = 0.0;
    if (pieceBounds.left < gridBounds.left) {
      dx += gridBounds.left - pieceBounds.left;
    }
    if (pieceBounds.right > gridBounds.right) {
      dx -= pieceBounds.right - gridBounds.right;
    }
    if (pieceBounds.top < gridBounds.top) {
      dy += gridBounds.top - pieceBounds.top;
    }
    if (pieceBounds.bottom > gridBounds.bottom) {
      dy -= pieceBounds.bottom - gridBounds.bottom;
    }
    targetPosition = Offset(preSnapped.dx + dx, preSnapped.dy + dy);
    return grid.snapToGrid(targetPosition);
  }

  Offset? snapOffset(final PuzzleGridEntity grid, final MovePiece? snapCorrection, final bool isFrom) {
    if (snapCorrection == null) return null;
    final pos = isFrom ? snapCorrection.from.position : snapCorrection.to.position;
    return grid.absolutPosition(Offset(pos.dx, pos.dy));
  }
}
