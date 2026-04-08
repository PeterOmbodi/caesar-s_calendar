import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:flutter/material.dart';

Rect? resolveLabelCellRect(final PuzzleState state, final int labelIndex) {
  final forbiddenCells = state.sortedConfigCells.toSet();
  var visibleLabelIndex = 0;

  for (var row = 0; row < state.gridConfig.rows; row++) {
    for (var column = 0; column < state.gridConfig.columns; column++) {
      if (forbiddenCells.contains(Cell(row, column))) {
        continue;
      }
      if (visibleLabelIndex == labelIndex) {
        final origin = state.gridConfig.origin;
        final cellSize = state.gridConfig.cellSize;
        return Rect.fromLTWH(
          origin.dx + column * cellSize,
          origin.dy + row * cellSize,
          cellSize,
          cellSize,
        );
      }
      visibleLabelIndex++;
      if (visibleLabelIndex > 42) {
        return null;
      }
    }
  }

  return null;
}
