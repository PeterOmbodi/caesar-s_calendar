part of 'puzzle_bloc.dart';

extension PuzzleBlocLayoutPart on PuzzleBloc {
  FutureOr<void> _onViewSize(final _SetViewSize event, final Emitter<PuzzleState> emit) {
    final hasChanged =
        _lastViewSize != event.viewSize ||
        _lastMaxCell != event.maxCell ||
        _lastTrayScale != event.trayScale ||
        _lastContentInsets != event.contentInsets;
    if (hasChanged && event.viewSize.width > 0 && event.viewSize.height > 0) {
      _lastViewSize = event.viewSize;
      _lastMaxCell = event.maxCell;
      _lastTrayScale = event.trayScale;
      _lastContentInsets = event.contentInsets;
      add(PuzzleEvent.configure());
    }
  }

  Future<void> _configure(final _Configure event, final Emitter<PuzzleState> emit) async {
    final contentRect = _lastContentInsets.deflateRect(Offset.zero & _lastViewSize!);
    final configurationPieces = event.configurationPieces;
    final isInitializing = state.status == GameStatus.initializing || event.toInitial;
    final layout = isInitializing
        ? _layoutService.buildInitialLayout(
            contentRect,
            maxCell: _lastMaxCell,
            trayScale: _lastTrayScale,
            configurationPieces: configurationPieces,
          )
        : _layoutService.rebuildLayout(
            contentRect: contentRect,
            maxCell: _lastMaxCell,
            prevGrid: state.gridConfig,
            prevBoard: state.boardConfig,
            pieces: state.pieces,
            trayScale: _lastTrayScale,
          );
    final newState = state.copyWith(
      gridConfig: layout.gridConfig,
      boardConfig: layout.boardConfig,
      trayArea: layout.trayArea,
      pieces: layout.pieces.toList(),
    );

    if (isInitializing) {
      emit(
        newState.copyWith(
          status: GameStatus.initialized,
          isRestoredSolvedSession: false,
          hasShownSolvedDialog: false,
          solutionIdx: -1,
          selectedPieceId: null,
          moveHistory: [],
          hintedCells: const {},
          moveIndex: 0,
          firstMoveAt: null,
          lastResumedAt: null,
          activeElapsedMs: 0,
          drawnGroup: null,
          drawnGroupCommitStatus: DrawnGroupCommitStatus.tooSmall,
          isDrawingGroup: false,
        ),
      );
    } else {
      emit(newState);
    }

    if (isInitializing && !event.skipSolve) {
      // solving causes UI freezes, wait for initial layout animation to finish
      await Future<void>.delayed(const Duration(milliseconds: 150));
      add(const PuzzleEvent.solve(showResult: false));
    }
  }
}
