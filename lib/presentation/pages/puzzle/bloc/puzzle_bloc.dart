import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:caesar_puzzle/application/contracts/settings_query.dart';
import 'package:caesar_puzzle/application/hint_puzzle_use_case.dart';
import 'package:caesar_puzzle/application/solve_puzzle_use_case.dart';
import 'package:caesar_puzzle/core/models/move.dart';
import 'package:caesar_puzzle/core/models/placement.dart';
import 'package:caesar_puzzle/core/models/puzzle_piece_base.dart';
import 'package:caesar_puzzle/core/utils/puzzle_board_extension.dart';
import 'package:caesar_puzzle/core/utils/puzzle_entity_extension.dart';
import 'package:caesar_puzzle/core/utils/puzzle_grid_extension.dart';
import 'package:caesar_puzzle/core/utils/puzzle_piece_extension.dart';
import 'package:caesar_puzzle/core/utils/puzzle_piece_utils.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_board.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_piece.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'puzzle_bloc.freezed.dart';
part 'puzzle_event.dart';
part 'puzzle_state.dart';

class PuzzleBloc extends Bloc<PuzzleEvent, PuzzleState> {
  static const double collisionTolerance = 2;
  static const double intersectionWidthThreshold = 2;
  static const double gridEdgeTolerance = 5;
  static const double maxCellSize = 50;
  static const int gridRows = 7;
  static const int gridColumns = 7;
  static const double defaultPadding = 16.0;
  static const double wideScreenPadding = 24.0;
  static const double boardExtraX = 1.5;
  static const Duration solvingDelay = Duration(milliseconds: 200);
  static const String placementIdPattern = r'^(.+)_r(\d+)_c(\d+)_rot(\d+)(_F)?$';
  static const double rotationStep = math.pi / 2;
  static const double fullRotation = math.pi * 2;
  static const double gridCenterOffset = 0.5;

  final SettingsQuery _settings;
  final Set<String> _keepOnGridIds = {};
  Size? _lastViewSize;

  PuzzleBloc({required SettingsQuery settings}) : _settings = settings, super(PuzzleState.initial()) {
    on<_SetViewSize>(_setViewSize);
    on<_Reset>(_reset);
    on<_OnTapDown>(_onTapDown);
    on<_OnTapUp>(_onTapUp);
    on<_OnPanStart>(_onPanStart);
    on<_OnPanUpdate>(_onPanUpdate);
    on<_OnPanEnd>(_onPanEnd);
    on<_OnDoubleTapDown>(_onDoubleTapDown);
    on<_RotatePiece>(_rotatePiece);
    on<_Solve>(_solve);
    on<_SetSolvingResults>(_setSolvingResults);
    on<_ShowSolution>(_showSolution);
    on<_Hint>(_hint);
    on<_SetHintingResults>(_setHintingResults);
    on<_ShowHint>(_showHint);
    on<_Configure>(_configure);
    on<_Undo>(_undoMove);
    on<_Redo>(_redoMove);
  }

  PuzzlePiece? _findPieceAtPosition(Offset position) =>
      state.pieces.lastWhereOrNull((piece) => piece.containsPoint(position));

  PlaceZone? _getZoneAtPosition(Offset position) {
    if (state.gridConfig.getBounds.contains(position)) {
      return PlaceZone.grid;
    } else if (state.boardConfig.getBounds.contains(position)) {
      return PlaceZone.board;
    }
    return null;
  }

