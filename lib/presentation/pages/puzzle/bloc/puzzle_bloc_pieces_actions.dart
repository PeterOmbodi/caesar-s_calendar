part of 'puzzle_bloc.dart';

extension PuzzleBlocPiecesActionsPart on PuzzleBloc {
  FutureOr<void> _flipPiece(
    final _OnDoubleTapDown event,
    final Emitter<PuzzleState> emit,
  ) {
    final selectedPiece = _findPieceAtPosition(event.localPosition);
    if (selectedPiece != null &&
        (!selectedPiece.isConfigItem || _settings.unlockConfig)) {
      final prevState = state;
      final flippedPiece = selectedPiece.copyWith(
        isFlipped: !selectedPiece.isFlipped,
      );
      final shouldSnap = selectedPiece.placeZone == PlaceZone.grid &&
          (_settings.snapToGridOnTransform || selectedPiece.isConfigItem);
      final (pieceToSave, snapMove) = shouldSnap
          ? _moveHistoryService.maybeSnap(
              selectedPiece: flippedPiece,
              grid: state.gridConfig,
            )
          : (flippedPiece, null);
      final move = FlipPiece(
        flippedPiece.id,
        snapMove,
        isFlipped: flippedPiece.isFlipped,
      );
      final tentativePieces = _updatePieceInList(pieceToSave);
      if (selectedPiece.isConfigItem &&
          (_movementHandler.checkCollision(
                piece: pieceToSave,
                newPosition: pieceToSave.position,
                zone: pieceToSave.placeZone,
                preventOverlap: true,
                pieces: state.pieces,
                gridConfig: state.gridConfig,
                boardConfig: state.boardConfig,
              ) ||
              _hasConfigOverlap(tentativePieces))) {
        return Future.value();
      }
      final pieces = tentativePieces;
      final shouldResolve = selectedPiece.isConfigItem;
      final applicableSolutions = shouldResolve
          ? <Map<String, PlacementParams>>[]
          : _combineSolutions(state.solutions, pieces);
      final nextState = state.copyWith(
        pieces: pieces,
        moveHistory: [...state.moveHistory, move],
        moveIndex: state.moveIndex + 1,
        status: _getStatus(pieces),
        applicableSolutions: applicableSolutions,
      );
      final timedState = _resumeTimerAfterUserAction(
        prevState: prevState,
        nextState: nextState,
      );
      emit(timedState);
      _persistHistoryChange(prevState: prevState, nextState: timedState);
      if (shouldResolve) {
        add(const PuzzleEvent.solve(showResult: false));
      }
    }
  }

  FutureOr<void> _rotatePiece(
    final _RotatePiece event,
    final Emitter<PuzzleState> emit,
  ) {
    final prevState = state;
    final selectedPiece = event.piece.copyWith(
      rotation: _stepRotation(event.piece.rotation),
    );
    final shouldSnap = event.piece.placeZone == PlaceZone.grid &&
        (_settings.snapToGridOnTransform || selectedPiece.isConfigItem);
    final (pieceToSave, snapMove) = shouldSnap
        ? _moveHistoryService.maybeSnap(
            selectedPiece: selectedPiece,
            grid: state.gridConfig,
          )
        : (selectedPiece, null);
    final move = RotatePiece(
      selectedPiece.id,
      snapMove,
      rotation: selectedPiece.rotation,
    );
    final tentativePieces = _updatePieceInList(pieceToSave);
    if (selectedPiece.isConfigItem &&
        (_movementHandler.checkCollision(
              piece: pieceToSave,
              newPosition: pieceToSave.position,
              zone: pieceToSave.placeZone,
              preventOverlap: true,
              pieces: state.pieces,
              gridConfig: state.gridConfig,
              boardConfig: state.boardConfig,
            ) ||
            _hasConfigOverlap(tentativePieces))) {
      return Future.value();
    }
    final pieces = tentativePieces;
    final shouldResolve = selectedPiece.isConfigItem;
    final applicableSolutions = shouldResolve
        ? <Map<String, PlacementParams>>[]
        : _combineSolutions(state.solutions, pieces);
    final nextState = state.copyWith(
      pieces: pieces,
      moveHistory: [...state.moveHistory, move],
      moveIndex: state.moveIndex + 1,
      status: _getStatus(pieces),
      applicableSolutions: applicableSolutions,
    );
    final timedState = _resumeTimerAfterUserAction(
      prevState: prevState,
      nextState: nextState,
    );
    emit(timedState);
    _persistHistoryChange(prevState: prevState, nextState: timedState);
    if (shouldResolve) {
      add(const PuzzleEvent.solve(showResult: false));
    }
  }

