import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:caesar_puzzle/application/solve_puzzle_use_case.dart';
import 'package:caesar_puzzle/core/models/placement.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_board.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid.dart' show PuzzleGrid;
import 'package:caesar_puzzle/domain/entities/puzzle_piece.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'puzzle_bloc.freezed.dart';
part 'puzzle_event.dart';
part 'puzzle_state.dart';

class PuzzleBloc extends Bloc<PuzzleEvent, PuzzleState> {
  static const double collisionTolerance = 2;

  PuzzleBloc(final Size screenSize) : super(PuzzleState.initial(screenSize)) {
    on<_Reset>((event, emit) => emit(PuzzleState.initial(screenSize)));
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
  }

  PuzzlePiece? _findPieceAtPosition(Offset position) => state.pieces.values.expand((e) => e).firstWhereOrNull(
        (piece) => piece.containsPoint(position),
      );

  PieceZone? _getZoneAtPosition(Offset position) {
    if (state.gridConfig.getBounds().contains(position)) {
      return PieceZone.grid;
    } else if (state.boardConfig.getBounds().contains(position)) {
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
    final testPiece = piece.copyWith(newPosition: newPosition);
    final testPath = testPiece.getTransformedPath();
    final testBounds = testPath.getBounds();

    final piecesToCheck = state.pieces[zone]!.where((p) => p.id != piece.id);
    debugPrint(
        'zone: $zone, newPosition: $newPosition, piecesToCheck: ${piecesToCheck.map((i) => i.id).join('|')}, all: ${state.pieces[zone]!.length}');
    for (var otherPiece in piecesToCheck) {
      final otherPath = otherPiece.getTransformedPath();
      final otherBounds = otherPath.getBounds();

      if (!testBounds.overlaps(otherBounds)) {
        continue;
      }

      try {
        // Add some tolerance to avoid false positives
        // For grid-based placements, we want to allow pieces to be adjacent
        final combinedPath = Path.combine(PathOperation.intersect, testPath, otherPath);
        final intersectionBounds = combinedPath.getBounds();

        // If the intersection area is significant, it's a collision
        if (!intersectionBounds.isEmpty &&
            intersectionBounds.width > 2 &&
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
        final gridRect = state.gridConfig.getBounds();
        // For grid, ensure the piece is mostly inside the grid
        // This is less strict than requiring all corners to be inside
        final centerX = testBounds.left + testBounds.width / 2;
        final centerY = testBounds.top + testBounds.height / 2;
        final pieceCenter = Offset(centerX, centerY);
        if (!gridRect.contains(pieceCenter)) {
          debugPrint('Piece center outside grid');
          return true;
        }
        // Allow some tolerance for pieces at edges
        final expandedGrid =
            Rect.fromLTRB(gridRect.left - 5, gridRect.top - 5, gridRect.right + 5, gridRect.bottom + 5);
        if (testBounds.left < expandedGrid.left ||
            testBounds.right > expandedGrid.right ||
            testBounds.top < expandedGrid.top ||
            testBounds.bottom > expandedGrid.bottom) {
          debugPrint('Piece partially outside grid');
          return true;
        }
      case PieceZone.board:
        final boardRect = state.boardConfig.getBounds();
        // For board, just make sure the piece overlaps with the board area
        if (!boardRect.overlaps(testBounds)) {
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
      newIsFlipped: params.isFlipped,
      newPosition: targetOffset,
      newRotation: params.rotationSteps * math.pi / 2,
    );
    return updatedPiece;
  }

  FutureOr<void> _onTapDown(_OnTapDown event, Emitter<PuzzleState> emit) {
    final piece = _findPieceAtPosition(event.localPosition);
    if (piece != null) {
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
          newRotation: (event.piece.rotation + math.pi / 2) % (math.pi * 2),
        ),
      ),
    ));
  }

  FutureOr<void> _onPanStart(_OnPanStart event, Emitter<PuzzleState> emit) {
    final piece = _findPieceAtPosition(event.localPosition);
    if (piece != null && piece.isDraggable) {
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
      emit(state.copyWith(
        pieces: pieces,
        selectedPiece: piece,
        dragStartOffset: event.localPosition - piece.position,
        pieceStartPosition: piece.position,
        dropZone: _getZoneAtPosition(piece.position),
        isDragging: true,
      ));
    }
  }

  FutureOr<void> _onPanUpdate(_OnPanUpdate event, Emitter<PuzzleState> emit) {
    if (state.selectedPiece != null && state.dragStartOffset != null) {
      final newPosition = event.localPosition - state.dragStartOffset!;
      final piece = state.selectedPiece!.copyWith(newPosition: newPosition);
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
      debugPrint('snappedPosition, newZone: $newZone');
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
          final boardBounds = state.boardConfig.getBounds();
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
      debugPrint('snappedPosition, snappedPosition: $snappedPosition, collisionDetected: $collisionDetected');
      final pieces = state.pieces.map(
        (zone, list) => MapEntry(
          zone,
          List<PuzzlePiece>.from(list),
        ),
      );
      if (!collisionDetected) {
        final selectedPiece = state.selectedPiece!.copyWith(
          newPosition: snappedPosition,
        );
        final boardPieces = pieces[PieceZone.board]!;
        final gridPieces = pieces[PieceZone.grid]!;
        debugPrint('snappedPosition, newZone: $newZone, state.dropZone: ${state.dropZone}');
        if (newZone != null && newZone != state.dropZone) {
          if (newZone == PieceZone.grid) {
            boardPieces.removeWhere((p) => p.id == selectedPiece.id);
            gridPieces.add(selectedPiece);
          } else if (newZone == PieceZone.board) {
            gridPieces.removeWhere((p) => p.id == selectedPiece.id);
            boardPieces.add(selectedPiece);
          }
          debugPrint('snappedPosition, boardPieces: ${boardPieces.length}, gridPieces: ${gridPieces.length}');
        }

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
      } else {
        debugPrint(
            'Collision detected, returning to original position, pieceStartPosition: ${state.pieceStartPosition}');
        final selectedPiece = state.selectedPiece!.copyWith(
          newPosition: state.pieceStartPosition,
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
    if (piece != null) {
      final flippedPiece = piece.copyWith(newIsFlipped: !piece.isFlipped);
      debugPrint('Flipping piece ${piece.id}: ${piece.isFlipped} -> ${flippedPiece.isFlipped}');
      emit(
        state.copyWith(
          pieces: _updatePieceInLists(state.pieces, piece, flippedPiece),
        ),
      );
    }
  }

  Future<void> _solve(_Solve event, Emitter<PuzzleState> emit) async {
    emit(state.copyWith(isSolving: true));
    await Future.delayed(Duration(milliseconds: 200));
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
    emit(state.copyWith(isSolving: false, solutions: event.solutions));
    for (final solution in event.solutions){
      debugPrint('sol: $solution');
    }
    if (event.solutions.isNotEmpty) {
      add(PuzzleEvent.showSolution(0));
    }
  }

  PlacementParams? _parsePlacementId(String solution) {
    final match = RegExp(r'^(.+)_r(\d+)_c(\d+)_rot(\d+)(_F)?$').firstMatch(solution);
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
    final gridPieces = <PuzzlePiece>[];
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
}
