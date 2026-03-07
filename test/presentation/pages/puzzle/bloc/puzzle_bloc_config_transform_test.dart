import 'dart:async';

import 'package:caesar_puzzle/application/contracts/puzzle_history_repository.dart';
import 'package:caesar_puzzle/application/contracts/settings_query.dart';
import 'package:caesar_puzzle/application/models/calendar_day_stats.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/puzzle_history_use_case.dart';
import 'package:caesar_puzzle/application/solve_puzzle_use_case.dart';
import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/solver_service.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_board_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_piece_entity.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_utils.dart';
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
  }) async =>
      const <List<String>>[];
}

class _FakePuzzleHistoryRepository implements PuzzleHistoryRepository {
  @override
  Future<String> createSession(final PuzzleSessionData session) async =>
      'session-id';

  @override
  Future<PuzzleSessionData?> getLatestUnsolvedSession({
    required final DateTime puzzleDate,
  }) async =>
      null;

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
  Future<String> upsertConfig({
    required final String configJson,
    final DateTime? createdAt,
  }) async =>
      'cfg';

  @override
  Stream<List<CalendarDayStats>> watchCalendarStats({
    required final DateTime from,
    required final DateTime to,
  }) =>
      const Stream.empty();

  @override
  Stream<List<PuzzleSessionData>> watchSessionsByDate({
    required final DateTime puzzleDate,
  }) =>
      const Stream.empty();

  @override
  Stream<List<PuzzleSessionData>> watchSessionsByMonthDay({
    required final DateTime puzzleDate,
  }) =>
      const Stream.empty();
}

PuzzlePieceUI _configPiece({
  required final String id,
  required final Offset position,
}) =>
    PuzzlePieceUI(
      id: id,
      position: position,
      placeZone: PlaceZone.grid,
      type: PieceType.square,
      originalPath: generatePathForType(PieceType.square, 10),
      color: () => Colors.blue,
      centerPoint: const Offset(5, 5),
      isConfigItem: true,
      isUsersItem: true,
    );

Future<void> _drain() async {
  await Future<void>.delayed(const Duration(milliseconds: 40));
}

class _TestPuzzleBloc extends PuzzleBloc {
  _TestPuzzleBloc({
    required super.settings,
    required super.solvePuzzleUseCase,
    required super.historyUseCase,
  });

  void emitForTest(final PuzzleState state) => emit(state);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _TestPuzzleBloc bloc;

  setUp(() {
    bloc = _TestPuzzleBloc(
      settings: _FakeSettingsQuery(),
      solvePuzzleUseCase: SolvePuzzleUseCase(_FakeSolverService()),
      historyUseCase: PuzzleHistoryUseCase(_FakePuzzleHistoryRepository()),
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  test('rotate config item is cancelled when overlap with another config item',
      () async {
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
    final a = _configPiece(id: 'A', position: const Offset(10, 10));
    final b = _configPiece(id: 'B', position: const Offset(10, 10));

    bloc.emitForTest(
      PuzzleState.initial().copyWith(
        status: GameStatus.playing,
        gridConfig: grid,
        boardConfig: board,
        pieces: [a, b],
      ),
    );

    bloc.add(PuzzleEvent.rotatePiece(a));
    await _drain();

    final updatedA = bloc.state.pieces.firstWhere((final p) => p.id == 'A');
    expect(updatedA.rotation, a.rotation);
    expect(bloc.state.moveHistory, isEmpty);
  });

  test('flip config item is cancelled when overlap with another config item',
      () async {
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
    final a = _configPiece(id: 'A', position: const Offset(10, 10));
    final b = _configPiece(id: 'B', position: const Offset(10, 10));

    bloc.emitForTest(
      PuzzleState.initial().copyWith(
        status: GameStatus.playing,
        gridConfig: grid,
        boardConfig: board,
        pieces: [a, b],
      ),
    );

    final tapPosition = a.position + a.centerPoint;
    bloc.add(PuzzleEvent.onDoubleTapDown(tapPosition));
    await _drain();

    // onDoubleTapDown selects top-most piece at point (B in this setup)
    final updatedB = bloc.state.pieces.firstWhere((final p) => p.id == 'B');
    expect(updatedB.isFlipped, b.isFlipped);
    expect(bloc.state.moveHistory, isEmpty);
  });
}