  /// Checks for collision of piece at newPosition.
  bool _checkCollision({required PuzzlePiece piece, required Offset newPosition, required PlaceZone zone}) {
    final testPiece = piece.copyWith(position: newPosition);
    final testPath = testPiece.getTransformedPath();
    final testBounds = testPath.getBounds();

    if (_settings.preventOverlap) {
      final piecesToCheck = state.piecesByZone(zone).where((p) => p.id != piece.id);
      for (var otherPiece in piecesToCheck) {
        final otherPath = otherPiece.getTransformedPath();
        final otherBounds = otherPath.getBounds();

        if (!testBounds.overlaps(otherBounds)) {
          continue;
        }

        try {
          final combinedPath = Path.combine(PathOperation.intersect, testPath, otherPath);
          final intersectionBounds = combinedPath.getBounds();

          if (!intersectionBounds.isEmpty &&
              intersectionBounds.width > intersectionWidthThreshold &&
              intersectionBounds.height > collisionTolerance) {
            return true;
          }
        } catch (e) {
          debugPrint('Checking collision exception: $e');
          return true;
        }
      }
    }
    switch (zone) {
      case PlaceZone.grid:
        final gridRect = state.gridConfig.getBounds;
        // For grid, ensure the piece is mostly inside the grid
        // This is less strict than requiring all corners to be inside
        final centerX = testBounds.left + testBounds.width * gridCenterOffset;
        final centerY = testBounds.top + testBounds.height * gridCenterOffset;
        final pieceCenter = Offset(centerX, centerY);
        if (!gridRect.contains(pieceCenter)) {
          debugPrint('Piece center outside grid');
          return true;
        }
        // Allow some tolerance for pieces at edges
        final expandedGrid = Rect.fromLTRB(
          gridRect.left - gridEdgeTolerance,
          gridRect.top - gridEdgeTolerance,
          gridRect.right + gridEdgeTolerance,
          gridRect.bottom + gridEdgeTolerance,
        );
        if (testBounds.left < expandedGrid.left ||
            testBounds.right > expandedGrid.right ||
            testBounds.top < expandedGrid.top ||
            testBounds.bottom > expandedGrid.bottom) {
          debugPrint('Piece partially outside grid');
          return true;
        }
      case PlaceZone.board:
        if (!state.boardConfig.getBounds.overlaps(testBounds)) {
          debugPrint('Piece not overlapping with board');
          return true;
        }
    }

    return false;
  }

  List<PuzzlePiece> _updatePieceInList(List<PuzzlePiece> statePieces, PuzzlePiece piece) {
    return List<PuzzlePiece>.from(statePieces)
      ..removeWhere((p) => p.id == piece.id)
      ..add(piece);
  }

  PuzzlePiece _applyPlacementToPiece(PuzzlePiece piece, PlacementParams params) {
    final cellSize = state.gridConfig.cellSize;
    final origin = state.gridConfig.origin;
    final dx = params.col * cellSize;
    final dy = params.row * cellSize;
    final targetOffset = Offset(origin.dx + dx, origin.dy + dy);

    final updatedPiece = piece.copyWith(
      isFlipped: params.isFlipped,
      position: targetOffset,
      rotation: params.rotationSteps * rotationStep,
      placeZone: PlaceZone.grid,
    );
    return updatedPiece;
  }

  FutureOr<void> _setViewSize(_SetViewSize event, Emitter<PuzzleState> emit) {
    if (_lastViewSize != event.viewSize && event.viewSize.width > 0 && event.viewSize.height > 0) {
      add(PuzzleEvent.configure(viewSize: event.viewSize, prevState: state, forbiddenPieces: []));
    }
  }

  FutureOr<void> _reset(_Reset event, Emitter<PuzzleState> emit) {
    if (_lastViewSize == null) {
      emit(PuzzleState.initial());
    } else {
      add(
        PuzzleEvent.configure(
          viewSize: _lastViewSize!,
          prevState: PuzzleState.initial(),
          forbiddenPieces: _settings.unlockConfig ? [] : state.gridPieces.where((e) => e.isForbidden),
        ),
      );
    }
    _keepOnGridIds.clear();
  }

  FutureOr<void> _onTapDown(_OnTapDown event, Emitter<PuzzleState> emit) {
    final piece = _findPieceAtPosition(event.localPosition);
    if (piece != null && (!piece.isForbidden || _settings.unlockConfig)) {
      emit(state.copyWith(selectedPiece: piece));
    }
  }

  FutureOr<void> _onTapUp(_OnTapUp event, Emitter<PuzzleState> emit) {
    if (state.selectedPiece != null && !state.isDragging) {
      add(PuzzleEvent.rotatePiece(state.selectedPiece!));
    }
    emit(state.copyWith(selectedPiece: null, isDragging: false));
  }

