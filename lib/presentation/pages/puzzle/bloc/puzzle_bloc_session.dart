part of 'puzzle_bloc.dart';

extension PuzzleBlocSessionPart on PuzzleBloc {
  FutureOr<void> _reset(final _Reset event, final Emitter<PuzzleState> emit) {
    _historyUseCase.resetSession();
    _currentSessionDifficulty = null;
    add(
      PuzzleEvent.configure(
        toInitial: true,
        configurationPieces: state.gridPieces.where((final e) => e.isConfigItem),
      ),
    );
    if (state.solutions.isEmpty && _settings.requireSolutions) {
      add(const PuzzleEvent.solve(showResult: false));
    }
  }

  FutureOr<void> _timerStateChanged(final _SetTimer event, final Emitter<PuzzleState> emit) {
    if (state.isEditingLayout) {
      return Future.value();
    }
    if (event.running) {
      if (state.status == GameStatus.paused) {
        final prevState = state;
        final nextState = state.copyWith(
          status: GameStatus.playing,
          lastResumedAt: DateTime.now().millisecondsSinceEpoch,
        );
        emit(nextState);
        _persistHistoryChange(prevState: prevState, nextState: nextState);
      }
      return Future.value();
    }

    if (state.status == GameStatus.playing && state.firstMoveAt != null) {
      final prevState = state;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final resumedAt = state.lastResumedAt ?? state.firstMoveAt!;
      final nextState = state.copyWith(
        status: GameStatus.paused,
        activeElapsedMs: state.activeElapsedMs + (nowMs - resumedAt),
        lastResumedAt: null,
      );
      emit(nextState);
      _persistHistoryChange(prevState: prevState, nextState: nextState);
    } else if (state.status == GameStatus.playing) {
      final prevState = state;
      final nextState = state.copyWith(status: GameStatus.paused);
      emit(nextState);
      _persistHistoryChange(prevState: prevState, nextState: nextState);
    }
  }

  FutureOr<void> _restoreSession(final _RestoreSession event, final Emitter<PuzzleState> emit) {
    final session = event.session;
    final isSolvedSession = session.status == PuzzleSessionStatus.solved || session.completedAt != null;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _historyUseCase.activateSession(session);
    _currentSessionDifficulty = session.difficulty;
    final restoredPieces = _restoreSessionPieces(session);
    final restoredElapsedMs = _restoredSessionElapsedMs(session);

    emit(
      state.copyWith(
        selectedDate: DateTime(session.puzzleDate.year, session.puzzleDate.month, session.puzzleDate.day),
        pieces: restoredPieces,
        moveHistory: session.moveHistory,
        hintedCells: _hintedCellsOf(session.moveHistory),
        moveIndex: session.moveIndex,
        firstMoveAt: session.firstMoveAt,
        lastResumedAt: !isSolvedSession && session.firstMoveAt != null ? nowMs : null,
        activeElapsedMs: restoredElapsedMs,
        solutionIdx: -1,
        solutions: const [],
        applicableSolutions: const [],
        pointerPiece: null,
        selectedPieceId: null,
        isDragging: false,
        dragStartOffset: null,
        pieceStartPosition: null,
        previewPosition: null,
        dragStartZone: null,
        showPreview: false,
        previewCollision: false,
        drawnGroup: null,
        drawnGroupCommitStatus: DrawnGroupCommitStatus.tooSmall,
        isDrawingGroup: false,
        isRestoredSolvedSession: isSolvedSession,
        hasShownSolvedDialog: isSolvedSession,
        status: isSolvedSession ? GameStatus.solvedByUser : GameStatus.playing,
      ),
    );

    add(const PuzzleEvent.solve(showResult: false));
  }

  void _setPuzzleDate(final _SetPuzzleDate event, final Emitter<PuzzleState> emit) => _startNewGame(
    emit,
    date: event.date,
    configurationPieces: state.gridPieces.where((final e) => e.isConfigItem),
  );

