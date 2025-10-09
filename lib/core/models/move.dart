import 'package:caesar_puzzle/core/models/puzzle_piece_base.dart';
import 'package:flutter/material.dart';

class MovePlacement {
  final PlaceZone zone;
  final Offset position;

  MovePlacement({this.zone = PlaceZone.grid, required this.position});
}

sealed class Move {
  final String pieceId;

  const Move(this.pieceId);

  T map<T>({
    required T Function(MovePiece) movePiece,
    required T Function(RotatePiece) rotatePiece,
    required T Function(FlipPiece) flipPiece,
    required T Function(HintMove) hintMove,
  }) {
    switch (this) {
      case MovePiece m:
        return movePiece(m);
      case RotatePiece r:
        return rotatePiece(r);
      case FlipPiece f:
        return flipPiece(f);
      case HintMove f:
       return hintMove(f);
    }
  }
}

class MovePiece extends Move {
  final MovePlacement from;
  final MovePlacement to;

  const MovePiece(super.pieceId, {required this.from, required this.to});
}

class HintMove extends Move {
  final MovePlacement from;
  final MovePlacement to;
  final double rotationFrom;
  final double rotationTo;
  final bool flippedFrom;
  final bool flippedTo;

  const HintMove(
    super.pieceId, {
    required this.from,
    required this.to,
    required this.rotationFrom,
    required this.rotationTo,
    required this.flippedFrom,
    required this.flippedTo,
  });
}

sealed class SnappableMove extends Move {
  final MovePiece? snapCorrection;

  SnappableMove(super.pieceId, this.snapCorrection);

  Offset? getSnapOffset(Function(Offset) absolutPosition, bool isFrom) => snapCorrection == null
      ? null
      : absolutPosition(isFrom ? snapCorrection!.from.position : snapCorrection!.to.position);
}

class RotatePiece extends SnappableMove {
  final double rotation;

  RotatePiece(super.pieceId, super.snapCorrection, {required this.rotation});
}

class FlipPiece extends SnappableMove {
  final bool isFlipped;

  FlipPiece(super.pieceId, super.snapCorrection, {required this.isFlipped});
}
