import 'package:caesar_puzzle/domain/entities/puzzle_board.dart';
import 'package:flutter/material.dart';

extension PuzzleBoardX on PuzzleBoard {
  Rect get getBounds {
    return Rect.fromLTWH(
      origin.dx,
      origin.dy,
      cellSize * columns,
      cellSize * rows,
    );
  }

  double initialX(double cellSize) => origin.dx + cellSize / 4;

  double initialY(double cellSize) => origin.dy + cellSize;
}