  void _applyLayout(final _ApplyLayout event, final Emitter<PuzzleState> emit) => _startNewGame(
    emit,
    date: DateTime.now(),
    configurationPieces: _withLayout(event.placements).where((final p) => p.isConfigItem),
  );

  void _startLayoutEdit(final _StartLayoutEdit event, final Emitter<PuzzleState> emit) {
    if (state.isEditingLayout || state.isShowSolutions) {
      return;
    }
    final resumedAt = state.lastResumedAt;
    final elapsedMs = resumedAt == null ? 0 : DateTime.now().millisecondsSinceEpoch - resumedAt;
    emit(
      state.copyWith(
        layoutEdit: LayoutEdit(
          start: state.configPlacements,
          status: state.status,
          layoutId: event.layoutId,
          name: event.name,
          moveHistory: state.moveHistory,
          moveIndex: state.moveIndex,
          solutions: state.solutions,
          applicableSolutions: state.applicableSolutions,
          wasTimerRunning: resumedAt != null,
        ),
        activeElapsedMs: state.activeElapsedMs + elapsedMs,
        lastResumedAt: null,
        selectedPieceId: null,
        pointerPiece: null,
        drawnGroup: null,
        isDrawingGroup: false,
      ),
    );
  }

  void _resetLayoutEdit(final _ResetLayoutEdit event, final Emitter<PuzzleState> emit) {
    final edit = state.layoutEdit;
    if (edit != null) {
      emit(state.copyWith(pieces: _withLayout(edit.start), selectedPieceId: null));
      add(const PuzzleEvent.solve(showResult: false));
    }
  }

  void _cancelLayoutEdit(final _CancelLayoutEdit event, final Emitter<PuzzleState> emit) {
    final edit = state.layoutEdit;
    if (edit == null) {
      return;
    }
    _solveRun++;
    emit(
      state.copyWith(
        pieces: _withLayout(edit.start),
        moveHistory: edit.moveHistory,
        moveIndex: edit.moveIndex,
        solutions: edit.solutions,
        applicableSolutions: edit.applicableSolutions,
        status: edit.status,
        lastResumedAt: edit.wasTimerRunning ? DateTime.now().millisecondsSinceEpoch : null,
        selectedPieceId: null,
        pointerPiece: null,
        layoutEdit: null,
      ),
    );
    if (edit.status == GameStatus.searchingSolutions) {
      add(const PuzzleEvent.solve(showResult: false));
    }
  }

  List<PuzzlePieceUI> _withLayout(final List<PlacementParams> placements) {
    final byId = {for (final p in placements) p.pieceId: p};
    return [
      for (final piece in state.pieces)
        if (piece.isConfigItem && byId[piece.id] != null) _applyPlacementToPiece(piece, byId[piece.id]!) else piece,
    ];
  }

  void _startNewGame(
    final Emitter<PuzzleState> emit, {
    required final DateTime date,
    required final Iterable<PuzzlePieceUI> configurationPieces,
  }) {
    final nextDate = DateTime(date.year, date.month, date.day);
    _historyUseCase.resetSession();
    _currentSessionDifficulty = null;
    emit(
      state.copyWith(
        selectedDate: nextDate,
        solutionIdx: -1,
        solutions: const [],
        applicableSolutions: const [],
        moveHistory: const [],
        moveIndex: 0,
        hintedCells: const {},
        firstMoveAt: null,
        lastResumedAt: null,
        activeElapsedMs: 0,
        pointerPiece: null,
        selectedPieceId: null,
        isDragging: false,
        dragStartOffset: null,
        pieceStartPosition: null,
        previewPosition: null,
        dragStartZone: null,
        showPreview: false,
        previewCollision: false,
        drawnGroup: null,
        drawnGroupCommitStatus: DrawnGroupCommitStatus.tooSmall,
        isDrawingGroup: false,
        isRestoredSolvedSession: false,
        hasShownSolvedDialog: false,
        status: GameStatus.paused,
        layoutEdit: null,
      ),
    );
    add(PuzzleEvent.configure(toInitial: true, configurationPieces: configurationPieces));
  }

