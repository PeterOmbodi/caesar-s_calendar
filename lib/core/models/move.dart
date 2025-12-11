import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/core/models/position.dart';

class MovePlacement {
  MovePlacement({this.zone = PlaceZone.grid, required this.position});

  final PlaceZone zone;
  final Position position;
}

sealed class Move {
  const Move(this.pieceId);

  final String pieceId;

  T map<T>({
    required final T Function(MovePiece) movePiece,
    required final T Function(RotatePiece) rotatePiece,
    required final T Function(FlipPiece) flipPiece,
    required final T Function(HintMove) hintMove,
  }) {
    switch (this) {
      case final MovePiece m:
        return movePiece(m);
      case final RotatePiece r:
        return rotatePiece(r);
      case final FlipPiece f:
        return flipPiece(f);
      case final HintMove f:
        return hintMove(f);
    }
  }
}

class MovePiece extends Move {
  const MovePiece(super.pieceId, {required this.from, required this.to});

  final MovePlacement from;
  final MovePlacement to;
}

class HintMove extends Move {
  const HintMove(
    super.pieceId, {
    required this.from,
    required this.to,
    required this.rotationFrom,
    required this.rotationTo,
    required this.flippedFrom,
    required this.flippedTo,
  });

  final MovePlacement from;
  final MovePlacement to;
  final double rotationFrom;
  final double rotationTo;
  final bool flippedFrom;
  final bool flippedTo;
}

sealed class SnappableMove extends Move {
  SnappableMove(super.pieceId, this.snapCorrection);

  final MovePiece? snapCorrection;
}

class RotatePiece extends SnappableMove {
  RotatePiece(super.pieceId, super.snapCorrection, {required this.rotation});

  final double rotation;
}

class FlipPiece extends SnappableMove {
  FlipPiece(super.pieceId, super.snapCorrection, {required this.isFlipped});

  final bool isFlipped;
}
