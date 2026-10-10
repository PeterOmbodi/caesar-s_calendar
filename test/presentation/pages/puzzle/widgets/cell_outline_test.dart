import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/cell_outline.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/widgets/piece_paint_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cell = 50.0;

  int contours(final Path path) => path.computeMetrics().length;

  test('single cell is inset on every side', () {
    final path = cellOutlinePath([Cell(0, 0)], cell, inset: 2, radius: 6);

    expect(path.getBounds(), const Rect.fromLTRB(2, 2, 48, 48));
    expect(contours(path), 1);
  });

  test('L shape follows its cells', () {
    final cells = [Cell(0, 0), Cell(1, 0), Cell(1, 1), Cell(1, 2), Cell(1, 3)];
    final path = cellOutlinePath(cells, cell, inset: 2);

    expect(path.getBounds(), const Rect.fromLTRB(2, 2, 198, 98));
    expect(path.contains(const Offset(25, 25)), isTrue);
    expect(path.contains(const Offset(75, 25)), isFalse);
    expect(path.contains(const Offset(175, 75)), isTrue);
  });

  test('cells touching only by a corner give separate contours', () {
    final path = cellOutlinePath([Cell(0, 0), Cell(1, 1)], cell, inset: 2);

    expect(contours(path), 2);
    expect(path.contains(const Offset(50, 50)), isFalse);
  });

  test('ring keeps its hole empty', () {
    final ring = [
      for (var row = 0; row < 3; row++)
        for (var col = 0; col < 3; col++)
          if (row != 1 || col != 1) Cell(row, col),
    ];
    final path = cellOutlinePath(ring, cell, inset: 2, radius: 6);

    expect(contours(path), 2);
    expect(path.contains(const Offset(75, 75)), isFalse);
    expect(path.contains(const Offset(25, 25)), isTrue);
  });

  test('piece outline is placed at the piece position', () {
    final piece = PuzzlePieceUI.fromType(
      PieceType.square,
      const Offset(100, 40),
      const Offset(cell / 2, cell / 2),
      cell,
    ).copyWith(placeZone: PlaceZone.grid);

    final bounds = PiecePaintHelper.outlinePath(piece, cell).getBounds();

    expect(bounds, const Rect.fromLTRB(102, 42, 198, 188));
  });
}