  FutureOr<void> _showHint(
    final _ShowHint event,
    final Emitter<PuzzleState> emit,
  ) {
    final prevState = state;
    final possibleSolutions = state.applicableSolutions.length;
    final solutionIndex = possibleSolutions < 2
        ? 0
        : math.Random().nextInt(possibleSolutions - 1);
    final encodedSolution = state.applicableSolutions[solutionIndex];
    final onGridIds = state.gridPieces.map((final e) => e.id);
    final encodedPieces = encodedSolution.entries
        .where((final e) => !onGridIds.contains(e.key))
        .toList();
    final pececIndex = encodedPieces.length == 1
        ? 0
        : math.Random().nextInt(encodedPieces.length - 1);
    final params = encodedPieces[pececIndex].value;

    final sourcePiece = state.pieces.firstWhere(
      (final p) => p.id == params.pieceId,
    );
    final targetPiece = _applyPlacementToPiece(
      sourcePiece,
      params,
    ).copyWith(isUsersItem: false);
    final pieces = _updatePieceInList(targetPiece);
    final applicableSolutions = _combineSolutions(state.solutions, pieces);

    final move = HintMove(
      targetPiece.id,
      from: MovePlacement(
        zone: PlaceZone.board,
        position: Position(
          dx: state.boardConfig.relativePosition(sourcePiece.position).dx,
          dy: state.boardConfig.relativePosition(sourcePiece.position).dy,
        ),
      ),
      to: MovePlacement(
        position: Position(
          dx: state.gridConfig.relativePosition(targetPiece.position).dx,
          dy: state.gridConfig.relativePosition(targetPiece.position).dy,
        ),
      ),
      rotationFrom: sourcePiece.rotation,
      rotationTo: targetPiece.rotation,
      flippedFrom: sourcePiece.isFlipped,
      flippedTo: targetPiece.isFlipped,
    );
    final nextState = state.copyWith(
      pieces: pieces,
      applicableSolutions: applicableSolutions,
      moveHistory: [...state.moveHistory.take(state.moveIndex), move],
      moveIndex: state.moveIndex + 1,
      status: _getStatus(pieces),
    );
    final timedState = _resumeTimerAfterUserAction(
      prevState: prevState,
      nextState: nextState,
    );
    emit(timedState);
    _persistHistoryChange(prevState: prevState, nextState: timedState);
  }

  FutureOr<void> _undoMove(final _Undo event, final Emitter<PuzzleState> emit) {
    if (state.moveHistory.isNotEmpty && state.moveIndex > 0) {
      final prevState = state;
      final idx = state.moveIndex - 1;
      final selectedPiece = _moveHistoryService.historyPiece(
        state: state,
        idx: idx,
        isUndo: true,
        rotationStep: PuzzleBloc.rotationStep,
        fullRotation: PuzzleBloc.fullRotation,
      );
      final pieces = _updatePieceInList(selectedPiece);
      final shouldResolve =
          selectedPiece.isConfigItem && _settings.requireSolutions;
      final applicableSolutions = shouldResolve
          ? state.applicableSolutions
          : _combineSolutions(state.solutions, pieces);
      final nextState = state.copyWith(
        moveIndex: idx,
        pieces: pieces,
        status: GameStatus.playing,
        applicableSolutions: applicableSolutions,
      );
      final timedState = _resumeTimerAfterUserAction(
        prevState: prevState,
        nextState: nextState,
      );
      emit(timedState);
      _persistHistoryChange(prevState: prevState, nextState: timedState);
      if (shouldResolve) {
        add(const PuzzleEvent.solve(showResult: false));
      }
    }
  }

  FutureOr<void> _redoMove(final _Redo event, final Emitter<PuzzleState> emit) {
    final prevState = state;
    final idx = state.moveIndex + 1;
    final selectedPiece = _moveHistoryService.historyPiece(
      state: state,
      idx: state.moveIndex,
      isUndo: false,
      rotationStep: PuzzleBloc.rotationStep,
      fullRotation: PuzzleBloc.fullRotation,
    );
    final pieces = _updatePieceInList(selectedPiece);
    final shouldResolve =
        selectedPiece.isConfigItem && _settings.requireSolutions;
    final applicableSolutions = shouldResolve
        ? state.applicableSolutions
        : _combineSolutions(state.solutions, pieces);
    final nextState = state.copyWith(
      moveIndex: idx,
      pieces: pieces,
      status: GameStatus.playing,
      applicableSolutions: applicableSolutions,
    );
    final timedState = _resumeTimerAfterUserAction(
      prevState: prevState,
      nextState: nextState,
    );
    emit(timedState);
    _persistHistoryChange(prevState: prevState, nextState: timedState);
    if (shouldResolve) {
      add(const PuzzleEvent.solve(showResult: false));
    }
  }

  // todo draft solution:
  // need to check empty date cells
  // need to change status for unique solutions only
  GameStatus _getStatus(final Iterable<PuzzlePieceUI> pieces) {
    if (state.selectedPiece?.isUsersItem == false) {
      return state.status;
    }
    return pieces.where((final p) => p.placeZone == PlaceZone.board).isEmpty &&
            !pieces.any(
              (final piece) => _movementHandler.checkCollision(
                piece: piece,
                newPosition: piece.position,
                zone: PlaceZone.grid,
                preventOverlap: true,
                pieces: pieces,
                gridConfig: state.gridConfig,
                boardConfig: state.boardConfig,
              ),
            )
        ? GameStatus.solvedByUser
        : GameStatus.playing;
  }

