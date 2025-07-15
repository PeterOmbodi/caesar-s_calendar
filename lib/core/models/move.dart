import 'package:caesar_puzzle/core/models/puzzle_piece_base.dart';
import 'package:flutter/material.dart';

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
  final ({PlaceZone zone, Offset position}) from;
  final ({PlaceZone zone, Offset position}) to;

  const MovePiece(
    super.pieceId, {
    required this.from,
    required this.to,
  });
}

class RotatePiece extends Move {
  final double rotation;

  const RotatePiece(
    super.pieceId, {
    required this.rotation,
  });
}

class FlipPiece extends Move {
  final bool isFlipped;

  const FlipPiece(
    super.pieceId, {
    required this.isFlipped,
  });
}
