import 'dart:async';

import 'package:caesar_puzzle/application/contracts/puzzle_history_repository.dart';
import 'package:caesar_puzzle/application/contracts/settings_query.dart';
import 'package:caesar_puzzle/application/models/calendar_day_stats.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/puzzle_history_use_case.dart';
import 'package:caesar_puzzle/application/solve_puzzle_use_case.dart';
import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/core/models/move.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/solver_service.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_piece_entity.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_grid_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSettingsQuery implements SettingsQuery {
  @override
  bool get autoLockConfig => false;

  @override
  bool get preventOverlap => false;

  @override
  bool get requireSolutions => false;

  @override
  bool get showSolutionCount => false;

  @override
  bool get separateMoveColors => false;

  @override
  bool get snapToGridOnTransform => false;

  @override
  bool get unlockConfig => true;
}

class _FakeSolverService implements PuzzleSolverService {
  @override
  Future<Iterable<List<String>>> solve({
    required final Iterable<PuzzlePieceEntity> pieces,
    required final PuzzleGridEntity grid,
    final bool keepUserMoves = false,
    final DateTime? date,
  }) async => const <List<String>>[];
}

class _FakePuzzleHistoryRepository implements PuzzleHistoryRepository {
  @override
  Future<void> clearLocalData() async {}

  @override
  Future<String> createSession(final PuzzleSessionData session) async => 'session-id';

  @override
  Future<PuzzleSessionData?> getLatestUnsolvedSession({required final DateTime puzzleDate}) async => null;

  @override
  Future<bool> hasAnyLocalSessions() async => false;

  @override
  Future<void> markSessionSolved({
    required final String sessionId,
    required final DateTime puzzleDate,
    required final String configId,
    required final Iterable<String> solutionSignatures,
    final DateTime? completedAt,
  }) async {}

  @override
  Future<void> updateSession(final PuzzleSessionData session) async {}

  @override
  Future<void> upsertSolutionCount({
    required final DateTime puzzleDate,
    required final String configId,
    required final int totalSolutions,
    final DateTime? computedAt,
  }) async {}

  @override
  Future<String> upsertConfig({required final String configJson, final DateTime? createdAt}) async => 'cfg';

  @override
  Stream<List<CalendarDayStats>> watchCalendarStats({required final DateTime from, required final DateTime to}) =>
      const Stream.empty();

  @override
  Stream<List<PuzzleSessionData>> watchSessionsByDate({required final DateTime puzzleDate}) => const Stream.empty();

  @override
  Stream<List<PuzzleSessionData>> watchSessionsByMonthDay({required final DateTime puzzleDate}) => const Stream.empty();
}

Future<void> _drain() async {
  await Future<void>.delayed(const Duration(milliseconds: 60));
}

Offset _cellCenter(final PuzzleBloc bloc, final int row, final int col) {
  final grid = bloc.state.gridConfig;
  return grid.cellTopLeft(Cell(row, col)) + Offset(grid.cellSize / 2, grid.cellSize / 2);
}

