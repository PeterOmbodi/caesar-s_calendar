part of 'puzzle_bloc.dart';

extension PuzzleBlocDragPart on PuzzleBloc {
  FutureOr<void> _onTapDown(final _OnTapDown event, final Emitter<PuzzleState> emit) {
    _selectedOnTapDownId = null;
    if (_consumeTapAfterDrawnCommitSuppression() || _isTapOfDoubleTapFlip(event.localPosition)) {
      emit(state.copyWith(pointerPiece: null));
      return Future<void>.value();
    }

    final cell = state.gridConfig.cellAt(event.localPosition);
    if (cell != null && state.drawnGroup?.contains(cell) == true) {
      emit(state.copyWith(pointerPiece: null));
      return Future<void>.value();
    }

    final piece = _findPieceAtPosition(event.localPosition);
    if (piece != null && _canTouch(piece)) {
      if (piece.id != state.selectedPieceId) {
        _selectedOnTapDownId = piece.id;
      }
      emit(state.copyWith(pointerPiece: piece, selectedPieceId: piece.id));
    } else {
      emit(state.copyWith(pointerPiece: null));
    }
  }

  FutureOr<void> _onTapUp(final _OnTapUp event, final Emitter<PuzzleState> emit) {
    final isTapOfDoubleTapFlip = _isTapOfDoubleTapFlip(event.localPosition);
    _lastDoubleTapFlip = null;
    if (_consumeTapAfterDrawnCommitSuppression() || isTapOfDoubleTapFlip) {
      emit(state.copyWith(pointerPiece: null, isDragging: false));
      return Future<void>.value();
    }

    final cell = state.gridConfig.cellAt(event.localPosition);
    final drawnGroup = state.drawnGroup;
    if (cell != null && drawnGroup != null) {
      final updatedGroup = drawnGroup.contains(cell)
          ? _drawnGroupService.remove(group: drawnGroup, cell: cell)
          : _drawnGroupService.extend(group: drawnGroup, cell: cell, grid: state.gridConfig, pieces: state.pieces);
      if (updatedGroup != drawnGroup) {
        emit(
          state.copyWith(
            drawnGroup: updatedGroup,
            drawnGroupCommitStatus: _resolveDrawnGroupCommitStatus(updatedGroup),
            pointerPiece: null,
            selectedPieceId: null,
            isDragging: false,
            isDrawingGroup: false,
          ),
        );
        return Future<void>.value();
      }
    }

    final pointerPiece = state.pointerPiece;
    final wasSelectedOnTapDown = pointerPiece != null && _selectedOnTapDownId == pointerPiece.id;
    _selectedOnTapDownId = null;
    if (pointerPiece != null && !state.isDragging && !wasSelectedOnTapDown) {
      add(const PuzzleEvent.rotateSelected());
    }
    emit(
      state.copyWith(
        pointerPiece: null,
        isDragging: false,
        selectedPieceId: pointerPiece == null ? null : state.selectedPieceId,
      ),
    );
  }

