import 'package:caesar_puzzle/application/race/noop_session_recorder.dart';
import 'package:caesar_puzzle/application/race/race_settings_query.dart';
import 'package:caesar_puzzle/application/solve_puzzle_use_case.dart';
import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/core/models/placement.dart';
import 'package:caesar_puzzle/domain/algorithms/dancing_links/solver_service.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_piece_entity.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_grid_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _FakeSolverService implements PuzzleSolverService {
  @override
  Future<Iterable<List<String>>> solve({
    required final Iterable<PuzzlePieceEntity> pieces,
    required final PuzzleGridEntity grid,
    final bool keepUserMoves = false,
    final DateTime? date,
  }) async => const <List<String>>[];
}

class _TestPuzzleBloc extends PuzzleBloc {
  _TestPuzzleBloc({super.mode})
    : super(
        settings: const RaceSettingsQuery(),
        solvePuzzleUseCase: SolvePuzzleUseCase(_FakeSolverService()),
        sessionRecorder: const NoopSessionRecorder(),
      );

  void emitForTest(final PuzzleState state) => emit(state);
}

Future<void> _drain() => Future<void>.delayed(const Duration(milliseconds: 60));

PuzzlePieceUI _square(final PuzzleBloc bloc) => bloc.state.pieces.firstWhere((final p) => p.id == 'Square');

Future<void> _layOut(final PuzzleBloc bloc) async {
  bloc.add(const PuzzleEvent.setViewSize(Size(393, 640), maxCell: ScreenSpec.compactMaxCell));
  await Future<void>.delayed(const Duration(milliseconds: 250));
}

// Leaves the square as the only piece, one move away from the only solution.
Future<void> _oneMoveFromSolved(final _TestPuzzleBloc bloc) async {
  await _layOut(bloc);
  final solution = <String, PlacementParams>{'Square': PlacementParams('Square', 2, 2, 0, false)};
  bloc.emitForTest(
    bloc.state.copyWith(
      status: GameStatus.playing,
      pieces: [_square(bloc)],
      solutions: [solution],
      applicableSolutions: [solution],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _TestPuzzleBloc bloc;

  tearDown(() => bloc.close());

  group('race', () {
    setUp(() => bloc = _TestPuzzleBloc(mode: PuzzleMode.race));

    test('placing the last piece solves the puzzle', () async {
      await _oneMoveFromSolved(bloc);
      final square = _square(bloc);
      bloc.add(PuzzleEvent.onPanStart(square.transformLocalPoint(square.centerPoint)));
      await _drain();
      final pointer = bloc.state.gridConfig.cellTopLeft(Cell(2, 2)) + bloc.state.dragStartOffset!;
      bloc.add(PuzzleEvent.onPanUpdate(pointer));
      await _drain();
      bloc.add(PuzzleEvent.onPanEnd(pointer));
      await _drain();

      expect(_square(bloc).placeZone, PlaceZone.grid);
      expect(bloc.state.status, GameStatus.solvedByUser);
    });

    test('hint and solutions are ignored', () async {
      await _oneMoveFromSolved(bloc);

      bloc.add(const PuzzleEvent.showHint());
      await _drain();
      expect(_square(bloc).placeZone, PlaceZone.board);

      bloc.add(const PuzzleEvent.showSolution(0));
      await _drain();
      expect(bloc.state.status, GameStatus.playing);
      expect(bloc.state.solutionIdx, -1);
    });

    test('the date cannot be changed from outside', () async {
      await _layOut(bloc);
      final date = bloc.state.selectedDate;

      bloc.add(PuzzleEvent.setPuzzleDate(date.add(const Duration(days: 40))));
      await _drain();

      expect(bloc.state.selectedDate, date);
    });

    test('startRace starts a new game for the given date', () async {
      await _layOut(bloc);

      bloc.add(PuzzleEvent.startRace(date: DateTime(2026, 3, 5, 14, 30)));
      await Future<void>.delayed(const Duration(milliseconds: 250));

      expect(bloc.state.selectedDate, DateTime(2026, 3, 5));
      expect(bloc.state.moveHistory, isEmpty);
      expect(bloc.state.boardPieces.where((final p) => !p.isConfigItem), hasLength(8));
    });

    test('never counts for records', () async {
      expect(await bloc.countsForRecords(), isFalse);
    });
  });

  test('a daily game ignores startRace', () async {
    bloc = _TestPuzzleBloc();
    await _layOut(bloc);
    final date = bloc.state.selectedDate;

    bloc.add(PuzzleEvent.startRace(date: date.add(const Duration(days: 40))));
    await _drain();

    expect(bloc.state.selectedDate, date);
  });
}