  List<Map<String, PlacementParams>> _combineSolutions(
    final Iterable<Map<String, PlacementParams>> solutions,
    final Iterable<PuzzlePieceUI> pieces,
  ) {
    if (solutions.isEmpty) {
      return [];
    }
    final gridPlacedPieces = pieces.where(
      (final p) => p.placeZone == PlaceZone.grid && !p.isConfigItem,
    );

    if (gridPlacedPieces.isEmpty) {
      return solutions.toList();
    }

    final origin = state.gridConfig.origin;
    final cellSize = state.gridConfig.cellSize;

    final userCellsById = <String, Set<Cell>>{
      for (final userPiece in gridPlacedPieces)
        userPiece.id: userPiece.cells(origin, cellSize),
    };

    return solutions.where((final solution) {
      // For each user-placed piece, check that solution has same occupied cells when applied
      for (final entry in userCellsById.entries) {
        final pieceId = entry.key;
        final parsed = solution[pieceId];
        if (parsed == null) return false;
        final basePiece = pieces.firstWhereOrNull((final p) => p.id == pieceId);
        if (basePiece == null) return false;
        final placedPiece = _applyPlacementToPiece(
          basePiece.copyWith(
            originalPath: generatePathForType(basePiece.type, cellSize),
          ),
          parsed,
        );
        final solutionCells = placedPiece.cells(origin, cellSize);
        if (solutionCells.length != entry.value.length) return false;
        if (!solutionCells.containsAll(entry.value)) return false;
      }
      return true;
    }).toList();
  }

  PuzzlePieceUI _applyPlacementToPiece(
    final PuzzlePieceUI piece,
    final PlacementParams params,
  ) {
    final cellSize = state.gridConfig.cellSize;
    final origin = state.gridConfig.origin;
    final dx = params.col * cellSize;
    final dy = params.row * cellSize;
    final targetOffset = Offset(origin.dx + dx, origin.dy + dy);

    final updatedPiece = piece.copyWith(
      isFlipped: params.isFlipped,
      position: targetOffset,
      rotation: params.rotationSteps * PuzzleBloc.rotationStep,
      placeZone: PlaceZone.grid,
    );
    return updatedPiece;
  }

  double _stepRotation(final double value) =>
      (value + PuzzleBloc.rotationStep) % PuzzleBloc.fullRotation;

  PuzzleState _resumeTimerAfterUserAction({
    required final PuzzleState prevState,
    required final PuzzleState nextState,
  }) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    var timedState = nextState;

    if (timedState.firstMoveAt == null && timedState.moveIndex > 0) {
      timedState = timedState.copyWith(
        firstMoveAt: nowMs,
        lastResumedAt: nowMs,
      );
    }

    if (prevState.status == GameStatus.paused &&
        timedState.firstMoveAt != null &&
        timedState.lastResumedAt == null) {
      timedState = timedState.copyWith(lastResumedAt: nowMs);
    }

    if (timedState.status == GameStatus.solvedByUser &&
        timedState.firstMoveAt != null) {
      final segmentStartMs = timedState.lastResumedAt ??
          (timedState.activeElapsedMs == 0 ? timedState.firstMoveAt : null);
      if (segmentStartMs != null) {
        final segmentMs = (nowMs - segmentStartMs).clamp(0, 1 << 31).toInt();
        timedState = timedState.copyWith(
          activeElapsedMs: timedState.activeElapsedMs + segmentMs,
          lastResumedAt: null,
        );
      }
    }

    return timedState;
  }

  void _persistHistoryChange({
    required final PuzzleState prevState,
    required final PuzzleState nextState,
  }) {
    if (nextState.isRestoredSolvedSession) {
      return;
    }
    final difficulty = _currentSessionDifficulty ?? _difficultyFromSettings();
    _currentSessionDifficulty = difficulty;
    _historyUseCase.setCurrentSessionDifficulty(difficulty);
    _historyUseCase.persistAfterChange(
      nextState.toHistoryInput(
        prevState: prevState,
        rotationStep: PuzzleBloc.rotationStep,
        difficulty: difficulty,
      ),
    );
  }

  bool _hasConfigOverlap(final Iterable<PuzzlePieceUI> pieces) {
    final occupied = <Cell>{};
    final configPieces = pieces.where((final p) => p.isConfigItem);
    for (final piece in configPieces) {
      final cells =
          piece.cells(state.gridConfig.origin, state.gridConfig.cellSize);
      for (final cell in cells) {
        if (!occupied.add(cell)) {
          return true;
        }
      }
    }
    return false;
  }
}
