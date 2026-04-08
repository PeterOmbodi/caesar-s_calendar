part of 'puzzle_bloc.dart';

extension PuzzleBlocSessionPart on PuzzleBloc {
  FutureOr<void> _reset(final _Reset event, final Emitter<PuzzleState> emit) {
    _historyUseCase.resetSession();
    _currentSessionDifficulty = null;
    add(
      PuzzleEvent.configure(
        toInitial: true,
        configurationPieces: _settings.unlockConfig
            ? []
            : state.gridPieces.where((final e) => e.isConfigItem),
      ),
    );
    if (state.solutions.isEmpty && _settings.requireSolutions) {
      add(const PuzzleEvent.solve(showResult: false));
    }
  }

  FutureOr<void> _timerStateChanged(
    final _SetTimer event,
    final Emitter<PuzzleState> emit,
  ) {
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

  FutureOr<void> _restoreSession(
    final _RestoreSession event,
    final Emitter<PuzzleState> emit,
  ) {
    final session = event.session;
    final isSolvedSession = session.status == PuzzleSessionStatus.solved ||
        session.completedAt != null;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _historyUseCase.activateSession(session);
    _currentSessionDifficulty = session.difficulty;
    final restoredPieces = _applySnapshotPieces(session.pieces);
    final restoredElapsedMs = _restoredSessionElapsedMs(session);

    emit(
      state.copyWith(
        selectedDate: DateTime(
          session.puzzleDate.year,
          session.puzzleDate.month,
          session.puzzleDate.day,
        ),
        pieces: restoredPieces,
        moveHistory: session.moveHistory,
        moveIndex: session.moveIndex,
        firstMoveAt: session.firstMoveAt,
        lastResumedAt:
            !isSolvedSession && session.firstMoveAt != null ? nowMs : null,
        activeElapsedMs: restoredElapsedMs,
        solutionIdx: -1,
        solutions: const [],
        applicableSolutions: const [],
        selectedPiece: null,
        isDragging: false,
        dragStartOffset: null,
        pieceStartPosition: null,
        previewPosition: null,
        dragStartZone: null,
        showPreview: false,
        previewCollision: false,
        isRestoredSolvedSession: isSolvedSession,
        hasShownSolvedDialog: isSolvedSession,
        status: isSolvedSession ? GameStatus.solvedByUser : GameStatus.playing,
      ),
    );

    add(const PuzzleEvent.solve(showResult: false));
  }

  FutureOr<void> _setPuzzleDate(
    final _SetPuzzleDate event,
    final Emitter<PuzzleState> emit,
  ) {
    final nextDate = DateTime(
      event.date.year,
      event.date.month,
      event.date.day,
    );
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
        firstMoveAt: null,
        lastResumedAt: null,
        activeElapsedMs: 0,
        selectedPiece: null,
        isDragging: false,
        dragStartOffset: null,
        pieceStartPosition: null,
        previewPosition: null,
        dragStartZone: null,
        showPreview: false,
        previewCollision: false,
        isRestoredSolvedSession: false,
        hasShownSolvedDialog: false,
        status: GameStatus.paused,
      ),
    );
    add(
      PuzzleEvent.configure(
        toInitial: true,
        configurationPieces: _settings.unlockConfig
            ? []
            : state.gridPieces.where((final e) => e.isConfigItem),
      ),
    );
  }

  FutureOr<void> _restoreLocalSnapshot(
    final _RestoreLocalSnapshot event,
    final Emitter<PuzzleState> emit,
  ) {
    final snapshot = event.snapshot;
    emit(
      state.copyWith(
        selectedDate: snapshot.selectedDate,
        pieces: _applySnapshotPieces(snapshot.pieces),
        moveHistory: snapshot.moveHistory,
        moveIndex: snapshot.moveIndex,
        firstMoveAt: snapshot.firstMoveAt,
        lastResumedAt: snapshot.lastResumedAt,
        activeElapsedMs: snapshot.activeElapsedMs,
        solutionIdx: -1,
        solutions: const [],
        applicableSolutions: const [],
        selectedPiece: null,
        isDragging: false,
        dragStartOffset: null,
        pieceStartPosition: null,
        previewPosition: null,
        dragStartZone: null,
        showPreview: false,
        previewCollision: false,
        isRestoredSolvedSession: snapshot.isRestoredSolvedSession,
        hasShownSolvedDialog: snapshot.hasShownSolvedDialog,
        status: snapshot.status,
      ),
    );
    add(const PuzzleEvent.solve(showResult: false));
  }

  FutureOr<void> _markSolvedDialogShown(
    final _MarkSolvedDialogShown event,
    final Emitter<PuzzleState> emit,
  ) {
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

  List<PuzzlePieceUI> _applySnapshotPieces(
    final List<PuzzlePieceSnapshot> snapshots,
  ) {
    final snapshotById = {
      for (final snapshot in snapshots) snapshot.id: snapshot,
    };
    return state.pieces.map((final piece) {
      final snapshot = snapshotById[piece.id];
      if (snapshot == null) {
        return piece;
      }
      return piece.copyWith(
        position: Offset(snapshot.position.dx, snapshot.position.dy),
        rotation: snapshot.rotation,
        isFlipped: snapshot.isFlipped,
        placeZone: snapshot.placeZone,
        isUsersItem: snapshot.isUsersItem,
        isForbidden: snapshot.isConfigItem,
      );
    }).toList();
  }

  int _restoredSessionElapsedMs(final PuzzleSessionData session) {
    final segmentEndMs = session.completedAt ?? session.updatedAt;
    final segmentStartMs = session.lastResumedAt ??
        (session.activeElapsedMs == 0 ? session.firstMoveAt : null);
    if (segmentStartMs == null) {
      return session.activeElapsedMs;
    }

    final currentSegmentMs =
        (segmentEndMs - segmentStartMs).clamp(0, 1 << 31).toInt();
    return session.activeElapsedMs + currentSegmentMs;
  }

  PuzzleSessionDifficulty _difficultyFromSettings() =>
      _settings.requireSolutions
          ? PuzzleSessionDifficulty.easy
          : PuzzleSessionDifficulty.hard;
}
