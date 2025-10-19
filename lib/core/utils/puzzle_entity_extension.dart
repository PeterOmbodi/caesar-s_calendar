import 'dart:ui';

import 'package:caesar_puzzle/domain/entities/puzzle_base_entity.dart';

extension PuzzleEntityX on PuzzleBaseEntity {
  Rect get getBounds => Rect.fromLTWH(topLeft.dx, topLeft.dy, cellSize * columns, cellSize * rows);

  double relativeX(final Offset absolutPosition) => absolutPosition.dx - topLeft.dx;

  double relativeY(final Offset absolutPosition) => absolutPosition.dy - topLeft.dy;

  Offset relativePosition(final Offset absolutPosition) =>
      Offset(relativeX(absolutPosition) / cellSize, relativeY(absolutPosition) / cellSize);

  Offset absolutPosition(final Offset relativePosition) =>
      Offset(relativePosition.dx * cellSize + topLeft.dx, relativePosition.dy * cellSize + topLeft.dy);
}
