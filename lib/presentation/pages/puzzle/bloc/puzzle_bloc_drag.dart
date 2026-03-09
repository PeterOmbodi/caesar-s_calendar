part of 'puzzle_bloc.dart';

extension PuzzleBlocDragPart on PuzzleBloc {
  FutureOr<void> _onTapDown(final _OnTapDown event, final Emitter<PuzzleState> emit) {
    final piece = _findPieceAtPosition(event.localPosition);
    if (piece != null && (!piece.isConfigItem || _settings.unlockConfig)) {
      emit(state.copyWith(selectedPiece: piece));
    }
  }

  FutureOr<void> _onTapUp(final _OnTapUp event, final Emitter<PuzzleState> emit) {
    if (state.selectedPiece != null && !state.isDragging) {
      add(PuzzleEvent.rotatePiece(state.selectedPiece!));
    }
    emit(state.copyWith(selectedPiece: null, isDragging: false));
  }

  FutureOr<void> _onPanStart(final _OnPanStart event, final Emitter<PuzzleState> emit) {
    final piece = _findPieceAtPosition(event.localPosition) ?? state.selectedPiece;
    if (piece != null && (!piece.isConfigItem || _settings.unlockConfig)) {
      final pieces = List<PuzzlePieceUI>.from(state.pieces);
      final pieceIndex = pieces.indexWhere((final item) => item.id == piece.id);
      if (pieceIndex >= 0) {
        pieces.removeAt(pieceIndex);
        pieces.add(piece);
      } else {
        debugPrint('_onPanStart, piece not found!');
      }
      emit(
        state.copyWith(
          pieces: pieces,
          selectedPiece: piece,
          dragStartOffset: event.localPosition - piece.position,
          pieceStartPosition: piece.position,
          dragStartZone: _movementHandler.getZoneAtPosition(piece.position, state.gridConfig, state.boardConfig),
          isDragging: true,
        ),
      );
    }
  }

  FutureOr<void> _onPanUpdate(final _OnPanUpdate event, final Emitter<PuzzleState> emit) {
    if (state.selectedPiece != null && state.dragStartOffset != null) {
      final newPosition = event.localPosition - state.dragStartOffset!;
      final piece = state.selectedPiece!.copyWith(position: newPosition);
      final pieces = List<PuzzlePieceUI>.from(state.pieces);
      final pieceIndex = pieces.indexWhere((final item) => item.id == piece.id);
      if (pieceIndex >= 0) {
        pieces[pieceIndex] = piece;
      } else {
        debugPrint('_onPanUpdate, piece not found!');
      }
      final currentZone = _movementHandler.getZoneAtPosition(newPosition, state.gridConfig, state.boardConfig);
      switch (currentZone) {
        case PlaceZone.grid:
          final previewPosition = state.gridConfig.snapToGrid(newPosition);
          emit(
            state.copyWith(
              pieces: pieces,
              selectedPiece: piece,
              showPreview: true,
              previewPosition: previewPosition,
              previewCollision: _movementHandler.checkCollision(
                piece: piece,
                newPosition: previewPosition,
                zone: currentZone!,
                preventOverlap: _settings.preventOverlap,
                pieces: pieces,
                gridConfig: state.gridConfig,
                boardConfig: state.boardConfig,
              ),
            ),
          );
        case PlaceZone.board:
        case null:
          emit(state.copyWith(pieces: pieces, selectedPiece: piece, showPreview: false, previewCollision: false));
      }
    }
  }

  FutureOr<void> _onPanEnd(final _OnPanEnd event, final Emitter<PuzzleState> emit) {
    if (state.selectedPiece != null) {
      final prevState = state;
      final selectedPiece = state.selectedPiece!;
      final dropResult = _movementHandler.computeDropResult(
        selectedPiece: selectedPiece,
        pieceStartPosition: state.pieceStartPosition!,
        dragStartZone: state.dragStartZone,
        gridConfig: state.gridConfig,
        boardConfig: state.boardConfig,
        pieces: state.pieces,
        preventOverlap: _settings.preventOverlap || selectedPiece.isConfigItem,
      );

      if (dropResult.accepted) {
        final movedPiece = selectedPiece.copyWith(position: dropResult.snappedPosition!, placeZone: dropResult.zone!);
        final move = dropResult.move!;
        final moveHistory = List<Move>.from(state.moveHistory);
        if (moveHistory.length > state.moveIndex) {
          moveHistory.removeRange(state.moveIndex, moveHistory.length);
        }
        moveHistory.add(move);
        final pieces = _updatePieceInList(movedPiece);
        final shouldResolve = movedPiece.isConfigItem;
        final applicableSolutions = shouldResolve
            ? <Map<String, PlacementParams>>[]
            : _combineSolutions(state.solutions, pieces);
        final nextState = state.copyWith(
          pieces: pieces,
          showPreview: false,
          previewPosition: null,
          selectedPiece: null,
          dragStartOffset: null,
          pieceStartPosition: null,
          dragStartZone: null,
          isDragging: false,
          moveHistory: moveHistory,
          moveIndex: moveHistory.length,
          status: _getStatus(pieces),
          applicableSolutions: applicableSolutions,
        );
        final timedState = _resumeTimerAfterUserAction(prevState: prevState, nextState: nextState);
        emit(timedState);
        _persistHistoryChange(prevState: prevState, nextState: timedState);
        if (shouldResolve) {
          add(const PuzzleEvent.solve(showResult: false));
        }
      } else {
        debugPrint(
          'Collision detected, returning to original position, pieceStartPosition: ${state.pieceStartPosition}',
        );
        final resetPiece = state.selectedPiece!.copyWith(position: state.pieceStartPosition);
        emit(
          state.copyWith(
            pieces: _updatePieceInList(resetPiece),
            showPreview: false,
            previewPosition: null,
            selectedPiece: null,
            dragStartOffset: null,
            pieceStartPosition: null,
            dragStartZone: null,
            isDragging: false,
          ),
        );
      }
    }
  }

  PuzzlePieceUI? _findPieceAtPosition(final Offset position) =>
      state.pieces.lastWhereOrNull((final piece) => piece.containsPoint(position));

  List<PuzzlePieceUI> _updatePieceInList(final PuzzlePieceUI piece) => List<PuzzlePieceUI>.from(state.pieces)
    ..removeWhere((final p) => p.id == piece.id)
    ..add(piece);
}