  FutureOr<void> _markSolvedDialogShown(final _MarkSolvedDialogShown event, final Emitter<PuzzleState> emit) {
    if (state.hasShownSolvedDialog) {
      return Future.value();
    }
    emit(state.copyWith(hasShownSolvedDialog: true));
  }

  void _onLifecycleChanged(final AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        add(const PuzzleEvent.setTimer(running: true));
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        add(const PuzzleEvent.setTimer(running: false));
      case AppLifecycleState.detached:
        break;
    }
  }

  List<PuzzlePieceUI> _restoreSessionPieces(final PuzzleSessionData session) {
    final snapshotById = {for (final snapshot in session.pieces) snapshot.id: snapshot};
    final restoredPieces = state.pieces.map((final piece) {
      final snapshot = snapshotById[piece.id];
      if (snapshot == null) {
        return piece;
      }
      return piece.copyWith(
        rotation: snapshot.rotation,
        isFlipped: snapshot.isFlipped,
        placeZone: snapshot.placeZone,
        isUsersItem: snapshot.isUsersItem,
        isForbidden: snapshot.isConfigItem,
      );
    }).toList();

    for (final move in session.moveHistory.take(session.moveIndex)) {
      final pieceIndex = restoredPieces.indexWhere((final piece) => piece.id == move.pieceId);
      if (pieceIndex < 0) {
        continue;
      }
      final piece = restoredPieces[pieceIndex];
      restoredPieces[pieceIndex] = _applySessionMoveToPiece(piece: piece, move: move);
    }

    return restoredPieces;
  }

  PuzzlePieceUI _applySessionMoveToPiece({required final PuzzlePieceUI piece, required final Move move}) => move.map(
    movePiece: (final mp) => _applySessionPlacement(
      piece: piece,
      placement: mp.to,
      rotation: mp.rotationTo ?? piece.rotation,
      isFlipped: mp.flippedTo ?? piece.isFlipped,
    ),
    rotatePiece: (final rp) => piece.copyWith(
      rotation: rp.rotation,
      position: _moveHistoryService.snapOffset(state.gridConfig, state.boardConfig, rp.snapCorrection, false) ?? piece.position,
    ),
    flipPiece: (final fp) => piece.copyWith(
      isFlipped: fp.isFlipped,
      position: _moveHistoryService.snapOffset(state.gridConfig, state.boardConfig, fp.snapCorrection, false) ?? piece.position,
    ),
    hintMove: (final hm) =>
        _applySessionPlacement(piece: piece, placement: hm.to, rotation: hm.rotationTo, isFlipped: hm.flippedTo),
  );

  PuzzlePieceUI _applySessionPlacement({
    required final PuzzlePieceUI piece,
    required final MovePlacement placement,
    required final double rotation,
    required final bool isFlipped,
  }) {
    final config = placement.zone == PlaceZone.grid ? state.gridConfig : state.boardConfig;
    final position = config.absolutPositionPos(placement.position);
    return piece.copyWith(
      placeZone: placement.zone,
      position: Offset(position.dx, position.dy),
      rotation: rotation,
      isFlipped: isFlipped,
    );
  }

  int _restoredSessionElapsedMs(final PuzzleSessionData session) {
    final segmentEndMs = session.completedAt ?? session.updatedAt;
    final segmentStartMs = session.lastResumedAt ?? (session.activeElapsedMs == 0 ? session.firstMoveAt : null);
    if (segmentStartMs == null) {
      return session.activeElapsedMs;
    }

    final currentSegmentMs = (segmentEndMs - segmentStartMs).clamp(0, 1 << 31).toInt();
    return session.activeElapsedMs + currentSegmentMs;
  }

  PuzzleSessionDifficulty _difficultyFromSettings() {
    if (!_settings.requireSolutions) {
      return PuzzleSessionDifficulty.hard;
    }
    return _settings.showSolutionCount ? PuzzleSessionDifficulty.easy : PuzzleSessionDifficulty.medium;
  }
}
