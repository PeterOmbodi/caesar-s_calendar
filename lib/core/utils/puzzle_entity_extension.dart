import 'dart:ui';

import 'package:caesar_puzzle/domain/entities/puzzle_base_entity.dart';

extension PuzzleEntityX on PuzzleBaseEntity {
  Rect get getBounds {
    return Rect.fromLTWH(
      topLeft.dx,
      topLeft.dy,
      cellSize * columns,
      cellSize * rows,
    );
  }

  double relativeX(Offset absolutPosition) => absolutPosition.dx - topLeft.dx;

  double relativeY(Offset absolutPosition) => absolutPosition.dy - topLeft.dy;

  double absolutX(Offset relativePosition) => relativePosition.dx + topLeft.dx;

  double absolutY(Offset relativePosition) => relativePosition.dy + topLeft.dy;

  Offset relativePosition(Offset absolutPosition) => Offset(
        relativeX(absolutPosition) / cellSize,
        relativeY(absolutPosition) / cellSize,
      );

  Offset absolutPosition(Offset relativePosition) => Offset(
        relativePosition.dx * cellSize + topLeft.dx,
        relativePosition.dy * cellSize + topLeft.dy,
      );
}
