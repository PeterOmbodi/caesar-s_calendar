import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:caesar_puzzle/application/contracts/settings_query.dart';
import 'package:caesar_puzzle/application/solve_puzzle_use_case.dart';
import 'package:caesar_puzzle/core/models/cell.dart';
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
  PuzzleBloc({required final SettingsQuery settings}) : _settings = settings, super(PuzzleState.initial()) {
    on<_SetViewSize>(_onViewSize);
    on<_Reset>(_reset);
    on<_Configure>(_configure);
    on<_OnTapDown>(_onTapDown);
    on<_OnTapUp>(_onTapUp);
    on<_OnPanStart>(_onPanStart);
    on<_OnPanUpdate>(_onPanUpdate);
    on<_OnPanEnd>(_onPanEnd);
    on<_OnDoubleTapDown>(_flipPiece);
    on<_RotatePiece>(_rotatePiece);
    on<_Solve>(_solve);
    on<_SetSolvingResults>(_setSolvingResults);
    on<_ShowSolution>(_showSolution);
    on<_ShowHint>(_showHint);
    on<_Undo>(_undoMove);
    on<_Redo>(_redoMove);
  }

  static const double collisionTolerance = 2;
  static const double intersectionWidthThreshold = 2;
  static const double gridEdgeTolerance = 5;
  static const double maxCellSize = 50;
  static const int gridRows = 7;
  static const int gridColumns = 7;
  static const double defaultPadding = 16.0;
  static const double wideScreenPadding = 24.0;
  static const double boardExtraX = 1.5;
  static const double rotationStep = math.pi / 2;
  static const double fullRotation = math.pi * 2;
  static const double gridCenterOffset = 0.5;

  final SettingsQuery _settings;
  Size? _lastViewSize;

  /* handle events */

  FutureOr<void> _onViewSize(final _SetViewSize event, final Emitter<PuzzleState> emit) {
    if (_lastViewSize != event.viewSize && event.viewSize.width > 0 && event.viewSize.height > 0) {
      add(PuzzleEvent.configure(viewSize: event.viewSize));
    }
  }

  FutureOr<void> _reset(final _Reset event, final Emitter<PuzzleState> emit) {
    if (_lastViewSize == null) {
      emit(PuzzleState.initial());
    } else {
      add(
        PuzzleEvent.configure(
          viewSize: _lastViewSize!,
          toInitial: true,
          configurationPieces: _settings.unlockConfig ? [] : state.gridPieces.where((final e) => e.isConfigItem),
        ),
      );
    }
    if (state.solutions.isEmpty && _settings.requireSolutions) {
      add(PuzzleEvent.solve(showResult: false));
    }
  }

  Future<void> _configure(final _Configure event, final Emitter<PuzzleState> emit) async {
    final viewSize = event.viewSize;
    final configurationPieces = event.configurationPieces;
    final isInitializing = state.status == GameStatus.initializing || event.toInitial;

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
    var boardPieces = <PuzzlePiece>[];
    var gridPieces = <PuzzlePiece>[];
    if (isInitializing) {
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

      gridPieces = configurationPieces.isNotEmpty
          ? configurationPieces.toList()
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
      final gridCellMod = gCellSize / state.gridConfig.cellSize;

      final prevGridX = state.gridConfig.origin.dx;
      final prevGridY = state.gridConfig.origin.dy;
      final gridDeltaX = gridConfig.origin.dx - prevGridX * gridCellMod;
      final gridDeltaY = gridConfig.origin.dy - prevGridY * gridCellMod;

      gridPieces = state.gridPieces
          .map(
            (final p) => p.copyWith(
              originalPath: generatePathForType(p.type, gCellSize),
              position: gridConfig.snapToGrid(
                Offset(p.position.dx * gridCellMod + gridDeltaX, p.position.dy * gridCellMod + gridDeltaY),
              ),
              centerPoint: centerPoint,
            ),
          )
          .toList();

      final prevBoardX = state.boardConfig.initialX(state.gridConfig.cellSize);
      final prevBoardY = state.boardConfig.initialY(state.gridConfig.cellSize);
      final boardDeltaX = boardX - prevBoardX * gridCellMod;
      final boardDeltaY = boardY - prevBoardY * gridCellMod;

      boardPieces = state.boardPieces
          .map(
            (final p) => p.copyWith(
              originalPath: generatePathForType(p.type, gCellSize),
              position: Offset(p.position.dx * gridCellMod + boardDeltaX, p.position.dy * gridCellMod + boardDeltaY),
              centerPoint: centerPoint,
            ),
          )
          .toList();
    }
    final newState = state.copyWith(
      gridConfig: gridConfig,
      boardConfig: boardConfig,
      pieces: [...gridPieces, ...boardPieces],
    );

    if (isInitializing) {
      emit(newState.copyWith(status: GameStatus.initialized, solutionIdx: -1, moveHistory: [], moveIndex: 0));
    } else {
      emit(newState);
    }
    _lastViewSize = event.viewSize;
    if (isInitializing) {
      //solving causes UI freezes, let`s wait a bit for animation comlplete
      await Future<void>.delayed(Duration(milliseconds: 150));
      add(PuzzleEvent.solve(showResult: false));
    }
  }

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
      final pieces = List<PuzzlePiece>.from(state.pieces);
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
          dragStartZone: _getZoneAtPosition(piece.position),
          isDragging: true,
        ),
      );
    }
  }

  FutureOr<void> _onPanUpdate(final _OnPanUpdate event, final Emitter<PuzzleState> emit) {
    if (state.selectedPiece != null && state.dragStartOffset != null) {
      final newPosition = event.localPosition - state.dragStartOffset!;
      final piece = state.selectedPiece!.copyWith(position: newPosition);
      final pieces = List<PuzzlePiece>.from(state.pieces);
      final pieceIndex = pieces.indexWhere((final item) => item.id == piece.id);
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
                preventOverlap: _settings.preventOverlap,
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
      final newZone = _getZoneAtPosition(state.selectedPiece!.position);
      Offset snappedPosition;
      var collisionDetected = false;
      switch (newZone) {
        case PlaceZone.grid:
          snappedPosition = state.gridConfig.snapToGrid(state.selectedPiece!.position);
          collisionDetected = _checkCollision(
            piece: state.selectedPiece!,
            newPosition: snappedPosition,
            zone: newZone!,
            preventOverlap: _settings.preventOverlap,
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
        final pieces = _updatePieceInList(selectedPiece);
        emit(
          state.copyWith(
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
            applicableSolutions: _combineSolutions(state.solutions, pieces),
          ),
        );
        if (selectedPiece.isConfigItem && _settings.requireSolutions) {
          add(PuzzleEvent.solve(showResult: false));
        }
      } else {
        debugPrint(
          'Collision detected, returning to original position, pieceStartPosition: ${state.pieceStartPosition}',
        );
        final selectedPiece = state.selectedPiece!.copyWith(position: state.pieceStartPosition);
        emit(
          state.copyWith(
            pieces: _updatePieceInList(selectedPiece),
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

  FutureOr<void> _flipPiece(final _OnDoubleTapDown event, final Emitter<PuzzleState> emit) {
    final selectedPiece = _findPieceAtPosition(event.localPosition);
    if (selectedPiece != null && (!selectedPiece.isConfigItem || _settings.unlockConfig)) {
      final flippedPiece = selectedPiece.copyWith(isFlipped: !selectedPiece.isFlipped);
      final shouldSnap = selectedPiece.placeZone == PlaceZone.grid && _settings.snapToGridOnTransform;
      final (pieceToSave, snapMove) = shouldSnap ? _maybeSnap(flippedPiece) : (flippedPiece, null);
      final move = FlipPiece(flippedPiece.id, snapMove, isFlipped: flippedPiece.isFlipped);
      final pieces = _updatePieceInList(pieceToSave);
      final shouldResolve = selectedPiece.isConfigItem && _settings.requireSolutions;
      final applicableSolutions = shouldResolve
          ? state.applicableSolutions
          : _combineSolutions(state.solutions, pieces);
      emit(
        state.copyWith(
          pieces: pieces,
          moveHistory: [...state.moveHistory, move],
          moveIndex: state.moveIndex + 1,
          status: _getStatus(pieces),
          applicableSolutions: applicableSolutions,
        ),
      );
      if (shouldResolve) {
        add(PuzzleEvent.solve(showResult: false));
      }
    }
  }

  FutureOr<void> _rotatePiece(final _RotatePiece event, final Emitter<PuzzleState> emit) {
    final selectedPiece = event.piece.copyWith(rotation: _stepRotation(event.piece.rotation));
    final shouldSnap = event.piece.placeZone == PlaceZone.grid && _settings.snapToGridOnTransform;
    final (pieceToSave, snapMove) = shouldSnap ? _maybeSnap(selectedPiece) : (selectedPiece, null);
    final move = RotatePiece(selectedPiece.id, snapMove, rotation: selectedPiece.rotation);
    final pieces = _updatePieceInList(pieceToSave);
    final shouldResolve = selectedPiece.isConfigItem && _settings.requireSolutions;
    final applicableSolutions = shouldResolve ? state.applicableSolutions : _combineSolutions(state.solutions, pieces);
    emit(
      state.copyWith(
        pieces: pieces,
        moveHistory: [...state.moveHistory, move],
        moveIndex: state.moveIndex + 1,
        status: _getStatus(pieces),
        applicableSolutions: applicableSolutions,
      ),
    );
    if (shouldResolve) {
      add(PuzzleEvent.solve(showResult: false));
    }
  }

  Future<void> _solve(final _Solve event, final Emitter<PuzzleState> emit) async {
    emit(state.copyWith(status: GameStatus.searchingSolutions, solutions: [], solutionIdx: -1));
    await Future<void>.delayed(Duration.zero);
    unawaited(
      SolvePuzzleUseCase().call(pieces: state.pieces, grid: state.gridConfig).then((final solutions) {
        debugPrint('solving finished, found solutions: ${solutions.length}');
        add(PuzzleEvent.setSolvingResults(solutions));
        if (event.showResult) {
          add(PuzzleEvent.showSolution(0));
        }
      }),
    );
  }

  FutureOr<void> _setSolvingResults(final _SetSolvingResults event, final Emitter<PuzzleState> emit) {
    emit(
      state.copyWith(
        status: GameStatus.solutionsReady,
        solutions: event.solutions.toList(),
        applicableSolutions: _combineSolutions(event.solutions, state.pieces),
      ),
    );
  }

  FutureOr<void> _showSolution(final _ShowSolution event, final Emitter<PuzzleState> emit) {
    if (state.solutions.isEmpty && state.status != GameStatus.solutionsReady) {
      add(PuzzleEvent.solve(showResult: true));
      return Future.value();
    }
    final applicableSolutions = state.applicableSolutions;
    final solutionIds = applicableSolutions.length > event.index
        ? applicableSolutions[event.index]
        : <String, String>{};
    final gridPieces = state.gridPieces
        .where((final e) => e.isConfigItem || e.isUsersItem)
        .map((final p) => p.copyWith(originalPath: generatePathForType(p.type, state.gridConfig.cellSize)))
        .toList();
    for (final solution in solutionIds.entries) {
      final params = _parsePlacementParams(solution);
      if (params == null) continue;
      final piece = state.pieces.firstWhere((final p) => p.id == params.pieceId);
      if (gridPieces.firstWhereOrNull((final e) => e.id == piece.id) == null) {
        gridPieces.add(_applyPlacementToPiece(piece, params).copyWith(isUsersItem: false));
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

  FutureOr<void> _showHint(final _ShowHint event, final Emitter<PuzzleState> emit) {
    final possibleSolutions = state.applicableSolutions.length;
    final solutionIndex = possibleSolutions < 2 ? 0 : math.Random().nextInt(possibleSolutions - 1);
    final encodedSolution = state.applicableSolutions[solutionIndex];
    final onGridIds = state.gridPieces.map((final e) => e.id);
    final encodedPieces = encodedSolution.entries.where((final e) => !onGridIds.contains(e.key)).toList();
    final pececIndex = encodedPieces.length == 1 ? 0 : math.Random().nextInt(encodedPieces.length - 1);
    final params = _parsePlacementParams(encodedPieces[pececIndex]);

    final sourcePiece = state.pieces.firstWhere((final p) => p.id == params!.pieceId);
    final targetPiece = _applyPlacementToPiece(sourcePiece, params!).copyWith(isUsersItem: false);
    final pieces = _updatePieceInList(targetPiece);
    final applicableSolutions = _combineSolutions(state.solutions, pieces);

    final move = HintMove(
      targetPiece.id,
      from: MovePlacement(zone: PlaceZone.board, position: state.boardConfig.relativePosition(sourcePiece.position)),
      to: MovePlacement(position: state.gridConfig.relativePosition(targetPiece.position)),
      rotationFrom: sourcePiece.rotation,
      rotationTo: targetPiece.rotation,
      flippedFrom: sourcePiece.isFlipped,
      flippedTo: targetPiece.isFlipped,
    );
    emit(
      state.copyWith(
        pieces: pieces,
        applicableSolutions: applicableSolutions,
        moveHistory: [...state.moveHistory.take(state.moveIndex), move],
        moveIndex: state.moveIndex + 1,
      ),
    );
  }

  FutureOr<void> _undoMove(final _Undo event, final Emitter<PuzzleState> emit) {
    if (state.moveHistory.isNotEmpty && state.moveIndex > 0) {
      final idx = state.moveIndex - 1;
      final selectedPiece = _getHistoryPiece(idx, true);
      final pieces = _updatePieceInList(selectedPiece);
      final shouldResolve = selectedPiece.isConfigItem && _settings.requireSolutions;
      final applicableSolutions = shouldResolve
          ? state.applicableSolutions
          : _combineSolutions(state.solutions, pieces);
      emit(
        state.copyWith(
          moveIndex: idx,
          pieces: pieces,
          status: GameStatus.playing,
          applicableSolutions: applicableSolutions,
        ),
      );
      if (shouldResolve) {
        add(PuzzleEvent.solve(showResult: false));
      }
    }
  }

  FutureOr<void> _redoMove(final _Redo event, final Emitter<PuzzleState> emit) {
    final idx = state.moveIndex + 1;
    final selectedPiece = _getHistoryPiece(state.moveIndex, false);
    final pieces = _updatePieceInList(selectedPiece);
    final shouldResolve = selectedPiece.isConfigItem && _settings.requireSolutions;
    final applicableSolutions = shouldResolve ? state.applicableSolutions : _combineSolutions(state.solutions, pieces);
    emit(
      state.copyWith(
        moveIndex: idx,
        pieces: pieces,
        status: GameStatus.playing,
        applicableSolutions: applicableSolutions,
      ),
    );
    if (shouldResolve) {
      add(PuzzleEvent.solve(showResult: false));
    }
  }

  /*  helpers etc  */

  PuzzlePiece _applyPlacementToPiece(final PuzzlePiece piece, final PlacementParams params) {
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

  PuzzlePiece? _findPieceAtPosition(final Offset position) =>
      state.pieces.lastWhereOrNull((final piece) => piece.containsPoint(position));

  PlaceZone? _getZoneAtPosition(final Offset position) {
    if (state.gridConfig.getBounds.contains(position)) {
      return PlaceZone.grid;
    } else if (state.boardConfig.getBounds.contains(position)) {
      return PlaceZone.board;
    }
    return null;
  }

  PlacementParams? _parsePlacementParams(final MapEntry<String, String> encodedPlacement) {
    final match = RegExp(r'^r(\d+)_c(\d+)_rot(\d+)(_F)?$').firstMatch(encodedPlacement.value);
    if (match == null) return null;

    final row = int.parse(match.group(1)!);
    final col = int.parse(match.group(2)!);
    final rotSteps = int.parse(match.group(3)!);
    final flipped = match.group(4) != null;

    return PlacementParams(encodedPlacement.key, row, col, rotSteps, flipped);
  }

  //todo draft solution
  // need to check to empty date cells
  // need to change status for unique solutions only
  GameStatus _getStatus(final Iterable<PuzzlePiece> pieces) {
    if (state.selectedPiece?.isUsersItem == false) {
      return state.status;
    }
    return pieces.where((final p) => p.placeZone == PlaceZone.board).isEmpty &&
            !pieces.any(
              (final piece) => _checkCollision(
                piece: piece,
                newPosition: piece.position,
                zone: PlaceZone.grid,
                preventOverlap: true,
                pieces: pieces,
              ),
            )
        ? GameStatus.solvedByUser
        : GameStatus.playing;
  }

  /// Checks for collision of piece at newPosition.
  bool _checkCollision({
    required final PuzzlePiece piece,
    required final Offset newPosition,
    required final PlaceZone zone,
    required final preventOverlap,
    final Iterable<PuzzlePiece>? pieces,
  }) {
    final testPiece = piece.copyWith(position: newPosition);
    final testPath = testPiece.getTransformedPath();
    final testBounds = testPath.getBounds();

    if (preventOverlap) {
      final piecesToCheck = (pieces ?? state.piecesByZone(zone)).where((final p) => p.id != piece.id);
      for (final otherPiece in piecesToCheck) {
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

  List<PuzzlePiece> _updatePieceInList(final PuzzlePiece piece) => List<PuzzlePiece>.from(state.pieces)
      ..removeWhere((final p) => p.id == piece.id)
      ..add(piece);

  List<Map<String, String>> _combineSolutions(
    final Iterable<Map<String, String>> solutions,
    final Iterable<PuzzlePiece> pieces,
  ) {
    if (solutions.isEmpty) {
      return [];
    }
    final gridPlacedPieces = pieces.where((final p) => p.placeZone == PlaceZone.grid && !p.isConfigItem);

    if (gridPlacedPieces.isEmpty) {
      return solutions.toList();
    }

    final origin = state.gridConfig.origin;
    final cellSize = state.gridConfig.cellSize;

    final userCellsById = <String, Set<Cell>>{
      for (final userPiece in gridPlacedPieces) userPiece.id: userPiece.cells(origin, cellSize),
    };

    return solutions.where((final solution) {
      // For each user-placed piece, check that solution has same occupied cells when applied
      for (final entry in userCellsById.entries) {
        final pieceId = entry.key;
        final candidateStr = solution[pieceId];
        if (candidateStr == null) return false;
        final parsed = _parsePlacementParams(MapEntry(pieceId, candidateStr));
        if (parsed == null) return false;
        final basePiece = pieces.firstWhereOrNull((final p) => p.id == pieceId);
        if (basePiece == null) return false;
        final placedPiece = _applyPlacementToPiece(
          basePiece.copyWith(originalPath: generatePathForType(basePiece.type, cellSize)),
          parsed,
        );
        final solutionCells = placedPiece.cells(origin, cellSize);
        if (solutionCells.length != entry.value.length) return false;
        if (!solutionCells.containsAll(entry.value)) return false;
      }
      return true;
    }).toList();
  }

  PuzzlePiece _getHistoryPiece(final int idx, final bool isUndo) {
    final move = state.moveHistory[idx];
    final piece = state.pieces.firstWhere((final p) => p.id == move.pieceId);

    final historyPiece = move.map(
      movePiece: (final mp) {
        final zone = isUndo ? mp.from.zone : mp.to.zone;
        final config = zone == PlaceZone.grid ? state.gridConfig : state.boardConfig;
        return piece.copyWith(
          placeZone: zone,
          position: config.absolutPosition(isUndo ? mp.from.position : mp.to.position),
        );
      },
      rotatePiece: (final rp) => piece.copyWith(
        rotation: (rp.rotation - (isUndo ? rotationStep + fullRotation : 0)) % fullRotation,
        position: rp.getSnapOffset(state.gridConfig.absolutPosition, isUndo),
      ),
      flipPiece: (final fp) => piece.copyWith(
        isFlipped: isUndo ? !fp.isFlipped : fp.isFlipped,
        position: fp.getSnapOffset(state.gridConfig.absolutPosition, isUndo),
      ),
      hintMove: (final hm) {
        final zone = isUndo ? hm.from.zone : hm.to.zone;
        final config = zone == PlaceZone.grid ? state.gridConfig : state.boardConfig;
        return piece.copyWith(
          rotation: isUndo ? hm.rotationFrom : hm.rotationTo,
          isFlipped: isUndo ? hm.flippedFrom : hm.flippedTo,
          placeZone: zone,
          position: config.absolutPosition(isUndo ? hm.from.position : hm.to.position),
        );
      },
    );

    return historyPiece;
  }

  double _stepRotation(final double value) => (value + rotationStep) % fullRotation;

  (PuzzlePiece piece, MovePiece? snapMove) _maybeSnap(final PuzzlePiece selectedPiece) {
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

  Offset _snappedPosition(final PuzzlePiece selectedPiece) {
    var targetPosition = selectedPiece.position;

    final preSnapped = state.gridConfig.snapToGrid(targetPosition);
    final gridBounds = state.gridConfig.getBounds;

    final testPiece = selectedPiece.copyWith(position: preSnapped);
    final pieceBounds = testPiece.getTransformedPath().getBounds();

    var dx = 0.0;
    var dy = 0.0;
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
