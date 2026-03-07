part of 'puzzle_bloc.dart';

extension PuzzleBlocLayoutPart on PuzzleBloc {
  FutureOr<void> _onViewSize(
    final _SetViewSize event,
    final Emitter<PuzzleState> emit,
  ) {
    if (_lastViewSize != event.viewSize &&
        event.viewSize.width > 0 &&
        event.viewSize.height > 0) {
      _lastViewSize = event.viewSize;
      add(PuzzleEvent.configure());
    }
  }

  Future<void> _configure(
    final _Configure event,
    final Emitter<PuzzleState> emit,
  ) async {
    final viewSize = _lastViewSize!;
    final configurationPieces = event.configurationPieces;
    final isInitializing =
        state.status == GameStatus.initializing || event.toInitial;
    final layout = isInitializing
        ? _layoutService.buildInitialLayout(
            viewSize,
            configurationPieces: configurationPieces,
          )
        : _layoutService.rebuildLayout(
            viewSize: viewSize,
            prevGrid: state.gridConfig,
            prevBoard: state.boardConfig,
            pieces: state.pieces,
          );
    final newState = state.copyWith(
      gridConfig: layout.gridConfig,
      boardConfig: layout.boardConfig,
      pieces: layout.pieces.toList(),
    );

    if (isInitializing) {
      emit(
        newState.copyWith(
          status: GameStatus.initialized,
          isRestoredSolvedSession: false,
          hasShownSolvedDialog: false,
          solutionIdx: -1,
          moveHistory: [],
          moveIndex: 0,
          firstMoveAt: null,
          lastResumedAt: null,
          activeElapsedMs: 0,
        ),
      );
    } else {
      emit(newState);
    }

    if (isInitializing) {
      // solving causes UI freezes, wait for initial layout animation to finish
      await Future<void>.delayed(const Duration(milliseconds: 150));
      add(const PuzzleEvent.solve(showResult: false));
    }
  }
}