  FutureOr<void> _onPanStart(final _OnPanStart event, final Emitter<PuzzleState> emit) {
    _selectedOnTapDownId = null;
    final piece = _findPieceAtPosition(event.localPosition) ?? state.pointerPiece;
    if (piece != null && _canTouch(piece)) {
      final lifted = state.shown(piece).rescaledAround(event.localPosition, isLifted: true);
      final pieces = List<PuzzlePieceUI>.from(state.pieces);
      final pieceIndex = pieces.indexWhere((final item) => item.id == piece.id);
      if (pieceIndex >= 0) {
        pieces.removeAt(pieceIndex);
        pieces.add(lifted);
      } else {
        debugPrint('_onPanStart, piece not found!');
      }
      emit(
        state.copyWith(
          pieces: pieces,
          pointerPiece: lifted,
          selectedPieceId: piece.id,
          dragStartOffset: event.localPosition - lifted.position,
          pieceStartPosition: piece.position,
          dragStartZone: _movementHandler.getZoneAtPosition(piece.position, state.gridConfig, state.boardConfig),
          isDragging: true,
          drawnGroup: null,
          drawnGroupCommitStatus: DrawnGroupCommitStatus.tooSmall,
          isDrawingGroup: false,
        ),
      );
      return Future<void>.value();
    }

    final cell = state.gridConfig.cellAt(event.localPosition);
    if (cell == null || state.isEditingLayout) {
      return Future<void>.value();
    }

    final drawnGroup = state.drawnGroup;
    if (drawnGroup != null) {
      if (drawnGroup.contains(cell)) {
        emit(state.copyWith(isDrawingGroup: true, pointerPiece: null, selectedPieceId: null, isDragging: false));
      }
      return Future<void>.value();
    }

    final newGroup = _drawnGroupService.start(cell: cell, grid: state.gridConfig, pieces: state.pieces);
    if (newGroup != null) {
      emit(
        state.copyWith(
          drawnGroup: newGroup,
          drawnGroupCommitStatus: _resolveDrawnGroupCommitStatus(newGroup),
          isDrawingGroup: true,
          pointerPiece: null,
          selectedPieceId: null,
          isDragging: false,
        ),
      );
    }
  }

