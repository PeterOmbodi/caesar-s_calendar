import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:caesar_puzzle/application/solve_puzzle_use_case.dart';
import 'package:caesar_puzzle/core/models/placement.dart';
import 'package:caesar_puzzle/core/utils/puzzle_board_extension.dart';
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

  Size? _lastViewSize;

  PuzzleBloc() : super(PuzzleState.initial()) {
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
    on<_ChangeForbiddenCellsMode>(
      (_, emit) => emit(
        state.copyWith(
          isUnlockedForbiddenCells: !state.isUnlockedForbiddenCells,
        ),
      ),
    );
    on<_Configure>(_configure);
  }

  PuzzlePiece? _findPieceAtPosition(Offset position) => state.pieces.values.expand((e) => e).firstWhereOrNull(
        (piece) => piece.containsPoint(position),
      );

  PieceZone? _getZoneAtPosition(Offset position) {
    if (state.gridConfig.getBounds.contains(position)) {
      return PieceZone.grid;
    } else if (state.boardConfig.getBounds.contains(position)) {
      return PieceZone.board;
    }
    return null;
  }

  /// Checks for collision of piece at newPosition.
  bool _checkCollision({
    required PuzzlePiece piece,
    required Offset newPosition,
    required PieceZone zone,
  }) {
    final testPiece = piece.copyWith(position: newPosition);
    final testPath = testPiece.getTransformedPath();
    final testBounds = testPath.getBounds();

    final piecesToCheck = state.pieces[zone]!.where((p) => p.id != piece.id);

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
          debugPrint(
              'Collision detected between ${piece.id} and ${otherPiece.id}, intersectionBounds: ${intersectionBounds.size}');
          return true;
        }
      } catch (e) {
        debugPrint('Checking collision exception: $e');
        return true;
      }
    }

    switch (zone) {
      case PieceZone.grid:
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
        final expandedGrid = Rect.fromLTRB(gridRect.left - gridEdgeTolerance, gridRect.top - gridEdgeTolerance,
            gridRect.right + gridEdgeTolerance, gridRect.bottom + gridEdgeTolerance);
        if (testBounds.left < expandedGrid.left ||
            testBounds.right > expandedGrid.right ||
            testBounds.top < expandedGrid.top ||
            testBounds.bottom > expandedGrid.bottom) {
          debugPrint('Piece partially outside grid');
          return true;
        }
      case PieceZone.board:
        if (!state.boardConfig.getBounds.overlaps(testBounds)) {
          debugPrint('Piece not overlapping with board');
          return true;
        }
    }

    return false;
  }

  Map<PieceZone, List<PuzzlePiece>> _updatePieceInLists(
    Map<PieceZone, List<PuzzlePiece>> pieces,
    PuzzlePiece oldPiece,
    PuzzlePiece newPiece,
  ) {
    return pieces.map(
      (zone, list) => MapEntry(
        zone,
        list.map((piece) => piece.id == oldPiece.id ? newPiece : piece).toList()
          ..sort((a, b) {
            if (a.id == newPiece.id) return 1;
            if (b.id == newPiece.id) return -1;
            return 0;
          }),
      ),
    );
  }

  PuzzlePiece _placePiece(PuzzlePiece piece, PlacementParams params) {
    final cellSize = state.gridConfig.cellSize;
    final origin = state.gridConfig.origin;
    final dx = params.col * cellSize;
    final dy = params.row * cellSize;
    final targetOffset = Offset(origin.dx + dx, origin.dy + dy);

    final updatedPiece = piece.copyWith(
      isFlipped: params.isFlipped,
      position: targetOffset,
      rotation: params.rotationSteps * rotationStep,
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
      add(PuzzleEvent.configure(
          viewSize: _lastViewSize!,
          prevState: PuzzleState.initial(),
          forbiddenPieces:
              state.isUnlockedForbiddenCells ? [] : state.pieces[PieceZone.grid]!.where((e) => e.isForbidden)));
    }
  }

  FutureOr<void> _onTapDown(_OnTapDown event, Emitter<PuzzleState> emit) {
    final piece = _findPieceAtPosition(event.localPosition);
    if (piece != null && (!piece.isForbidden || state.isUnlockedForbiddenCells)) {
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
    emit(state.copyWith(
      pieces: _updatePieceInLists(
        state.pieces,
        event.piece,
        event.piece.copyWith(
          rotation: (event.piece.rotation + rotationStep) % fullRotation,
        ),
      ),
    ));
  }

  FutureOr<void> _onPanStart(_OnPanStart event, Emitter<PuzzleState> emit) {
    final piece = _findPieceAtPosition(event.localPosition);
    if (piece != null && (!piece.isForbidden || state.isUnlockedForbiddenCells)) {
      final pieces = Map<PieceZone, List<PuzzlePiece>>.from(state.pieces);
      final boardPieces = state.pieces[PieceZone.board];
      final boardIndex = boardPieces?.indexWhere((item) => item.id == piece.id) ?? -1;
      if (boardIndex >= 0) {
        final piecesCopy = List<PuzzlePiece>.from(boardPieces!);
        piecesCopy.remove(piece);
        piecesCopy.add(piece);
        pieces[PieceZone.board] = piecesCopy;
      } else {
        final gridPieces = state.pieces[PieceZone.grid];
        final gridIndex = gridPieces?.indexWhere((item) => item.id == piece.id) ?? -1;
        if (gridIndex >= 0) {
          final piecesCopy = List<PuzzlePiece>.from(gridPieces!);
          piecesCopy.remove(piece);
          piecesCopy.add(piece);
          pieces[PieceZone.grid] = piecesCopy;
        }
      }
      emit(
        state.copyWith(
          pieces: pieces,
          selectedPiece: piece,
          dragStartOffset: event.localPosition - piece.position,
          pieceStartPosition: piece.position,
          dropZone: _getZoneAtPosition(piece.position),
          isDragging: true,
        ),
      );
    }
  }

  FutureOr<void> _onPanUpdate(_OnPanUpdate event, Emitter<PuzzleState> emit) {
    if (state.selectedPiece != null && state.dragStartOffset != null) {
      final newPosition = event.localPosition - state.dragStartOffset!;
      final piece = state.selectedPiece!.copyWith(position: newPosition);
      final pieces = Map<PieceZone, List<PuzzlePiece>>.from(state.pieces);
      final boardPieces = state.pieces[PieceZone.board];
      final boardIndex = boardPieces?.indexWhere((item) => item.id == piece.id) ?? -1;

      if (boardIndex >= 0) {
        final piecesCopy = List<PuzzlePiece>.from(boardPieces!);
        piecesCopy[boardIndex] = piece;
        pieces[PieceZone.board] = piecesCopy;
      } else {
        final gridPieces = state.pieces[PieceZone.grid];
        final gridIndex = gridPieces?.indexWhere((item) => item.id == piece.id) ?? -1;
        if (gridIndex >= 0) {
          final piecesCopy = List<PuzzlePiece>.from(gridPieces!);
          piecesCopy[gridIndex] = piece;
          pieces[PieceZone.grid] = piecesCopy;
        }
      }
      final currentZone = _getZoneAtPosition(newPosition);
      switch (currentZone) {
        case PieceZone.grid:
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
        case PieceZone.board:
        case null:
          emit(
            state.copyWith(
              pieces: pieces,
              selectedPiece: piece,
              showPreview: false,
              previewCollision: false,
            ),
          );
      }
    }
  }

  FutureOr<void> _onPanEnd(_OnPanEnd event, Emitter<PuzzleState> emit) {
    if (state.selectedPiece != null) {
      final newZone = _getZoneAtPosition(state.selectedPiece!.position);
      Offset snappedPosition;
      bool collisionDetected = false;
      switch (newZone) {
        case PieceZone.grid:
          snappedPosition = state.gridConfig.snapToGrid(state.selectedPiece!.position);
          collisionDetected = _checkCollision(
            piece: state.selectedPiece!,
            newPosition: snappedPosition,
            zone: newZone!,
          );
        case PieceZone.board:
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
            snappedPosition =
                Offset(snappedPosition.dx, snappedPosition.dy - (pieceBounds.bottom - boardBounds.bottom));
          }

          collisionDetected = false;
        default:
          snappedPosition = state.pieceStartPosition!;
          collisionDetected = true;
          debugPrint('not over either zone, return to starting position');
      }
      final pieces = state.pieces.map(
        (zone, list) => MapEntry(
          zone,
          List<PuzzlePiece>.from(list),
        ),
      );
      if (!collisionDetected) {
        final selectedPiece = state.selectedPiece!.copyWith(
          position: snappedPosition,
        );
        final boardPieces = pieces[PieceZone.board]!;
        final gridPieces = pieces[PieceZone.grid]!;
        if (newZone != null && newZone != state.dropZone) {
          if (newZone == PieceZone.grid) {
            boardPieces.removeWhere((p) => p.id == selectedPiece.id);
            gridPieces.add(selectedPiece);
          } else if (newZone == PieceZone.board) {
            gridPieces.removeWhere((p) => p.id == selectedPiece.id);
            boardPieces.add(selectedPiece);
          }
        }

        emit(
          state.copyWith(
            pieces: _updatePieceInLists(pieces, state.selectedPiece!, selectedPiece),
            showPreview: false,
            previewPosition: null,
            selectedPiece: null,
            dragStartOffset: null,
            pieceStartPosition: null,
            dropZone: null,
            isDragging: false,
          ),
        );
      } else {
        debugPrint(
            'Collision detected, returning to original position, pieceStartPosition: ${state.pieceStartPosition}');
        final selectedPiece = state.selectedPiece!.copyWith(
          position: state.pieceStartPosition,
        );
        emit(state.copyWith(
          pieces: _updatePieceInLists(pieces, state.selectedPiece!, selectedPiece),
          showPreview: false,
          previewPosition: null,
          selectedPiece: null,
          dragStartOffset: null,
          pieceStartPosition: null,
          dropZone: null,
          isDragging: false,
        ));
      }
    }
  }

  FutureOr<void> _onDoubleTapDown(_OnDoubleTapDown event, Emitter<PuzzleState> emit) {
    final piece = _findPieceAtPosition(event.localPosition);
    if (piece != null && (!piece.isForbidden || state.isUnlockedForbiddenCells)) {
      final flippedPiece = piece.copyWith(isFlipped: !piece.isFlipped);
      emit(
        state.copyWith(
          pieces: _updatePieceInLists(state.pieces, piece, flippedPiece),
        ),
      );
    }
  }

  Future<void> _solve(_Solve event, Emitter<PuzzleState> emit) async {
    emit(state.copyWith(
      status: GameStatus.solving,
      solutions: [],
      solutionIdx: -1,
    ));
    await Future.delayed(solvingDelay);
    final pieces = [
      ...state.pieces[PieceZone.grid]!,
      ...state.pieces[PieceZone.board]!,
    ];
    SolvePuzzleUseCase().call(pieces: pieces, grid: state.gridConfig).then((solutions) {
      debugPrint('solving finished, found solutions: ${solutions.length}');
      add(PuzzleEvent.setSolvingResults(solutions));
    });
  }

  FutureOr<void> _setSolvingResults(_SetSolvingResults event, Emitter<PuzzleState> emit) {
    emit(state.copyWith(status: GameStatus.solved, solutions: event.solutions));
    for (final solution in event.solutions) {
      debugPrint('sol: $solution');
    }
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

  FutureOr<void> _showSolution(_ShowSolution event, Emitter<PuzzleState> emit) {
    final pieces = [
      ...state.pieces[PieceZone.grid]!,
      ...state.pieces[PieceZone.board]!,
    ];
    final solutionIds = state.solutions[event.index];
    final gridPieces = state.pieces[PieceZone.grid]!
        .where((e) => e.isForbidden)
        .map((p) => p.copyWith(originalPath: generatePathForType(p.type, state.gridConfig.cellSize)))
        .toList();
    for (var solution in solutionIds) {
      final params = _parsePlacementId(solution);
      if (params == null) continue;
      final idx = pieces.indexWhere((p) => p.id == params.pieceId);
      gridPieces.add(_placePiece(pieces[idx], params));
    }
    final solvedPieces = <PieceZone, List<PuzzlePiece>>{
      PieceZone.board: [],
      PieceZone.grid: gridPieces,
    };
    emit(state.copyWith(pieces: solvedPieces, solutionIdx: event.index));
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
            PieceType.yShape, Offset(boardX + boardExtraX * 2, boardY + gCellSize * 2), centerPoint, gCellSize),
        PuzzlePiece.fromType(PieceType.uShape, Offset(boardX + cellXOffset + boardExtraX, boardY + gCellSize * 3),
            centerPoint, gCellSize),
        PuzzlePiece.fromType(PieceType.pShape, Offset(boardX, boardY), centerPoint, gCellSize),
        PuzzlePiece.fromType(PieceType.nShape, Offset(boardX + 2 * cellXOffset, boardY), centerPoint, gCellSize),
        PuzzlePiece.fromType(
            PieceType.vShape, Offset(boardX + cellXOffset * 4, boardY + gCellSize * 3), centerPoint, gCellSize),
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

      gridPieces = prevState.pieces[PieceZone.grid]!
          .map(
            (p) => p.copyWith(
              originalPath: generatePathForType(p.type, gCellSize),
              position: gridConfig.snapToGrid(
                Offset(
                  p.position.dx * gridCellMod + gridDeltaX,
                  p.position.dy * gridCellMod + gridDeltaY,
                ),
              ),
              centerPoint: centerPoint,
            ),
          )
          .toList();

      final prevBoardX = prevState.boardConfig.initialX(prevState.gridConfig.cellSize);
      final prevBoardY = prevState.boardConfig.initialY(prevState.gridConfig.cellSize);
      final boardDeltaX = boardX - prevBoardX * gridCellMod;
      final boardDeltaY = boardY - prevBoardY * gridCellMod;

      boardPieces = prevState.pieces[PieceZone.board]!
          .map(
            (p) => p.copyWith(
              originalPath: generatePathForType(p.type, gCellSize),
              position: Offset(
                p.position.dx * gridCellMod + boardDeltaX,
                p.position.dy * gridCellMod + boardDeltaY,
              ),
              centerPoint: centerPoint,
            ),
          )
          .toList();
    }
    emit(PuzzleState(
      status: GameStatus.waiting,
      gridConfig: gridConfig,
      boardConfig: boardConfig,
      pieces: {
        PieceZone.grid: gridPieces,
        PieceZone.board: boardPieces,
      },
      solutions: prevState.solutions,
      solutionIdx: prevState.solutionIdx,
      timer: prevState.timer,
      selectedPiece: null,
      isDragging: false,
      showPreview: false,
      previewCollision: false,
      isUnlockedForbiddenCells: false,
    ));
    _lastViewSize = event.viewSize;
  }
}