  FutureOr<void> _rotatePiece(_RotatePiece event, Emitter<PuzzleState> emit) {
    final selectedPiece = event.piece.copyWith(rotation: _normalizeRotation(event.piece.rotation));
    final shouldSnap = event.piece.placeZone == PlaceZone.grid && _settings.snapToGridOnTransform;
    final (pieceToSave, snapMove) = shouldSnap ? _maybeSnap(selectedPiece) : (selectedPiece, null);
    final move = RotatePiece(selectedPiece.id, rotation: selectedPiece.rotation, snapCorrection: snapMove);
    emit(
      state.copyWith(
        pieces: _updatePieceInList(state.pieces, pieceToSave),
        moveHistory: [...state.moveHistory, move],
        moveIndex: state.moveIndex + 1,
      ),
    );
  }

  FutureOr<void> _onPanStart(_OnPanStart event, Emitter<PuzzleState> emit) {
    final piece = _findPieceAtPosition(event.localPosition) ?? state.selectedPiece;
    if (piece != null && (!piece.isForbidden || _settings.unlockConfig)) {
      final pieces = List<PuzzlePiece>.from(state.pieces);
      final pieceIndex = pieces.indexWhere((item) => item.id == piece.id);
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
          dragStartZone: _getZoneAtPosition(piece.position),
          isDragging: true,
        ),
      );
    }
  }

  FutureOr<void> _onPanUpdate(_OnPanUpdate event, Emitter<PuzzleState> emit) {
    if (state.selectedPiece != null && state.dragStartOffset != null) {
      final newPosition = event.localPosition - state.dragStartOffset!;
      final piece = state.selectedPiece!.copyWith(position: newPosition);
      final pieces = List<PuzzlePiece>.from(state.pieces);
      final pieceIndex = pieces.indexWhere((item) => item.id == piece.id);
      if (pieceIndex >= 0) {
        pieces[pieceIndex] = piece;
      } else {
        debugPrint('_onPanUpdate, piece not found!');
      }
      final currentZone = _getZoneAtPosition(newPosition);
      switch (currentZone) {
        case PlaceZone.grid:
          emit(
            state.copyWith(
              pieces: pieces,
              selectedPiece: piece,
              showPreview: true,
              previewPosition: state.gridConfig.snapToGrid(newPosition),
              previewCollision: _checkCollision(
                piece: piece,
                newPosition: state.gridConfig.snapToGrid(newPosition),
                zone: currentZone!,
              ),
            ),
          );
        case PlaceZone.board:
        case null:
          emit(state.copyWith(pieces: pieces, selectedPiece: piece, showPreview: false, previewCollision: false));
      }
    }
  }

  FutureOr<void> _onPanEnd(_OnPanEnd event, Emitter<PuzzleState> emit) {
    if (state.selectedPiece != null) {
      final newZone = _getZoneAtPosition(state.selectedPiece!.position);
      Offset snappedPosition;
      bool collisionDetected = false;
      switch (newZone) {
        case PlaceZone.grid:
          snappedPosition = state.gridConfig.snapToGrid(state.selectedPiece!.position);
          collisionDetected = _checkCollision(
            piece: state.selectedPiece!,
            newPosition: snappedPosition,
            zone: newZone!,
          );
        case PlaceZone.board:
          snappedPosition = state.selectedPiece!.position;
          final boardBounds = state.boardConfig.getBounds;
          final pieceBounds = state.selectedPiece!.getTransformedPath().getBounds();

          if (pieceBounds.left < boardBounds.left) {
            snappedPosition = Offset(snappedPosition.dx + (boardBounds.left - pieceBounds.left), snappedPosition.dy);
          }
          if (pieceBounds.right > boardBounds.right) {
            snappedPosition = Offset(snappedPosition.dx - (pieceBounds.right - boardBounds.right), snappedPosition.dy);
          }
          if (pieceBounds.top < boardBounds.top) {
            snappedPosition = Offset(snappedPosition.dx, snappedPosition.dy + (boardBounds.top - pieceBounds.top));
          }
          if (pieceBounds.bottom > boardBounds.bottom) {
            snappedPosition = Offset(
              snappedPosition.dx,
              snappedPosition.dy - (pieceBounds.bottom - boardBounds.bottom),
            );
          }

          collisionDetected = false;
        default:
          snappedPosition = state.pieceStartPosition!;
          collisionDetected = true;
          debugPrint('not over either zone, return to starting position');
      }

      if (!collisionDetected) {
        final selectedPiece = state.selectedPiece!.copyWith(
          position: snappedPosition,
          placeZone: newZone ?? state.selectedPiece!.placeZone,
        );

        final fromConfig = state.dragStartZone == PlaceZone.grid ? state.gridConfig : state.boardConfig;
        final toConfig = newZone == PlaceZone.grid ? state.gridConfig : state.boardConfig;
        final move = MovePiece(
          selectedPiece.id,
          from: MovePlacement(
            zone: state.dragStartZone ?? PlaceZone.board,
            position: fromConfig.relativePosition(state.pieceStartPosition!),
          ),
          to: MovePlacement(zone: newZone!, position: toConfig.relativePosition(snappedPosition)),
        );
        final moveHistory = List<Move>.from(state.moveHistory);
        if (moveHistory.length > state.moveIndex) {
          moveHistory.removeRange(state.moveIndex, moveHistory.length);
        }
        moveHistory.add(move);
        emit(
          state.copyWith(
            pieces: _updatePieceInList(state.pieces, selectedPiece),
            showPreview: false,
            previewPosition: null,
            selectedPiece: null,
            dragStartOffset: null,
            pieceStartPosition: null,
            dragStartZone: null,
            isDragging: false,
            moveHistory: moveHistory,
            moveIndex: moveHistory.length,
          ),
        );
      } else {
        debugPrint(
          'Collision detected, returning to original position, pieceStartPosition: ${state.pieceStartPosition}',
        );
        final selectedPiece = state.selectedPiece!.copyWith(position: state.pieceStartPosition);
        emit(
          state.copyWith(
            pieces: _updatePieceInList(state.pieces, selectedPiece),
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

  FutureOr<void> _onDoubleTapDown(_OnDoubleTapDown event, Emitter<PuzzleState> emit) {
    final piece = _findPieceAtPosition(event.localPosition);
    if (piece != null && (!piece.isForbidden || _settings.unlockConfig)) {
      final flippedPiece = piece.copyWith(isFlipped: !piece.isFlipped);
      final shouldSnap = piece.placeZone == PlaceZone.grid && _settings.snapToGridOnTransform;
      final (pieceToSave, snapMove) = shouldSnap ? _maybeSnap(flippedPiece) : (flippedPiece, null);
      final move = FlipPiece(flippedPiece.id, isFlipped: flippedPiece.isFlipped, snapCorrection: snapMove);
      emit(
        state.copyWith(
          pieces: _updatePieceInList(state.pieces, pieceToSave),
          moveHistory: [...state.moveHistory, move],
          moveIndex: state.moveIndex + 1,
        ),
      );
    }
  }

  Future<void> _solve(_Solve event, Emitter<PuzzleState> emit) async {
    emit(state.copyWith(status: GameStatus.searchingAllSolutions, solutions: [], solutionIdx: -1));
    await Future.delayed(solvingDelay);
    if (event.keepUserMoves) {
      _keepOnGridIds.addAll(state.gridPieces.map((e) => e.id));
    } else {
      _keepOnGridIds.clear();
    }
    SolvePuzzleUseCase().call(pieces: state.pieces, grid: state.gridConfig, keepUserMoves: event.keepUserMoves).then((
      solutions,
    ) {
      debugPrint('solving finished, found solutions: ${solutions.length}');
      add(PuzzleEvent.setSolvingResults(solutions));
    });
  }

  FutureOr<void> _setSolvingResults(_SetSolvingResults event, Emitter<PuzzleState> emit) {
    emit(state.copyWith(status: GameStatus.solutionsReady, solutions: event.solutions));
    for (final solution in event.solutions) {
      debugPrint('sol: $solution');
    }
  }

  FutureOr<void> _showSolution(_ShowSolution event, Emitter<PuzzleState> emit) {
    final solutionIds = state.solutions[event.index];
    final gridPieces = state.gridPieces
        .where((e) => e.isForbidden || _keepOnGridIds.contains(e.id))
        .map((p) => p.copyWith(originalPath: generatePathForType(p.type, state.gridConfig.cellSize)))
        .toList();
    for (var solution in solutionIds) {
      final params = _parsePlacementId(solution);
      if (params == null) continue;
      final piece = state.pieces.firstWhere((p) => p.id == params.pieceId);
      gridPieces.add(_applyPlacementToPiece(piece, params).copyWith(isUserMove: false));
    }
    emit(state.copyWith(pieces: gridPieces, solutionIdx: event.index, moveHistory: [], moveIndex: 0));
  }

  FutureOr<void> _hint(_Hint event, Emitter<PuzzleState> emit) async {
    emit(state.copyWith(status: GameStatus.searchingHint, solutions: []));
    await Future.delayed(solvingDelay);
    HintPuzzleUseCase().call(pieces: state.pieces, grid: state.gridConfig).then((solutions) {
      debugPrint('hinting finished, found solutions: ${solutions.length}');
      add(PuzzleEvent.setHintingResults(solutions));
    });
  }

  FutureOr<void> _setHintingResults(_SetHintingResults event, Emitter<PuzzleState> emit) {
    emit(state.copyWith(status: GameStatus.hintReady, solutions: event.solutions));
  }

  FutureOr<void> _showHint(_ShowHint event, Emitter<PuzzleState> emit) {
    final solutionIds = state.solutions[event.index];
    final gridPieces = List<PuzzlePiece>.from(state.gridPieces);

    final solution = solutionIds.first;
    final params = _parsePlacementId(solution);
    final piece = state.pieces.firstWhere((p) => p.id == params!.pieceId);
    gridPieces.add(_applyPlacementToPiece(piece, params!));
    final boardPieces = List<PuzzlePiece>.from(state.boardPieces)..removeWhere((p) => p.id == params.pieceId);
    emit(
      state.copyWith(
        pieces: [...gridPieces, ...boardPieces],
        solutionIdx: event.index,
        //todo hint move should be in history too
        moveHistory: [],
        moveIndex: 0,
      ),
    );
  }

  PlacementParams? _parsePlacementId(String solution) {
    final match = RegExp(placementIdPattern).firstMatch(solution);
    if (match == null) return null;

    final pieceId = match.group(1)!;
    final row = int.parse(match.group(2)!);
    final col = int.parse(match.group(3)!);
    final rotSteps = int.parse(match.group(4)!);
    final flipped = match.group(5) != null;

    return PlacementParams(pieceId, row, col, rotSteps, flipped);
  }

  FutureOr<void> _configure(_Configure event, Emitter<PuzzleState> emit) {
    final viewSize = event.viewSize;
    final prevState = event.prevState;
    final forbiddenPieces = event.forbiddenPieces;

    double calcCellSize(final Size viewSize) {
      final smallestSide = viewSize.width > viewSize.height ? viewSize.height : viewSize.width;
      final floored = (smallestSide / (gridRows + 1)).floor();
      return floored < maxCellSize
          ? floored.isEven
                ? floored.toDouble()
                : floored - 1.0
          : maxCellSize;
    }

    final gCellSize = calcCellSize(viewSize);
    final gLeftPadding = gCellSize < maxCellSize || viewSize.height < viewSize.width
        ? wideScreenPadding
        : (viewSize.width - gCellSize * gridColumns) / 2;

    final gridConfig = PuzzleGrid(
      cellSize: gCellSize,
      rows: gridRows,
      columns: gridColumns,
      origin: Offset(gLeftPadding, defaultPadding),
    );

    final boardConfig = PuzzleBoard(
      cellSize: gCellSize + gLeftPadding / gridColumns,
      rows: gridRows,
      columns: gridColumns,
      origin: Offset(
        viewSize.height > viewSize.width
            ? gLeftPadding / 2
            : gridConfig.origin.dx + gridConfig.cellSize * gridConfig.columns + defaultPadding,
        viewSize.height > viewSize.width
            ? gridConfig.origin.dy + gridConfig.cellSize * gridConfig.rows + defaultPadding
            : defaultPadding,
      ),
    );

    final boardX = boardConfig.initialX(gCellSize);
    final boardY = boardConfig.initialY(gCellSize);
    final cellXOffset = gCellSize + boardExtraX;

    final centerPoint = Offset(gCellSize * gridCenterOffset, gCellSize * gridCenterOffset);
    List<PuzzlePiece> boardPieces = [];
    List<PuzzlePiece> gridPieces = [];
    if (prevState.pieces.isEmpty) {
      boardPieces = [
        PuzzlePiece.fromType(PieceType.lShape, Offset(boardX, boardY + gCellSize * 4), centerPoint, gCellSize),
        PuzzlePiece.fromType(
          PieceType.square,
          Offset(boardX + cellXOffset * 5 + boardExtraX, boardY + gCellSize * 2),
          centerPoint,
          gCellSize,
        ),
        PuzzlePiece.fromType(PieceType.zShape, Offset(boardX + cellXOffset * 4, boardY), centerPoint, gCellSize),
        PuzzlePiece.fromType(
          PieceType.yShape,
          Offset(boardX + boardExtraX * 2, boardY + gCellSize * 2),
          centerPoint,
          gCellSize,
        ),
        PuzzlePiece.fromType(
          PieceType.uShape,
          Offset(boardX + cellXOffset + boardExtraX, boardY + gCellSize * 3),
          centerPoint,
          gCellSize,
        ),
        PuzzlePiece.fromType(PieceType.pShape, Offset(boardX, boardY), centerPoint, gCellSize),
        PuzzlePiece.fromType(PieceType.nShape, Offset(boardX + 2 * cellXOffset, boardY), centerPoint, gCellSize),
        PuzzlePiece.fromType(
          PieceType.vShape,
          Offset(boardX + cellXOffset * 4, boardY + gCellSize * 3),
          centerPoint,
          gCellSize,
        ),
      ];

      gridPieces = forbiddenPieces.isNotEmpty
          ? forbiddenPieces.toList()
          : [
              PuzzlePiece.fromType(
                PieceType.zone1,
                Offset(gridConfig.origin.dx + gCellSize * 6, gridConfig.origin.dy),
                centerPoint,
                gCellSize,
              ),
              PuzzlePiece.fromType(
                PieceType.zone2,
                Offset(gridConfig.origin.dx + gCellSize * 3, gridConfig.origin.dy + gCellSize * 6),
                centerPoint,
                gCellSize,
              ),
            ];
    } else {
      final gridCellMod = gCellSize / prevState.gridConfig.cellSize;

      final prevGridX = prevState.gridConfig.origin.dx;
      final prevGridY = prevState.gridConfig.origin.dy;
      final gridDeltaX = gridConfig.origin.dx - prevGridX * gridCellMod;
      final gridDeltaY = gridConfig.origin.dy - prevGridY * gridCellMod;

      gridPieces = prevState.gridPieces
          .map(
            (p) => p.copyWith(
              originalPath: generatePathForType(p.type, gCellSize),
              position: gridConfig.snapToGrid(
                Offset(p.position.dx * gridCellMod + gridDeltaX, p.position.dy * gridCellMod + gridDeltaY),
              ),
              centerPoint: centerPoint,
            ),
          )
          .toList();

      final prevBoardX = prevState.boardConfig.initialX(prevState.gridConfig.cellSize);
      final prevBoardY = prevState.boardConfig.initialY(prevState.gridConfig.cellSize);
      final boardDeltaX = boardX - prevBoardX * gridCellMod;
      final boardDeltaY = boardY - prevBoardY * gridCellMod;

      boardPieces = prevState.boardPieces
          .map(
            (p) => p.copyWith(
              originalPath: generatePathForType(p.type, gCellSize),
              position: Offset(p.position.dx * gridCellMod + boardDeltaX, p.position.dy * gridCellMod + boardDeltaY),
              centerPoint: centerPoint,
            ),
          )
          .toList();
    }
    emit(
      prevState.copyWith(
        status: GameStatus.waiting,
        gridConfig: gridConfig,
        boardConfig: boardConfig,
        pieces: [...gridPieces, ...boardPieces],
      ),
    );
    _lastViewSize = event.viewSize;
  }

  FutureOr<void> _undoMove(_Undo event, Emitter<PuzzleState> emit) {
    if (state.moveHistory.isNotEmpty && state.moveIndex > 0) {
      final idx = state.moveIndex - 1;
      final undoPiece = _getHistoryPiece(idx, true);
      emit(state.copyWith(moveIndex: idx, pieces: _updatePieceInList(state.pieces, undoPiece)));
    }
  }

  FutureOr<void> _redoMove(_Redo event, Emitter<PuzzleState> emit) {
    final idx = state.moveIndex + 1;
    final redoPiece = _getHistoryPiece(state.moveIndex, false);
    emit(state.copyWith(moveIndex: idx, pieces: _updatePieceInList(state.pieces, redoPiece)));
  }

  PuzzlePiece _getHistoryPiece(int idx, bool isUndo) {
    final move = state.moveHistory[idx];
    final piece = state.pieces.firstWhere((p) => p.id == move.pieceId);

    final historyPiece = move.map(
      movePiece: (mp) {
        final zone = isUndo ? mp.from.zone : mp.to.zone;
        final config = zone == PlaceZone.grid ? state.gridConfig : state.boardConfig;
        return piece.copyWith(
          placeZone: zone,
          position: config.absolutPosition(isUndo ? mp.from.position : mp.to.position),
        );
      },
      rotatePiece: (rp) => piece.copyWith(
        rotation: (rp.rotation - (isUndo ? rotationStep + fullRotation : 0)) % fullRotation,
        position: rp.snapCorrection != null
            ? state.gridConfig.absolutPosition(isUndo ? rp.snapCorrection!.from.position : rp.snapCorrection!.to.position)
            : null,
      ),
      flipPiece: (fp) => piece.copyWith(
        isFlipped: isUndo ? !fp.isFlipped : fp.isFlipped,
        position: fp.snapCorrection != null
            ? state.gridConfig.absolutPosition(isUndo ? fp.snapCorrection!.from.position : fp.snapCorrection!.to.position)
            : null,
      ),
    );

    return historyPiece;
  }

  double _normalizeRotation(double value) => (value + rotationStep) % fullRotation;

  (PuzzlePiece piece, MovePiece? snapMove) _maybeSnap(PuzzlePiece selectedPiece) {
    final snappedPos = _snappedPosition(selectedPiece);
    if (snappedPos == selectedPiece.position) {
      return (selectedPiece, null);
    }
    final snapped = selectedPiece.copyWith(position: snappedPos);
    final snapMove = MovePiece(
      selectedPiece.id,
      from: MovePlacement(position: state.gridConfig.relativePosition(selectedPiece.position)),
      to: MovePlacement(position: state.gridConfig.relativePosition(snapped.position)),
    );
    return (snapped, snapMove);
  }

  Offset _snappedPosition(PuzzlePiece selectedPiece) {
    Offset targetPosition = selectedPiece.position;

    Offset preSnapped = state.gridConfig.snapToGrid(targetPosition);
    final gridBounds = state.gridConfig.getBounds;

    final testPiece = selectedPiece.copyWith(position: preSnapped);
    final pieceBounds = testPiece.getTransformedPath().getBounds();

    double dx = 0.0;
    double dy = 0.0;
    if (pieceBounds.left < gridBounds.left) {
      dx += gridBounds.left - pieceBounds.left;
    }
    if (pieceBounds.right > gridBounds.right) {
      dx -= pieceBounds.right - gridBounds.right;
    }
    if (pieceBounds.top < gridBounds.top) {
      dy += gridBounds.top - pieceBounds.top;
    }
    if (pieceBounds.bottom > gridBounds.bottom) {
      dy -= pieceBounds.bottom - gridBounds.bottom;
    }
    targetPosition = Offset(preSnapped.dx + dx, preSnapped.dy + dy);
    return state.gridConfig.snapToGrid(targetPosition);
  }
}
