import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_board_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/services/puzzle_piece_movement_service.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = PuzzlePieceMovementService();

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

  PuzzlePieceUI piece({
    required final String id,
    required final PieceType type,
    required final Offset position,
    final PlaceZone zone = PlaceZone.grid,
  }) =>
      PuzzlePieceUI(
        id: id,
        position: position,
        placeZone: zone,
        type: type,
        originalPath: generatePathForType(type, grid.cellSize),
        color: () => Colors.blue,
        centerPoint: const Offset(5, 5),
      );

  test('getZoneAtPosition returns grid, board and null', () {
    expect(service.getZoneAtPosition(const Offset(5, 5), grid, board),
        PlaceZone.grid);
    expect(service.getZoneAtPosition(const Offset(105, 5), grid, board),
        PlaceZone.board);
    expect(
        service.getZoneAtPosition(const Offset(90, 90), grid, board), isNull);
  });

  test('checkCollision detects overlap on grid when preventOverlap=true', () {
    final a =
        piece(id: 'a', type: PieceType.square, position: const Offset(10, 10));
    final b =
        piece(id: 'b', type: PieceType.square, position: const Offset(10, 10));

    final hasCollision = service.checkCollision(
      piece: a,
      newPosition: a.position,
      zone: PlaceZone.grid,
      preventOverlap: true,
      pieces: [a, b],
      gridConfig: grid,
      boardConfig: board,
    );

    expect(hasCollision, isTrue);
  });

  test('computeDropResult rejects drop outside grid and board', () {
    final selected = piece(
        id: 'a', type: PieceType.square, position: const Offset(999, 999));

    final result = service.computeDropResult(
      selectedPiece: selected,
      pieceStartPosition: const Offset(10, 10),
      dragStartZone: PlaceZone.board,
      gridConfig: grid,
      boardConfig: board,
      pieces: [selected],
      preventOverlap: false,
    );

    expect(result.accepted, isFalse);
    expect(result.snappedPosition, isNull);
    expect(result.move, isNull);
  });

  test('computeDropResult clamps board drop into board bounds', () {
    final selected = piece(
      id: 'a',
      type: PieceType.square,
      position: const Offset(155, 60),
      zone: PlaceZone.board,
    );

    final result = service.computeDropResult(
      selectedPiece: selected,
      pieceStartPosition: const Offset(110, 10),
      dragStartZone: PlaceZone.board,
      gridConfig: grid,
      boardConfig: board,
      pieces: [selected],
      preventOverlap: false,
    );

    expect(result.accepted, isTrue);
    expect(result.zone, PlaceZone.board);
    expect(result.snappedPosition, isNotNull);
    expect(
        board.cellSize * board.columns + board.origin.dx >=
            result.snappedPosition!.dx,
        isTrue);
    expect(
        board.cellSize * board.rows + board.origin.dy >=
            result.snappedPosition!.dy,
        isTrue);
  });
}
