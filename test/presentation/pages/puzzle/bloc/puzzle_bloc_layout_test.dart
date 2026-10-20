import 'dart:async';

import 'package:caesar_puzzle/application/contracts/puzzle_history_repository.dart';
import 'package:caesar_puzzle/application/contracts/settings_query.dart';
import 'package:caesar_puzzle/application/models/calendar_day_stats.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_status.dart';
import 'package:caesar_puzzle/application/puzzle_config_json.dart';
import 'package:caesar_puzzle/application/puzzle_history_use_case.dart';
import 'package:caesar_puzzle/application/solve_puzzle_use_case.dart';
import 'package:caesar_puzzle/core/models/move.dart';
import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/core/models/placement.dart';
import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/solver_service.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_piece_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_board_entity.dart';
import 'package:caesar_puzzle/infrastructure/sync/sync_runner.dart';
import 'package:caesar_puzzle/injection.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/layouts/layout_edit.dart';
import 'package:caesar_puzzle/presentation/utils/board_layout_cells.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSettingsQuery implements SettingsQuery {
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
}

class _FakeSolverService implements PuzzleSolverService {
  List<PuzzlePieceEntity> lastPieces = const [];
  Completer<void>? gate;

  @override
  Future<Iterable<List<String>>> solve({
    required final Iterable<PuzzlePieceEntity> pieces,
    required final PuzzleGridEntity grid,
    final bool keepUserMoves = false,
    final DateTime? date,
  }) async {
    lastPieces = pieces.toList();
    await gate?.future;
    return const [<String>[], <String>[]];
  }
}

class _FakePuzzleHistoryRepository implements PuzzleHistoryRepository {
  final Map<String, String> configs = {};

  @override
  Future<void> clearLocalData() async {}

  @override
  Future<String> createSession(final PuzzleSessionData session) async =>
      'session-id';

  @override
  Future<PuzzleSessionData?> getLatestUnsolvedSession({
    required final DateTime puzzleDate,
  }) async => null;

  @override
  Future<bool> hasAnyLocalSessions() async => false;

  @override
  Stream<int> watchSolvedSolutionCount() => Stream.value(0);

  @override
  Future<String?> getConfigJson(final String configId) async => configs[configId];

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
  }) async => 'cfg';

  @override
  Stream<List<CalendarDayStats>> watchCalendarStats({
    required final DateTime from,
    required final DateTime to,
  }) => const Stream.empty();

  @override
  Stream<List<PuzzleSessionData>> watchSessionsByDate({
    required final DateTime puzzleDate,
  }) => const Stream.empty();

  @override
  Stream<List<PuzzleSessionData>> watchSessionsByMonthDay({
    required final DateTime puzzleDate,
  }) => const Stream.empty();

  @override
  Stream<List<PuzzleSessionData>> watchSessionsInPuzzleDateRange({
    required final DateTime from,
    required final DateTime to,
  }) => const Stream.empty();
}

class _FakeSyncRunner implements SyncRunner {
  @override
  Future<void> dispose() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> runExclusiveSync() async {}

  @override
  void publishProfileNow() {}

  @override
  void requestSync() {}

  @override
  void resume({final bool requestImmediateSync = true}) {}

  @override
  void start({final bool requestImmediateSync = true}) {}

  @override
  void stop() {}
}

class _TestPuzzleBloc extends PuzzleBloc {
  _TestPuzzleBloc({
    required super.settings,
    required super.solvePuzzleUseCase,
    required super.historyUseCase,
  });

  void emitForTest(final PuzzleState state) => emit(state);
}