Future<void> _drawCells(final PuzzleBloc bloc, final List<Cell> cells) async {
  bloc.add(PuzzleEvent.onPanStart(_cellCenter(bloc, cells.first.row, cells.first.col)));
  await _drain();
  for (final cell in cells.skip(1)) {
    bloc.add(PuzzleEvent.onPanUpdate(_cellCenter(bloc, cell.row, cell.col)));
    await _drain();
  }
  bloc.add(PuzzleEvent.onPanEnd(_cellCenter(bloc, cells.last.row, cells.last.col)));
  await _drain();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  PuzzleBloc? bloc;

  setUp(() {
    final solveUseCase = SolvePuzzleUseCase(_FakeSolverService());
    final historyUseCase = PuzzleHistoryUseCase(_FakePuzzleHistoryRepository());
    bloc = PuzzleBloc(settings: _FakeSettingsQuery(), solvePuzzleUseCase: solveUseCase, historyUseCase: historyUseCase);
  });

  tearDown(() async {
    await bloc?.close();
  });

  test('difficulty change before first move replaces stale easy value', () {
    bloc!.markCurrentSessionDifficulty(PuzzleSessionDifficulty.easy);
    expect(bloc!.currentSessionDifficulty, PuzzleSessionDifficulty.easy);

    bloc!.markCurrentSessionDifficulty(PuzzleSessionDifficulty.medium);

    expect(bloc!.currentSessionDifficulty, PuzzleSessionDifficulty.medium);
  });

  test('onPanUpdate over grid enables preview with snapped position', () async {
    bloc!.add(const PuzzleEvent.setViewSize(Size(1200, 800)));
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final boardPiece = bloc!.state.boardPieces.firstWhere((final p) => p.id == 'Square');
    final panStartPoint = boardPiece.position + boardPiece.centerPoint;
    bloc!.add(PuzzleEvent.onPanStart(panStartPoint));
    await _drain();
    expect(bloc!.state.dragStartOffset, isNotNull);

    final targetPosition = Offset(
      bloc!.state.gridConfig.origin.dx + bloc!.state.gridConfig.cellSize * 2,
      bloc!.state.gridConfig.origin.dy + bloc!.state.gridConfig.cellSize * 2,
    );
    final local = targetPosition + bloc!.state.dragStartOffset!;
    bloc!.add(PuzzleEvent.onPanUpdate(local));
    await _drain();

    expect(bloc!.state.showPreview, isTrue);
    expect(bloc!.state.previewPosition, bloc!.state.gridConfig.snapToGrid(targetPosition));
  });

  test('pan from free grid cell creates and extends drawn group', () async {
    bloc!.add(const PuzzleEvent.setViewSize(Size(1200, 800)));
    await Future<void>.delayed(const Duration(milliseconds: 250));

    await _drawCells(bloc!, [Cell(0, 0), Cell(0, 1), Cell(1, 1)]);

    expect(bloc!.state.isDrawingGroup, isFalse);
    expect(bloc!.state.drawnGroup?.cellSet, {Cell(0, 0), Cell(0, 1), Cell(1, 1)});
  });

  test('existing drawn group can be extended only from group cell', () async {
    bloc!.add(const PuzzleEvent.setViewSize(Size(1200, 800)));
    await Future<void>.delayed(const Duration(milliseconds: 250));

    await _drawCells(bloc!, [Cell(0, 0)]);

    bloc!.add(PuzzleEvent.onPanStart(_cellCenter(bloc!, 0, 1)));
    await _drain();
    bloc!.add(PuzzleEvent.onPanUpdate(_cellCenter(bloc!, 0, 2)));
    await _drain();
    bloc!.add(PuzzleEvent.onPanEnd(_cellCenter(bloc!, 0, 2)));
    await _drain();

    expect(bloc!.state.drawnGroup?.cellSet, {Cell(0, 0)});

    bloc!.add(PuzzleEvent.onPanStart(_cellCenter(bloc!, 0, 0)));
    await _drain();
    bloc!.add(PuzzleEvent.onPanUpdate(_cellCenter(bloc!, 0, 1)));
    await _drain();
    bloc!.add(PuzzleEvent.onPanEnd(_cellCenter(bloc!, 0, 1)));
    await _drain();

    expect(bloc!.state.drawnGroup?.cellSet, {Cell(0, 0), Cell(0, 1)});
  });

  test('double tap on matching drawn group moves board piece to grid', () async {
    bloc!.add(const PuzzleEvent.setViewSize(Size(1200, 800)));
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final squareCells = [Cell(0, 0), Cell(0, 1), Cell(1, 1), Cell(1, 0), Cell(2, 0), Cell(2, 1)];
    await _drawCells(bloc!, squareCells);

    bloc!.add(PuzzleEvent.onDoubleTapDown(_cellCenter(bloc!, 0, 0)));
    await _drain();

    final square = bloc!.state.pieces.firstWhere((final p) => p.id == 'Square');
    expect(square.placeZone, PlaceZone.grid);
    expect(square.cells(bloc!.state.gridConfig.origin, bloc!.state.gridConfig.cellSize), squareCells.toSet());
    expect(bloc!.state.drawnGroup, isNull);
    expect(bloc!.state.moveHistory, hasLength(1));
  });

  test('double tap on matching drawn group can move grid piece again', () async {
    bloc!.add(const PuzzleEvent.setViewSize(Size(1200, 800)));
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final firstCells = [Cell(0, 0), Cell(0, 1), Cell(1, 1), Cell(1, 0), Cell(2, 0), Cell(2, 1)];
    await _drawCells(bloc!, firstCells);
    bloc!.add(PuzzleEvent.onDoubleTapDown(_cellCenter(bloc!, 0, 0)));
    await _drain();

    final secondCells = [Cell(3, 0), Cell(3, 1), Cell(4, 1), Cell(4, 0), Cell(5, 0), Cell(5, 1)];
    await _drawCells(bloc!, secondCells);
    bloc!.add(PuzzleEvent.onDoubleTapDown(_cellCenter(bloc!, 3, 0)));
    await _drain();

    final square = bloc!.state.pieces.firstWhere((final p) => p.id == 'Square');
    expect(square.placeZone, PlaceZone.grid);
    expect(square.cells(bloc!.state.gridConfig.origin, bloc!.state.gridConfig.cellSize), secondCells.toSet());
    expect(bloc!.state.moveHistory, hasLength(2));
  });

  test('drawn group commit preserves transform data for undo', () async {
    bloc!.add(const PuzzleEvent.setViewSize(Size(1200, 800)));
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final originalSquare = bloc!.state.boardPieces.firstWhere((final p) => p.id == 'Square');
    final rotatedSquareCells = [Cell(0, 0), Cell(0, 1), Cell(0, 2), Cell(1, 2), Cell(1, 1), Cell(1, 0)];
    await _drawCells(bloc!, rotatedSquareCells);

    bloc!.add(PuzzleEvent.onDoubleTapDown(_cellCenter(bloc!, 0, 0)));
    await _drain();

    final placedSquare = bloc!.state.pieces.firstWhere((final p) => p.id == 'Square');
    expect(placedSquare.placeZone, PlaceZone.grid);
    expect(placedSquare.rotation, isNot(originalSquare.rotation));

    bloc!.add(const PuzzleEvent.undo());
    await _drain();

    final restoredSquare = bloc!.state.pieces.firstWhere((final p) => p.id == 'Square');
    expect(restoredSquare.placeZone, PlaceZone.board);
    expect(restoredSquare.position, originalSquare.position);
    expect(restoredSquare.rotation, originalSquare.rotation);
    expect(restoredSquare.isFlipped, originalSquare.isFlipped);
  });

  test('drawn group commit marks moved piece as user item', () async {
    bloc!.add(const PuzzleEvent.setViewSize(Size(1200, 800)));
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final square = bloc!.state.boardPieces.firstWhere((final p) => p.id == 'Square');
    final pieces = bloc!.state.pieces.map((final p) => p.id == square.id ? p.copyWith(isUsersItem: false) : p).toList();
    (bloc! as dynamic).emit(bloc!.state.copyWith(pieces: pieces));

    final squareCells = [Cell(0, 0), Cell(0, 1), Cell(1, 1), Cell(1, 0), Cell(2, 0), Cell(2, 1)];
    await _drawCells(bloc!, squareCells);
    bloc!.add(PuzzleEvent.onDoubleTapDown(_cellCenter(bloc!, 0, 0)));
    await _drain();

    final movedSquare = bloc!.state.pieces.firstWhere((final p) => p.id == 'Square');
    expect(movedSquare.isUsersItem, isTrue);
    expect(bloc!.state.moveHistory.whereType<HintMove>(), isEmpty);
    expect(bloc!.state.moveHistory.whereType<MovePiece>(), hasLength(1));
  });

  test('tap down emitted after drawn commit does not select committed piece', () async {
    bloc!.add(const PuzzleEvent.setViewSize(Size(1200, 800)));
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final squareCells = [Cell(0, 0), Cell(0, 1), Cell(1, 1), Cell(1, 0), Cell(2, 0), Cell(2, 1)];
    await _drawCells(bloc!, squareCells);
    final tapPosition = _cellCenter(bloc!, 0, 0);

    bloc!.add(PuzzleEvent.onDoubleTapDown(tapPosition));
    await _drain();
    bloc!.add(PuzzleEvent.onTapDown(tapPosition));
    await _drain();

    expect(bloc!.state.selectedPiece, isNull);
    final square = bloc!.state.pieces.firstWhere((final p) => p.id == 'Square');
    expect(square.isUsersItem, isTrue);
  });

  test('tap up then tap down after drawn commit does not select committed piece', () async {
    bloc!.add(const PuzzleEvent.setViewSize(Size(1200, 800)));
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final squareCells = [Cell(0, 0), Cell(0, 1), Cell(1, 1), Cell(1, 0), Cell(2, 0), Cell(2, 1)];
    await _drawCells(bloc!, squareCells);
    final tapPosition = _cellCenter(bloc!, 0, 0);

    bloc!.add(PuzzleEvent.onDoubleTapDown(tapPosition));
    await _drain();
    bloc!.add(PuzzleEvent.onTapUp(tapPosition));
    await _drain();
    bloc!.add(PuzzleEvent.onTapDown(tapPosition));
    await _drain();

    expect(bloc!.state.selectedPiece, isNull);
  });

  test('manual flip of hint piece marks it as user item', () async {
    bloc!.add(const PuzzleEvent.setViewSize(Size(1200, 800)));
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final square = bloc!.state.boardPieces.firstWhere((final p) => p.id == 'Square');
    final pieces = bloc!.state.pieces.map((final p) => p.id == square.id ? p.copyWith(isUsersItem: false) : p).toList();
    (bloc! as dynamic).emit(bloc!.state.copyWith(pieces: pieces));

    final hintedSquare = bloc!.state.pieces.firstWhere((final p) => p.id == 'Square');
    bloc!.add(PuzzleEvent.onDoubleTapDown(hintedSquare.position + hintedSquare.centerPoint));
    await _drain();

    final updatedSquare = bloc!.state.pieces.firstWhere((final p) => p.id == 'Square');
    expect(updatedSquare.isUsersItem, isTrue);
  });

  test('onPanEnd outside zones rejects drop and keeps piece at start position', () async {
    bloc!.add(const PuzzleEvent.setViewSize(Size(1200, 800)));
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final boardPiece = bloc!.state.boardPieces.firstWhere((final p) => p.id == 'Square');
    final start = boardPiece.position;
    final panStartPoint = start + boardPiece.centerPoint;
    bloc!.add(PuzzleEvent.onPanStart(panStartPoint));
    await _drain();
    expect(bloc!.state.dragStartOffset, isNotNull);

    final outsidePosition = const Offset(-500, -500);
    final local = outsidePosition + bloc!.state.dragStartOffset!;
    bloc!.add(PuzzleEvent.onPanUpdate(local));
    await _drain();

    bloc!.add(const PuzzleEvent.onPanEnd(Offset.zero));
    await _drain();

    final updated = bloc!.state.pieces.firstWhere((final p) => p.id == boardPiece.id);
    expect(updated.position, start);
    expect(updated.placeZone, PlaceZone.board);
    expect(bloc!.state.moveHistory, isEmpty);
  });

  test('onPanEnd keeps existing firstMoveAt instead of resetting timer start', () async {
    bloc!.add(const PuzzleEvent.setViewSize(Size(1200, 800)));
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final boardPiece = bloc!.state.boardPieces.firstWhere((final p) => p.id == 'Square');
    bloc!.add(PuzzleEvent.rotatePiece(boardPiece));
    await _drain();

    final firstMoveAtBeforeDrop = bloc!.state.firstMoveAt;
    expect(firstMoveAtBeforeDrop, isNotNull);

    await Future<void>.delayed(const Duration(milliseconds: 30));

    final refreshedPiece = bloc!.state.boardPieces.firstWhere((final p) => p.id == 'Square');
    final panStartPoint = refreshedPiece.position + refreshedPiece.centerPoint;
    bloc!.add(PuzzleEvent.onPanStart(panStartPoint));
    await _drain();
    expect(bloc!.state.dragStartOffset, isNotNull);

    final targetPosition = Offset(
      bloc!.state.gridConfig.origin.dx + bloc!.state.gridConfig.cellSize * 2,
      bloc!.state.gridConfig.origin.dy + bloc!.state.gridConfig.cellSize * 2,
    );
    final local = targetPosition + bloc!.state.dragStartOffset!;
    bloc!.add(PuzzleEvent.onPanUpdate(local));
    await _drain();
    bloc!.add(const PuzzleEvent.onPanEnd(Offset.zero));
    await _drain();

    expect(bloc!.state.firstMoveAt, firstMoveAtBeforeDrop);
  });
}