  FutureOr<void> _onPanUpdate(final _OnPanUpdate event, final Emitter<PuzzleState> emit) {
    if (state.isDrawingGroup) {
      final cell = state.gridConfig.cellAt(event.localPosition);
      final drawnGroup = state.drawnGroup;
      if (cell == null || drawnGroup == null) {
        return Future<void>.value();
      }
      final updatedGroup = _drawnGroupService.extend(
        group: drawnGroup,
        cell: cell,
        grid: state.gridConfig,
        pieces: state.pieces,
      );
      emit(
        state.copyWith(drawnGroup: updatedGroup, drawnGroupCommitStatus: _resolveDrawnGroupCommitStatus(updatedGroup)),
      );
      return Future<void>.value();
    }

    if (state.pointerPiece != null && state.dragStartOffset != null) {
      final newPosition = event.localPosition - state.dragStartOffset!;
      final piece = state.pointerPiece!.copyWith(position: newPosition);
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
              pointerPiece: piece,
              showPreview: true,
              previewPosition: previewPosition,
              previewCollision: _movementHandler.checkCollision(
                piece: piece,
                newPosition: previewPosition,
                zone: currentZone!,
                preventOverlap: _settings.preventOverlap || piece.isConfigItem,
                pieces: _obstacles(pieces),
                gridConfig: state.gridConfig,
                boardConfig: state.boardConfig,
              ),
            ),
          );
        case PlaceZone.board:
        case null:
          emit(state.copyWith(pieces: pieces, pointerPiece: piece, showPreview: false, previewCollision: false));
      }
    }
  }

  FutureOr<void> _onPanEnd(final _OnPanEnd event, final Emitter<PuzzleState> emit) {
    if (state.isDrawingGroup) {
      emit(state.copyWith(isDrawingGroup: false));
      return Future<void>.value();
    }

    if (state.pointerPiece != null) {
      final prevState = state;
      final selectedPiece = state.pointerPiece!;
      final dropResult = _movementHandler.computeDropResult(
        selectedPiece: selectedPiece,
        pieceStartPosition: state.pieceStartPosition!,
        dragStartZone: state.dragStartZone,
        gridConfig: state.gridConfig,
        boardConfig: state.boardConfig,
        pieces: _obstacles(state.pieces),
        preventOverlap: _settings.preventOverlap || selectedPiece.isConfigItem,
        anchor: state.dragStartOffset == null ? null : selectedPiece.position + state.dragStartOffset!,
      );

      if (dropResult.accepted && (!selectedPiece.isConfigItem || dropResult.zone == PlaceZone.grid)) {
        final movedPiece = selectedPiece.copyWith(
          position: dropResult.snappedPosition!,
          placeZone: dropResult.zone!,
          isLifted: false,
          isUsersItem: selectedPiece.isConfigItem ? selectedPiece.isUsersItem : true,
        );
        final move = dropResult.move!;
        final moveHistory = List<Move>.from(state.moveHistory);
        if (moveHistory.length > state.moveIndex) {
          moveHistory.removeRange(state.moveIndex, moveHistory.length);
        }
        moveHistory.add(move);
        final pieces = _updatePieceInList(_withHintFlag(movedPiece));
        final shouldResolve = movedPiece.isConfigItem;
        final applicableSolutions = shouldResolve
            ? <Map<String, PlacementParams>>[]
            : _combineSolutions(state.solutions, pieces);
        final nextState = state.copyWith(
          pieces: pieces,
          showPreview: false,
          previewPosition: null,
          pointerPiece: null,
          dragStartOffset: null,
          pieceStartPosition: null,
          dragStartZone: null,
          isDragging: false,
          moveHistory: moveHistory,
          moveIndex: moveHistory.length,
          status: _getStatus(pieces: pieces, applicableSolutions: applicableSolutions),
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
        final resetPiece = state.pointerPiece!.copyWith(position: state.pieceStartPosition, isLifted: false);
        emit(
          state.copyWith(
            pieces: _updatePieceInList(resetPiece),
            showPreview: false,
            previewPosition: null,
            pointerPiece: null,
            dragStartOffset: null,
            pieceStartPosition: null,
            dragStartZone: null,
            isDragging: false,
          ),
        );
      }
    }
  }

  FutureOr<void> _clearDrawnGroup(final _ClearDrawnGroup event, final Emitter<PuzzleState> emit) {
    emit(
      state.copyWith(
        drawnGroup: null,
        drawnGroupCommitStatus: DrawnGroupCommitStatus.tooSmall,
        isDrawingGroup: false,
        pointerPiece: null,
        isDragging: false,
      ),
    );
  }

  PuzzlePieceUI? _findPieceAtPosition(final Offset position) {
    final selectedPiece = state.selectedPiece;
    if (selectedPiece != null && state.shown(selectedPiece).containsPoint(position)) {
      return selectedPiece;
    }
    return state.pieces.lastWhereOrNull((final piece) => _canTouch(piece) && state.shown(piece).containsPoint(position));
  }

  bool _isTapOfDoubleTapFlip(final Offset position) {
    final flip = _lastDoubleTapFlip;
    if (flip == null) {
      return false;
    }
    final elapsedMs = DateTime.now().millisecondsSinceEpoch - flip.atMs;
    return elapsedMs >= 0 &&
        elapsedMs <= kDoubleTapTimeout.inMilliseconds &&
        (position - flip.position).distance <= kDoubleTapSlop;
  }

  bool _consumeTapAfterDrawnCommitSuppression() {
    final suppressedAt = _suppressTapAfterDrawnCommitAtMs;
    if (suppressedAt == null) {
      return false;
    }

    final elapsedMs = DateTime.now().millisecondsSinceEpoch - suppressedAt;
    if (elapsedMs >= 0 && elapsedMs <= 700) {
      return true;
    }
    _suppressTapAfterDrawnCommitAtMs = null;
    return false;
  }

  List<PuzzlePieceUI> _updatePieceInList(final PuzzlePieceUI piece) => List<PuzzlePieceUI>.from(state.pieces)
    ..removeWhere((final p) => p.id == piece.id)
    ..add(piece);

  bool _canTouch(final PuzzlePieceUI piece) => piece.isConfigItem == state.isEditingLayout;

  // Game pieces are hidden while a layout is edited, so blocks may lie over them.
  Iterable<PuzzlePieceUI> _obstacles(final Iterable<PuzzlePieceUI> pieces) =>
      state.isEditingLayout ? pieces.where((final p) => p.isConfigItem) : pieces;
}