PuzzlePieceUI _piece({
  required final String id,
  required final PieceType type,
  required final Offset position,
  required final PlaceZone zone,
  final bool isConfigItem = false,
  final bool isUsersItem = true,
}) => PuzzlePieceUI(
  id: id,
  position: position,
  placeZone: zone,
  type: type,
  originalPath: generatePathForType(type, 10),
  color: () => Colors.blue,
  centerPoint: const Offset(5, 5),
  isConfigItem: isConfigItem,
  isUsersItem: isUsersItem,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    if (!getIt.isRegistered<SyncRunner>()) {
      getIt.registerSingleton<SyncRunner>(_FakeSyncRunner());
    }
  });

  tearDown(() async {
    if (getIt.isRegistered<SyncRunner>()) {
      await getIt.unregister<SyncRunner>();
    }
  });

  test('countSolutionsFor solves with the blocks moved to the layout', () async {
    final solver = _FakeSolverService();
    final bloc = _TestPuzzleBloc(
      settings: _FakeSettingsQuery(),
      solvePuzzleUseCase: SolvePuzzleUseCase(solver),
      historyUseCase: PuzzleHistoryUseCase(_FakePuzzleHistoryRepository()),
    );
    const grid = PuzzleGridEntity(cellSize: 10, rows: 7, columns: 7, origin: Position(dx: 0, dy: 0));
    bloc.emitForTest(
      PuzzleState.initial().copyWith(
        gridConfig: grid,
        pieces: [
          _piece(id: 'zone1', type: PieceType.zone1, position: const Offset(60, 0), zone: PlaceZone.grid, isConfigItem: true),
          _piece(id: 'zone2', type: PieceType.zone2, position: const Offset(30, 60), zone: PlaceZone.grid, isConfigItem: true),
          _piece(id: 'Square', type: PieceType.square, position: const Offset(110, 10), zone: PlaceZone.board),
        ],
      ),
    );
    final layout = [PlacementParams('zone1', 0, 6, 0, false), PlacementParams('zone2', 3, 6, 1, false)];

    final count = await bloc.countSolutionsFor(layout, DateTime(2026, 10, 8));

    expect(count, 2);
    final blocked = {for (final p in solver.lastPieces.where((final p) => p.isConfigItem)) ...p.absoluteCells};
    expect(blocked, blockedCellsOf(layout));
    expect(bloc.state.blockedCells, blockedCellsOf([PlacementParams('zone1', 0, 6, 0, false), PlacementParams('zone2', 6, 3, 0, false)]));
    await bloc.close();
  });

  test('restoring a session puts the blocks back to its layout', () async {
    final repository = _FakePuzzleHistoryRepository();
    final bloc = _TestPuzzleBloc(
      settings: _FakeSettingsQuery(),
      solvePuzzleUseCase: SolvePuzzleUseCase(_FakeSolverService()),
      historyUseCase: PuzzleHistoryUseCase(repository),
    );
    const grid = PuzzleGridEntity(cellSize: 10, rows: 7, columns: 7, origin: Position(dx: 0, dy: 0));
    bloc.emitForTest(
      PuzzleState.initial().copyWith(
        gridConfig: grid,
        pieces: [
          _piece(id: 'zone1', type: PieceType.zone1, position: const Offset(60, 0), zone: PlaceZone.grid, isConfigItem: true),
          _piece(id: 'zone2', type: PieceType.zone2, position: const Offset(30, 60), zone: PlaceZone.grid, isConfigItem: true),
          _piece(id: 'Square', type: PieceType.square, position: const Offset(110, 10), zone: PlaceZone.board),
        ],
      ),
    );
    final layout = [PlacementParams('zone1', 3, 0, 0, false), PlacementParams('zone2', 6, 3, 0, false)];
    repository.configs['custom'] = PuzzleConfigJson.encode(layout);
    final move = MovePiece(
      'Square',
      from: MovePlacement(position: const Position(dx: 11, dy: 1)),
      to: MovePlacement(zone: PlaceZone.grid, position: const Position(dx: 2, dy: 2)),
    );

    bloc.add(
      PuzzleEvent.restoreSession(
        PuzzleSessionData(
          id: 's1',
          puzzleDate: DateTime(2026, 10, 8),
          configId: 'custom',
          difficulty: PuzzleSessionDifficulty.hard,
          status: PuzzleSessionStatus.unsolved,
          startedAt: 0,
          firstMoveAt: 0,
          lastResumedAt: null,
          activeElapsedMs: 1000,
          updatedAt: 0,
          completedAt: null,
          moveIndex: 1,
          moveHistoryVersion: 1,
          pieces: const [],
          moveHistory: [move],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(bloc.state.blockedCells, blockedCellsOf(layout));
    expect(bloc.state.isPieceInGrid('Square'), isTrue);
    await bloc.close();
  });

  group('layout edit', () {
    late _FakeSolverService solver;
    late _TestPuzzleBloc bloc;
    const grid = PuzzleGridEntity(cellSize: 10, rows: 7, columns: 7, origin: Position(dx: 0, dy: 0));
    final gameMove = MovePiece(
      'Square',
      from: MovePlacement(position: const Position.zero()),
      to: MovePlacement(zone: PlaceZone.grid, position: const Position.zero()),
    );
    final solution = {'Square': PlacementParams('Square', 0, 0, 0, false)};

    setUp(() {
      solver = _FakeSolverService();
      bloc = _TestPuzzleBloc(
        settings: _FakeSettingsQuery(),
        solvePuzzleUseCase: SolvePuzzleUseCase(solver),
        historyUseCase: PuzzleHistoryUseCase(_FakePuzzleHistoryRepository()),
      );
      bloc.emitForTest(
        PuzzleState.initial().copyWith(
          status: GameStatus.playing,
          gridConfig: grid,
          pieces: [
            _piece(id: 'zone1', type: PieceType.zone1, position: const Offset(60, 0), zone: PlaceZone.grid, isConfigItem: true),
            _piece(id: 'zone2', type: PieceType.zone2, position: const Offset(30, 60), zone: PlaceZone.grid, isConfigItem: true),
            _piece(id: 'Square', type: PieceType.square, position: Offset.zero, zone: PlaceZone.grid),
          ],
          moveHistory: [gameMove],
          moveIndex: 1,
          solutions: [solution],
          applicableSolutions: [solution],
          firstMoveAt: DateTime.now().millisecondsSinceEpoch - 5000,
          lastResumedAt: DateTime.now().millisecondsSinceEpoch - 1000,
          activeElapsedMs: 4000,
        ),
      );
    });

    tearDown(() => bloc.close());

    Future<void> moveBlocks() async {
      bloc.emitForTest(
        bloc.state.copyWith(
          pieces: [
            for (final p in bloc.state.pieces) p.id == 'zone1' ? p.copyWith(position: const Offset(0, 30)) : p,
          ],
          moveHistory: [...bloc.state.moveHistory, gameMove],
          moveIndex: 2,
          status: GameStatus.playing,
        ),
      );
      await Future<void>.delayed(Duration.zero);
    }

    test('start keeps the game pieces in place and stops the timer', () async {
      bloc.add(const PuzzleEvent.startLayoutEdit());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isEditingLayout, isTrue);
      expect(bloc.state.isPieceInGrid('Square'), isTrue);
      expect(bloc.state.lastResumedAt, isNull);
      expect(bloc.state.activeElapsedMs, greaterThanOrEqualTo(5000));
    });

    test('cancel puts back the blocks, the move history and the timer', () async {
      final blocked = bloc.state.blockedCells;
      bloc.add(const PuzzleEvent.startLayoutEdit());
      await Future<void>.delayed(Duration.zero);
      await moveBlocks();
      expect(bloc.state.isLayoutChanged, isTrue);

      bloc.add(const PuzzleEvent.cancelLayoutEdit());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isEditingLayout, isFalse);
      expect(bloc.state.blockedCells, blocked);
      expect(bloc.state.moveIndex, 1);
      expect(bloc.state.moveHistory, hasLength(1));
      expect(bloc.state.solutions, [solution]);
      expect(bloc.state.status, GameStatus.playing);
      expect(bloc.state.lastResumedAt, isNotNull);
    });

    test('a solver run from the edit does not reach the game after cancel', () async {
      bloc.add(const PuzzleEvent.startLayoutEdit());
      await Future<void>.delayed(Duration.zero);
      await moveBlocks();
      solver.gate = Completer<void>();
      bloc.add(const PuzzleEvent.solve(showResult: false));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      bloc.add(const PuzzleEvent.cancelLayoutEdit());
      await Future<void>.delayed(Duration.zero);
      solver.gate!.complete();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bloc.state.solutions, [solution]);
      expect(bloc.state.status, GameStatus.playing);
    });
  });
}
