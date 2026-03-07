import 'package:caesar_puzzle/core/models/move.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_board_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/domain/services/placement_validator.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_entity_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_grid_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_utils.dart';
import 'package:flutter/material.dart';

class PuzzleDropResult {
  const PuzzleDropResult._({
    required this.accepted,
    this.snappedPosition,
    this.zone,
    this.move,
  });

  const PuzzleDropResult.accepted({
    required final Offset snappedPosition,
    required final PlaceZone zone,
    required final MovePiece move,
  }) : this._(
          accepted: true,
          snappedPosition: snappedPosition,
          zone: zone,
          move: move,
        );

  const PuzzleDropResult.rejected() : this._(accepted: false);

  final bool accepted;
  final Offset? snappedPosition;
  final PlaceZone? zone;
  final MovePiece? move;
}

class PuzzlePieceMovementService {
  const PuzzlePieceMovementService();

  static const double collisionTolerance = 2;
  static const double intersectionWidthThreshold = 2;

  final PlacementValidator _placementValidator = const PlacementValidator();

  PlaceZone? getZoneAtPosition(
    final Offset position,
    final PuzzleGridEntity grid,
    final PuzzleBoardEntity board,
  ) {
    if (grid.getBounds.contains(position)) {
      return PlaceZone.grid;
    } else if (board.getBounds.contains(position)) {
      return PlaceZone.board;
    }
    return null;
  }

  bool checkCollision({
    required final PuzzlePieceUI piece,
    required final Offset newPosition,
    required final PlaceZone zone,
    required final bool preventOverlap,
    required final Iterable<PuzzlePieceUI> pieces,
    required final PuzzleGridEntity gridConfig,
    required final PuzzleBoardEntity boardConfig,
  }) {
    switch (zone) {
      case PlaceZone.grid:
        final testPiece = piece.copyWith(position: newPosition);
        final candidate = testPiece.toDomain(gridConfig);
        final others = pieces
            .where((final p) => p.id != piece.id && p.placeZone == zone)
            .map(
              (final other) => other.copyWith(
                originalPath:
                    generatePathForType(other.type, gridConfig.cellSize),
              ),
            );
        final otherDomains = others.map((final ui) => ui.toDomain(gridConfig));
        return _placementValidator.hasCollision(
          candidate: candidate,
          grid: gridConfig,
          others: otherDomains,
          preventOverlap: preventOverlap,
        );
      case PlaceZone.board:
        final testPiece = piece.copyWith(position: newPosition);
        final testPath = testPiece.getTransformedPath();
        final testBounds = testPath.getBounds();
        if (preventOverlap) {
          final piecesToCheck = pieces.where(
            (final p) => p.id != piece.id && p.placeZone == zone,
          );
          for (final otherPiece in piecesToCheck) {
            final otherPath = otherPiece.getTransformedPath();
            final otherBounds = otherPath.getBounds();

            if (!testBounds.overlaps(otherBounds)) {
              continue;
            }

            try {
              final combinedPath = Path.combine(
                PathOperation.intersect,
                testPath,
                otherPath,
              );
              final intersectionBounds = combinedPath.getBounds();

              if (!intersectionBounds.isEmpty &&
                  intersectionBounds.width > intersectionWidthThreshold &&
                  intersectionBounds.height > collisionTolerance) {
                return true;
              }
            } catch (e) {
              debugPrint('Checking collision exception: $e');
              return true;
            }
          }
        }
        if (!boardConfig.getBounds.overlaps(testBounds)) {
          debugPrint('Piece not overlapping with board');
          return true;
        }
    }

    return false;
  }

  PuzzleDropResult computeDropResult({
    required final PuzzlePieceUI selectedPiece,
    required final Offset pieceStartPosition,
    required final PlaceZone? dragStartZone,
    required final PuzzleGridEntity gridConfig,
    required final PuzzleBoardEntity boardConfig,
    required final Iterable<PuzzlePieceUI> pieces,
    required final bool preventOverlap,
  }) {
    final newZone =
        getZoneAtPosition(selectedPiece.position, gridConfig, boardConfig);
    if (newZone == null) {
      return const PuzzleDropResult.rejected();
    }

    late Offset snappedPosition;
    var collisionDetected = false;
    switch (newZone) {
      case PlaceZone.grid:
        snappedPosition = gridConfig.snapToGrid(selectedPiece.position);
        collisionDetected = checkCollision(
          piece: selectedPiece,
          newPosition: snappedPosition,
          zone: newZone,
          preventOverlap: preventOverlap,
          pieces: pieces,
          gridConfig: gridConfig,
          boardConfig: boardConfig,
        );
      case PlaceZone.board:
        snappedPosition = selectedPiece.position;
        final boardBounds = boardConfig.getBounds;
        final pieceBounds = selectedPiece.getTransformedPath().getBounds();

        if (pieceBounds.left < boardBounds.left) {
          snappedPosition = Offset(
            snappedPosition.dx + (boardBounds.left - pieceBounds.left),
            snappedPosition.dy,
          );
        }
        if (pieceBounds.right > boardBounds.right) {
          snappedPosition = Offset(
            snappedPosition.dx - (pieceBounds.right - boardBounds.right),
            snappedPosition.dy,
          );
        }
        if (pieceBounds.top < boardBounds.top) {
          snappedPosition = Offset(
            snappedPosition.dx,
            snappedPosition.dy + (boardBounds.top - pieceBounds.top),
          );
        }
        if (pieceBounds.bottom > boardBounds.bottom) {
          snappedPosition = Offset(
            snappedPosition.dx,
            snappedPosition.dy - (pieceBounds.bottom - boardBounds.bottom),
          );
        }
        collisionDetected = false;
    }

    if (collisionDetected) {
      return const PuzzleDropResult.rejected();
    }

    final fromConfig =
        dragStartZone == PlaceZone.grid ? gridConfig : boardConfig;
    final toConfig = newZone == PlaceZone.grid ? gridConfig : boardConfig;
    final move = MovePiece(
      selectedPiece.id,
      from: MovePlacement(
        zone: dragStartZone ?? PlaceZone.board,
        position: Position(
          dx: fromConfig.relativePosition(pieceStartPosition).dx,
          dy: fromConfig.relativePosition(pieceStartPosition).dy,
        ),
      ),
      to: MovePlacement(
        zone: newZone,
        position: Position(
          dx: toConfig.relativePosition(snappedPosition).dx,
          dy: toConfig.relativePosition(snappedPosition).dy,
        ),
      ),
    );

    return PuzzleDropResult.accepted(
      snappedPosition: snappedPosition,
      zone: newZone,
      move: move,
    );
  }
}
