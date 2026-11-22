import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_board_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/services/puzzle_piece_movement_service.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_entity_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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
  }) => PuzzlePieceUI(
    id: id,
    position: position,
    placeZone: zone,
    type: type,
    originalPath: generatePathForType(type, grid.cellSize),
    color: () => Colors.blue,
    centerPoint: const Offset(5, 5),
  );

  test('getZoneAtPosition returns grid, board and null', () {
    expect(service.getZoneAtPosition(const Offset(5, 5), grid, board), PlaceZone.grid);
    expect(service.getZoneAtPosition(const Offset(105, 5), grid, board), PlaceZone.board);
    expect(service.getZoneAtPosition(const Offset(90, 90), grid, board), isNull);
  });

  test('checkCollision detects overlap on grid when preventOverlap=true', () {
    final a = piece(id: 'a', type: PieceType.square, position: const Offset(10, 10));
    final b = piece(id: 'b', type: PieceType.square, position: const Offset(10, 10));

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
    final selected = piece(id: 'a', type: PieceType.square, position: const Offset(999, 999));

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
    expect(board.cellSize * board.columns + board.origin.dx >= result.snappedPosition!.dx, isTrue);
    expect(board.cellSize * board.rows + board.origin.dy >= result.snappedPosition!.dy, isTrue);
  });

  test('lifted piece dropped into the tray shrinks around the finger and stays inside', () {
    final lifted = piece(
      id: 'a',
      type: PieceType.square,
      position: const Offset(140, 20),
      zone: PlaceZone.board,
    ).copyWith(isLifted: true);
    const finger = Offset(145, 25);

    final result = service.computeDropResult(
      selectedPiece: lifted,
      pieceStartPosition: const Offset(110, 10),
      dragStartZone: PlaceZone.board,
      gridConfig: grid,
      boardConfig: board,
      pieces: [lifted],
      preventOverlap: false,
      anchor: finger,
    );

    expect(result.accepted, isTrue);
    expect(result.zone, PlaceZone.board);
    const s = PuzzlePieceUI.defaultTrayScale;
    expect(result.snappedPosition!.dx, closeTo(finger.dx - 5 * s, 1e-9));
    expect(result.snappedPosition!.dy, closeTo(finger.dy - 5 * s, 1e-9));
  });

  test('finger over the tray area sends the piece to the tray', () {
    final lifted = piece(id: 'a', type: PieceType.lShape, position: const Offset(60, 65)).copyWith(isLifted: true);
    const trayArea = Rect.fromLTRB(0, 75, 200, 200);

    final result = service.computeDropResult(
      selectedPiece: lifted,
      pieceStartPosition: const Offset(10, 10),
      dragStartZone: PlaceZone.grid,
      gridConfig: grid,
      boardConfig: board,
      pieces: [lifted],
      preventOverlap: false,
      anchor: const Offset(65, 90),
      trayArea: trayArea,
    );

    expect(result.accepted, isTrue);
    expect(result.zone, PlaceZone.board);
  });

  test('drop over a blocked spot lands on the last free grid position', () {
    final selected = piece(id: 'a', type: PieceType.square, position: const Offset(40, 40));
    final other = piece(id: 'b', type: PieceType.square, position: const Offset(40, 40));

    final result = service.computeDropResult(
      selectedPiece: selected,
      pieceStartPosition: const Offset(110, 10),
      dragStartZone: PlaceZone.board,
      gridConfig: grid,
      boardConfig: board,
      pieces: [selected, other],
      preventOverlap: true,
      fallbackGridPosition: const Offset(10, 10),
    );

    expect(result.accepted, isTrue);
    expect(result.zone, PlaceZone.grid);
    expect(result.snappedPosition, const Offset(10, 10));
  });

  test('drop is rejected when the last free grid position is taken too', () {
    final selected = piece(id: 'a', type: PieceType.square, position: const Offset(10, 10));
    final other = piece(id: 'b', type: PieceType.square, position: const Offset(10, 10));

    final result = service.computeDropResult(
      selectedPiece: selected,
      pieceStartPosition: const Offset(110, 10),
      dragStartZone: PlaceZone.board,
      gridConfig: grid,
      boardConfig: board,
      pieces: [selected, other],
      preventOverlap: true,
      fallbackGridPosition: const Offset(20, 10),
    );

    expect(result.accepted, isFalse);
  });

  test('grid piece dropped outside grid and board goes to the tray', () {
    final selected = piece(id: 'a', type: PieceType.square, position: const Offset(999, 999)).copyWith(isLifted: true);

    final result = service.computeDropResult(
      selectedPiece: selected,
      pieceStartPosition: const Offset(10, 10),
      dragStartZone: PlaceZone.grid,
      gridConfig: grid,
      boardConfig: board,
      pieces: [selected],
      preventOverlap: false,
    );

    expect(result.accepted, isTrue);
    expect(result.zone, PlaceZone.board);
    expect(board.getBounds.inflate(0.01).contains(result.snappedPosition!), isTrue);
    expect(result.move!.from.zone, PlaceZone.grid);
  });

  group('nearestFreeGridPosition', () {
    test('keeps a position that is already free', () {
      final selected = piece(id: 'a', type: PieceType.square, position: const Offset(20, 20));

      final free = service.nearestFreeGridPosition(
        piece: selected,
        pieces: [selected],
        gridConfig: grid,
        boardConfig: board,
      );

      expect(free, const Offset(20, 20));
    });

    test('moves the piece to the closest free cells', () {
      final selected = piece(id: 'a', type: PieceType.square, position: Offset.zero);
      final other = piece(id: 'b', type: PieceType.square, position: Offset.zero);

      final free = service.nearestFreeGridPosition(
        piece: selected,
        pieces: [selected, other],
        gridConfig: grid,
        boardConfig: board,
      );

      expect(free, const Offset(20, 0));
    });

    test('returns null when nothing is free within reach', () {
      final selected = piece(id: 'a', type: PieceType.square, position: Offset.zero);
      final other = piece(id: 'b', type: PieceType.square, position: Offset.zero);

      final free = service.nearestFreeGridPosition(
        piece: selected,
        pieces: [selected, other],
        gridConfig: grid,
        boardConfig: board,
        maxShift: 1,
      );

      expect(free, isNull);
    });
  });

  test('rescaledAround keeps the anchor over the same point of the piece', () {
    final inTray = piece(
      id: 'a',
      type: PieceType.lShape,
      position: const Offset(120, 30),
      zone: PlaceZone.board,
    ).copyWith(rotation: 1.5707963267948966);
    const anchor = Offset(131, 37);
    final local = inTray.transformLocalPoint(const Offset(7, 3));

    final lifted = inTray.rescaledAround(anchor, isLifted: true);
    expect(lifted.scale, 1.0);
    final liftedLocal = lifted.transformLocalPoint(const Offset(7, 3));
    final ratio = 1 / PuzzlePieceUI.defaultTrayScale;
    expect(liftedLocal.dx, closeTo(anchor.dx + (local.dx - anchor.dx) * ratio, 1e-9));
    expect(liftedLocal.dy, closeTo(anchor.dy + (local.dy - anchor.dy) * ratio, 1e-9));

    final back = lifted.rescaledAround(anchor, isLifted: false);
    expect(back.position.dx, closeTo(inTray.position.dx, 1e-9));
    expect(back.position.dy, closeTo(inTray.position.dy, 1e-9));
  });
}
