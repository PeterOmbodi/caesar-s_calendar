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

class RotatePiece extends Move {
  final double rotation;
  final MovePiece? snapCorrection;

  const RotatePiece(super.pieceId, {required this.rotation, this.snapCorrection});
}

class FlipPiece extends Move {
  final bool isFlipped;
  final MovePiece? snapCorrection;

  const FlipPiece(super.pieceId, {required this.isFlipped, this.snapCorrection});
}
