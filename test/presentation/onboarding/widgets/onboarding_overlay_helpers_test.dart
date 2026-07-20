import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_board_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/onboarding/widgets/overlay/onboarding_overlay_helpers.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_entity_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('drag interaction hole is wider and taller for the onboarding drag step', () {
    const cellSize = 60.0;
    const grid = PuzzleGridEntity(cellSize: cellSize, rows: 7, columns: 7, origin: Position(dx: 10, dy: 20));
    const board = PuzzleBoardEntity(cellSize: cellSize, rows: 7, columns: 7, origin: Position(dx: 460, dy: 20));
    final pShape = PuzzlePieceUI.fromType(
      PieceType.pShape,
      const Offset(470, 35),
      const Offset(cellSize / 2, cellSize / 2),
      cellSize,
    );
    final state = PuzzleState.initial().copyWith(
      gridConfig: grid,
      boardConfig: board,
      pieces: [pShape.copyWith(placeZone: PlaceZone.board)],
    );

    final baseRect = grid.getBounds.expandToInclude(board.getBounds).inflate(8);
    final sourceBounds = pShape.getTransformedPath().getBounds();
    final oldHole = Rect.fromLTRB(baseRect.left + 8, baseRect.top, baseRect.right - 8, sourceBounds.bottom + 16);
    final hole = buildDragInteractionHole(state);

    expect(hole.left, lessThan(oldHole.left));
    expect(hole.right, greaterThan(oldHole.right));
    expect(hole.height, closeTo(oldHole.height + cellSize / 3, 0.001));
  });
}
