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
  }) {
    switch (this) {
      case MovePiece m:
        return movePiece(m);
      case RotatePiece r:
        return rotatePiece(r);
      case FlipPiece f:
        return flipPiece(f);
    }
  }
}

class MovePiece extends Move {
  final MovePlacement from;
  final MovePlacement to;

  const MovePiece(super.pieceId, {required this.from, required this.to});
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
