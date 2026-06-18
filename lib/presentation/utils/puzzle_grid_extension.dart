import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_entity_extension.dart';
import 'package:flutter/material.dart';

extension PuzzleGridX on PuzzleGridEntity {
  Cell? cellAt(final Offset position) {
    if (!getBounds.contains(position)) {
      return null;
    }
    final col = (relativeX(position) / cellSize).floor();
    final row = (relativeY(position) / cellSize).floor();
    final cell = Cell(row, col);
    return containsCell(cell) ? cell : null;
  }

  bool containsCell(final Cell cell) => cell.row >= 0 && cell.row < rows && cell.col >= 0 && cell.col < columns;

  Offset cellTopLeft(final Cell cell) => Offset(origin.dx + cell.col * cellSize, origin.dy + cell.row * cellSize);

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
