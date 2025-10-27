import 'package:caesar_puzzle/core/utils/puzzle_entity_extension.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid.dart';
import 'package:flutter/material.dart';

extension PuzzleGridX on PuzzleGrid {
  Offset snapToGrid(final Offset position) {
    // Calculate the closest cell coordinates
    final cellX = (relativeX(position) / cellSize).round();
    final cellY = (relativeY(position) / cellSize).round();

    // Make sure we're within grid bounds
    final boundedCellX = cellX.clamp(0, columns - 1);
    final boundedCellY = cellY.clamp(0, rows - 1);

    // Convert back to absolute coordinates
    final snappedX = boundedCellX * cellSize + topLeft.dx;
    final snappedY = boundedCellY * cellSize + topLeft.dy;

    return Offset(snappedX, snappedY);
  }

  BoxConstraints cellConstraints() => BoxConstraints.tightFor(height: cellSize, width: cellSize);
}
