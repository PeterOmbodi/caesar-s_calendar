import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_board_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PuzzlePieceUI _configPiece({
  required final String id,
  required final PieceType type,
  required final Offset position,
}) =>
    PuzzlePieceUI(
      id: id,
      position: position,
      placeZone: PlaceZone.grid,
      type: type,
      originalPath: generatePathForType(type, 10),
      color: () => Colors.blue,
      centerPoint: const Offset(5, 5),
      isConfigItem: true,
      isUsersItem: true,
    );

void main() {
  test(
      'cfgCellOffset maps index 0 to small config top-left and index 2 to large config top-left',
      () {
    const grid = PuzzleGridEntity(
      cellSize: 10,
      rows: 7,
      columns: 7,
      origin: Position(dx: 0, dy: 0),
    );
    const board = PuzzleBoardEntity(
      cellSize: 10,
      rows: 7,
      columns: 7,
      origin: Position(dx: 100, dy: 0),
    );

    // Keep reverse order intentionally to verify sorting by piece size.
    final big = _configPiece(
      id: 'zone2',
      type: PieceType.zone2,
      position: const Offset(30, 60), // row 6, col 3
    );
    final small = _configPiece(
      id: 'zone1',
      type: PieceType.zone1,
      position: const Offset(60, 10), // row 1, col 6
    );

    final state = PuzzleState.initial().copyWith(
      gridConfig: grid,
      boardConfig: board,
      pieces: [big, small],
    );

    // index 0: top-left cell of small piece
    expect(state.cfgCellOffset(0), const Offset(60, 10));
    // index 2: top-left cell of big piece
    expect(state.cfgCellOffset(2), const Offset(30, 60));
  });
}
