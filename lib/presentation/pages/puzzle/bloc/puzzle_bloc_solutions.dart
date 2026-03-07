part of 'puzzle_bloc.dart';

extension PuzzleBlocSolutionsPart on PuzzleBloc {
  Future<void> _solve(
    final _Solve event,
    final Emitter<PuzzleState> emit,
  ) async {
    emit(
      state.copyWith(
        status: GameStatus.searchingSolutions,
        solutions: [],
        solutionIdx: -1,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    unawaited(
      _solvePuzzleUseCase
          .call(
        pieces: state.pieces.map((final p) => p.toDomain(state.gridConfig)),
        grid: state.gridConfig,
        date: state.selectedDate,
      )
          .then((final solutions) {
        debugPrint(
          'solving finished, found solutions: ${solutions.length}',
        );
        add(PuzzleEvent.setSolvingResults(solutions));
        if (event.showResult) {
          add(const PuzzleEvent.showSolution(0));
        }
      }),
    );
  }

  FutureOr<void> _setSolvingResults(
    final _SetSolvingResults event,
    final Emitter<PuzzleState> emit,
  ) {
    emit(
      state.copyWith(
        status: GameStatus.solutionsReady,
        solutions: event.solutions.toList(),
        applicableSolutions: _combineSolutions(event.solutions, state.pieces),
      ),
    );
  }

  FutureOr<void> _showSolution(
    final _ShowSolution event,
    final Emitter<PuzzleState> emit,
  ) {
    if (state.solutions.isEmpty && state.status != GameStatus.solutionsReady) {
      add(const PuzzleEvent.solve(showResult: true));
      return Future.value();
    }
    final applicableSolutions = state.applicableSolutions;
    final solutionIds = applicableSolutions.length > event.index
        ? applicableSolutions[event.index]
        : <String, PlacementParams>{};
    final gridPieces = state.gridPieces
        .where((final e) => e.isConfigItem || e.isUsersItem)
        .map(
          (final p) => p.copyWith(
            originalPath: generatePathForType(
              p.type,
              state.gridConfig.cellSize,
            ),
          ),
        )
        .toList();
    for (final solution in solutionIds.entries) {
      final params = solution.value;
      final piece = state.pieces.firstWhere(
        (final p) => p.id == params.pieceId,
      );
      if (gridPieces.firstWhereOrNull((final e) => e.id == piece.id) == null) {
        gridPieces.add(
          _applyPlacementToPiece(piece, params).copyWith(isUsersItem: false),
        );
      }
    }
    emit(
      state.copyWith(
        pieces: gridPieces,
        applicableSolutions: applicableSolutions,
        solutionIdx: event.index,
        moveHistory: [],
        moveIndex: 0,
        status: GameStatus.showingSolution,
      ),
    );
  }
}
