import 'dart:ui';

import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_base_entity.dart';

extension PuzzleEntityX on PuzzleBaseEntity {
  Rect get getBounds => Rect.fromLTWH(topLeft.dx, topLeft.dy, width, height);

  double relativeX(final Offset absolutPosition) => absolutPosition.dx - positionOrigin.dx;

  double relativeY(final Offset absolutPosition) => absolutPosition.dy - positionOrigin.dy;

  Offset relativePosition(final Offset absolutPosition) =>
      Offset(relativeX(absolutPosition) / cellSize, relativeY(absolutPosition) / cellSize);

  Offset absolutPosition(final Offset relativePosition) =>
      Offset(relativePosition.dx * cellSize + positionOrigin.dx, relativePosition.dy * cellSize + positionOrigin.dy);

  Position relativePositionPos(final Position absolutePosition) => Position(
    dx: (absolutePosition.dx - positionOrigin.dx) / cellSize,
    dy: (absolutePosition.dy - positionOrigin.dy) / cellSize,
  );

  Position absolutPositionPos(final Position relativePosition) => Position(
    dx: relativePosition.dx * cellSize + positionOrigin.dx,
    dy: relativePosition.dy * cellSize + positionOrigin.dy,
  );
}
