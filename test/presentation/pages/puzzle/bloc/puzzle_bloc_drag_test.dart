import 'dart:async';

import 'package:caesar_puzzle/application/contracts/puzzle_history_repository.dart';
import 'package:caesar_puzzle/application/contracts/settings_query.dart';
import 'package:caesar_puzzle/application/models/calendar_day_stats.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/puzzle_history_use_case.dart';
import 'package:caesar_puzzle/application/solve_puzzle_use_case.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/solver_service.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_piece_entity.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_grid_extension.dart';
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

Future<void> _drain() async {
  await Future<void>.delayed(const Duration(milliseconds: 60));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  PuzzleBloc? bloc;

  setUp(() {
    final solveUseCase = SolvePuzzleUseCase(_FakeSolverService());
    final historyUseCase = PuzzleHistoryUseCase(_FakePuzzleHistoryRepository());
    bloc = PuzzleBloc(
      settings: _FakeSettingsQuery(),
      solvePuzzleUseCase: solveUseCase,
      historyUseCase: historyUseCase,
    );
  });

  tearDown(() async {
    await bloc?.close();
  });

  test('onPanUpdate over grid enables preview with snapped position', () async {
    bloc!.add(const PuzzleEvent.setViewSize(Size(1200, 800)));
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final boardPiece =
        bloc!.state.boardPieces.firstWhere((final p) => p.id == 'Square');
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
    expect(bloc!.state.previewPosition,
        bloc!.state.gridConfig.snapToGrid(targetPosition));
  });

  test('onPanEnd outside zones rejects drop and keeps piece at start position',
      () async {
    bloc!.add(const PuzzleEvent.setViewSize(Size(1200, 800)));
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final boardPiece =
        bloc!.state.boardPieces.firstWhere((final p) => p.id == 'Square');
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

    final updated =
        bloc!.state.pieces.firstWhere((final p) => p.id == boardPiece.id);
    expect(updated.position, start);
    expect(updated.placeZone, PlaceZone.board);
    expect(bloc!.state.moveHistory, isEmpty);
  });
}
