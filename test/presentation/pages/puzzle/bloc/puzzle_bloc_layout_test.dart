import 'dart:async';

import 'package:caesar_puzzle/application/contracts/puzzle_history_repository.dart';
import 'package:caesar_puzzle/application/contracts/settings_query.dart';
import 'package:caesar_puzzle/application/models/calendar_day_stats.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/puzzle_history_use_case.dart';
import 'package:caesar_puzzle/application/solve_puzzle_use_case.dart';
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
import 'package:caesar_puzzle/presentation/utils/board_layout_cells.dart';
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
  bool get showSolutionCount => false;

  @override
  bool get separateMoveColors => false;

  @override
  bool get snapToGridOnTransform => false;

  @override
  bool get unlockConfig => true;
}

class _FakeSolverService implements PuzzleSolverService {
  List<PuzzlePieceEntity> lastPieces = const [];

  @override
  Future<Iterable<List<String>>> solve({
    required final Iterable<PuzzlePieceEntity> pieces,
    required final PuzzleGridEntity grid,
    final bool keepUserMoves = false,
    final DateTime? date,
  }) async {
    lastPieces = pieces.toList();
    return const [<String>[], <String>[]];
  }
}

class _FakePuzzleHistoryRepository implements PuzzleHistoryRepository {
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
}
