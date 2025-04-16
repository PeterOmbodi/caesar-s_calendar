import 'package:caesar_puzzle/dancing_links/cell.dart';
import 'package:caesar_puzzle/puzzle/puzzle_piece.dart';
import 'package:flutter/material.dart';

/// Extension for PuzzlePiece to add the [relativeCells] getter.
/// This computes the grid cells (relative to the shape’s top-left in its default orientation)
/// covered by the piece based on its [originalPath].
extension PuzzlePieceExtensions on PuzzlePiece {
  /// Returns the list of grid cells covered by this piece in its default orientation.
  /// It uses the bounding box of the original path and samples at the cell center.
  /// Assumes that the grid "unit" is the size of a cell.
  List<Cell> get relativeCells {
    // Ensure unit is not zero. If centerPoint.dx is 0, fallback to centerPoint.dy, or use a default value.
    final double unit = centerPoint.dx != 0
        ? centerPoint.dx
        : (centerPoint.dy != 0 ? centerPoint.dy : 1.0);

    // Get the bounding box of the original path.
    final Rect bounds = originalPath.getBounds();

    // Determine the starting row and column in grid units.
    final int startRow = (bounds.top - 0) ~/ unit; // 0 is an offset if needed
    final int startCol = (bounds.left - 0) ~/ unit;

    // Calculate how many grid units the bounding box spans.
    final int numRows = ((bounds.bottom - bounds.top) / unit).ceil();
    final int numCols = ((bounds.right - bounds.left) / unit).ceil();

    final List<Cell> cells = [];

    // Iterate over each grid cell in the bounding box.
    for (int r = 0; r < numRows; r++) {
      for (int c = 0; c < numCols; c++) {
        // Calculate the center of the cell in absolute coordinates.
        final Offset cellCenter = Offset(
          (startCol + c) * unit + unit / 2,
          (startRow + r) * unit + unit / 2,
        );
        // Check if the original path contains the cell center.
        if (originalPath.contains(cellCenter)) {
          // Save the cell relative to the bounding box top-left.
          cells.add(Cell(r, c));
        }
      }
    }

    return cells;
  }
}

