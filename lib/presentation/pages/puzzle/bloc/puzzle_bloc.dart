import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:caesar_puzzle/application/contracts/settings_query.dart';
import 'package:caesar_puzzle/application/models/puzzle_history_input.dart';
import 'package:caesar_puzzle/application/models/puzzle_piece_snapshot.dart';
import 'package:caesar_puzzle/application/puzzle_history_use_case.dart';
import 'package:caesar_puzzle/application/solve_puzzle_use_case.dart';
import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/core/models/move.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/core/models/placement.dart';
import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_board_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/domain/services/placement_validator.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/services/layout_service.dart';
import 'package:caesar_puzzle/presentation/services/lifecycle_service.dart';
import 'package:caesar_puzzle/presentation/services/move_history_service.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_entity_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_grid_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_utils.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'puzzle_bloc.freezed.dart';
part 'puzzle_event.dart';
part 'puzzle_history_input_extension.dart';
part 'puzzle_state.dart';

class PuzzleBloc extends Bloc<PuzzleEvent, PuzzleState> {
  PuzzleBloc({
    required final SettingsQuery settings,
    required final SolvePuzzleUseCase solvePuzzleUseCase,
    required final PuzzleHistoryUseCase historyUseCase,
  })
      : _settings = settings,
      _solvePuzzleUseCase = solvePuzzleUseCase,
        _historyUseCase = historyUseCase,
      super(PuzzleState.initial()) {
    _lifecycleService = LifecycleService(_onLifecycleChanged);

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
    on<_SetTimer>(_timerStateChanged);
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
  final SolvePuzzleUseCase _solvePuzzleUseCase;
  final PuzzleHistoryUseCase _historyUseCase;
  final PlacementValidator _placementValidator = const PlacementValidator();
  final LayoutService _layoutService = const LayoutService();
  final MoveHistoryService _moveHistoryService = const MoveHistoryService();

  late final LifecycleService _lifecycleService;

  Size? _lastViewSize;

  @override
  Future<void> close() {
    _lifecycleService.dispose();
    return super.close();
  }

  /* handle events */

  FutureOr<void> _onViewSize(final _SetViewSize event, final Emitter<PuzzleState> emit) {
    if (_lastViewSize != event.viewSize && event.viewSize.width > 0 && event.viewSize.height > 0) {
      _lastViewSize = event.viewSize;
      add(PuzzleEvent.configure());
    }
  }

  FutureOr<void> _reset(final _Reset event, final Emitter<PuzzleState> emit) {
    _historyUseCase.resetSession();
    add(
      PuzzleEvent.configure(
        toInitial: true,
        configurationPieces: _settings.unlockConfig ? [] : state.gridPieces.where((final e) => e.isConfigItem),
      ),
    );
    if (state.solutions.isEmpty && _settings.requireSolutions) {
      add(PuzzleEvent.solve(showResult: false));
    }
  }

  Future<void> _configure(final _Configure event, final Emitter<PuzzleState> emit) async {
    final viewSize = _lastViewSize!;
    final configurationPieces = event.configurationPieces;
    final isInitializing = state.status == GameStatus.initializing || event.toInitial;
    final layout = isInitializing
        ? _layoutService.buildInitialLayout(viewSize, configurationPieces: configurationPieces)
        : _layoutService.rebuildLayout(
            viewSize: viewSize,
            prevGrid: state.gridConfig,
            prevBoard: state.boardConfig,
            pieces: state.pieces,
          );
    final newState = state.copyWith(
      gridConfig: layout.gridConfig,
      boardConfig: layout.boardConfig,
      pieces: layout.pieces.toList(),
    );

    if (isInitializing) {
      emit(
        newState.copyWith(
          status: GameStatus.initialized,
          solutionIdx: -1,
          moveHistory: [],
          moveIndex: 0,
          firstMoveAt: null,
          lastResumedAt: null,
          activeElapsedMs: 0,
        ),
      );
    } else {
      emit(newState);
    }

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
      final pieces = List<PuzzlePieceUI>.from(state.pieces);
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
      final prevState = state;
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
            preventOverlap: _settings.preventOverlap || state.selectedPiece!.isConfigItem,
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
            position: Position(
              dx: fromConfig.relativePosition(state.pieceStartPosition!).dx,
              dy: fromConfig.relativePosition(state.pieceStartPosition!).dy,
            ),
          ),
          to: MovePlacement(
            zone: newZone!,
            position: Position(
              dx: toConfig.relativePosition(snappedPosition).dx,
              dy: toConfig.relativePosition(snappedPosition).dy,
            ),
          ),
        );
        final moveHistory = List<Move>.from(state.moveHistory);
        if (moveHistory.length > state.moveIndex) {
          moveHistory.removeRange(state.moveIndex, moveHistory.length);
        }
        final firstMoveAt = state.gridPieces.where((final p) => !p.isConfigItem).isEmpty
            ? DateTime.now().millisecondsSinceEpoch
            : null;
        moveHistory.add(move);
        final pieces = _updatePieceInList(selectedPiece);
        final shouldResolve = selectedPiece.isConfigItem;
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
          firstMoveAt: firstMoveAt ?? state.firstMoveAt,
        );
        emit(nextState);
        _historyUseCase.persistAfterChange(
          nextState.toHistoryInput(prevState: prevState, rotationStep: rotationStep),
        );
        if (shouldResolve) {
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
      final prevState = state;
      final flippedPiece = selectedPiece.copyWith(isFlipped: !selectedPiece.isFlipped);
      final shouldSnap =
          selectedPiece.placeZone == PlaceZone.grid && (_settings.snapToGridOnTransform || selectedPiece.isConfigItem);
      final (pieceToSave, snapMove) =
          shouldSnap ? _moveHistoryService.maybeSnap(selectedPiece: flippedPiece, grid: state.gridConfig) : (flippedPiece, null);
      final move = FlipPiece(flippedPiece.id, snapMove, isFlipped: flippedPiece.isFlipped);
      final pieces = _updatePieceInList(pieceToSave);
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
      emit(nextState);
      _historyUseCase.persistAfterChange(
        nextState.toHistoryInput(prevState: prevState, rotationStep: rotationStep),
      );
      if (shouldResolve) {
        add(PuzzleEvent.solve(showResult: false));
      }
    }
  }

  FutureOr<void> _rotatePiece(final _RotatePiece event, final Emitter<PuzzleState> emit) {
    final prevState = state;
    final selectedPiece = event.piece.copyWith(rotation: _stepRotation(event.piece.rotation));
    final shouldSnap =
        event.piece.placeZone == PlaceZone.grid && (_settings.snapToGridOnTransform || selectedPiece.isConfigItem);
    final (pieceToSave, snapMove) = shouldSnap
        ? _moveHistoryService.maybeSnap(selectedPiece: selectedPiece, grid: state.gridConfig)
        : (selectedPiece, null);
    final move = RotatePiece(selectedPiece.id, snapMove, rotation: selectedPiece.rotation);
    final pieces = _updatePieceInList(pieceToSave);
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
    emit(nextState);
    _historyUseCase.persistAfterChange(
      nextState.toHistoryInput(prevState: prevState, rotationStep: rotationStep),
    );
    if (shouldResolve) {
      add(PuzzleEvent.solve(showResult: false));
    }
  }

  Future<void> _solve(final _Solve event, final Emitter<PuzzleState> emit) async {
    emit(state.copyWith(status: GameStatus.searchingSolutions, solutions: [], solutionIdx: -1));
    await Future<void>.delayed(Duration.zero);
    unawaited(
      _solvePuzzleUseCase
          .call(pieces: state.pieces.map((final p) => p.toDomain(state.gridConfig)), grid: state.gridConfig)
          .then((final solutions) {
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
        : <String, PlacementParams>{};
    final gridPieces = state.gridPieces
        .where((final e) => e.isConfigItem || e.isUsersItem)
        .map((final p) => p.copyWith(originalPath: generatePathForType(p.type, state.gridConfig.cellSize)))
        .toList();
    for (final solution in solutionIds.entries) {
      final params = solution.value;
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
    final prevState = state;
    final possibleSolutions = state.applicableSolutions.length;
    final solutionIndex = possibleSolutions < 2 ? 0 : math.Random().nextInt(possibleSolutions - 1);
    final encodedSolution = state.applicableSolutions[solutionIndex];
    final onGridIds = state.gridPieces.map((final e) => e.id);
    final encodedPieces = encodedSolution.entries.where((final e) => !onGridIds.contains(e.key)).toList();
    final pececIndex = encodedPieces.length == 1 ? 0 : math.Random().nextInt(encodedPieces.length - 1);
    final params = encodedPieces[pececIndex].value;

    final sourcePiece = state.pieces.firstWhere((final p) => p.id == params.pieceId);
    final targetPiece = _applyPlacementToPiece(sourcePiece, params).copyWith(isUsersItem: false);
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
    );
    emit(nextState);
    _historyUseCase.persistAfterChange(
      nextState.toHistoryInput(prevState: prevState, rotationStep: rotationStep),
    );
  }

  FutureOr<void> _undoMove(final _Undo event, final Emitter<PuzzleState> emit) {
    if (state.moveHistory.isNotEmpty && state.moveIndex > 0) {
      final prevState = state;
      final idx = state.moveIndex - 1;
      final selectedPiece = _moveHistoryService.historyPiece(
        state: state,
        idx: idx,
        isUndo: true,
        rotationStep: rotationStep,
        fullRotation: fullRotation,
      );
      final pieces = _updatePieceInList(selectedPiece);
      final shouldResolve = selectedPiece.isConfigItem && _settings.requireSolutions;
      final applicableSolutions = shouldResolve
          ? state.applicableSolutions
          : _combineSolutions(state.solutions, pieces);
      final nextState = state.copyWith(
        moveIndex: idx,
        pieces: pieces,
        status: GameStatus.playing,
        applicableSolutions: applicableSolutions,
      );
      emit(nextState);
      _historyUseCase.persistAfterChange(
        nextState.toHistoryInput(prevState: prevState, rotationStep: rotationStep),
      );
      if (shouldResolve) {
        add(PuzzleEvent.solve(showResult: false));
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
      rotationStep: rotationStep,
      fullRotation: fullRotation,
    );
    final pieces = _updatePieceInList(selectedPiece);
    final shouldResolve = selectedPiece.isConfigItem && _settings.requireSolutions;
    final applicableSolutions = shouldResolve ? state.applicableSolutions : _combineSolutions(state.solutions, pieces);
    final nextState = state.copyWith(
      moveIndex: idx,
      pieces: pieces,
      status: GameStatus.playing,
      applicableSolutions: applicableSolutions,
    );
    emit(nextState);
    _historyUseCase.persistAfterChange(
      nextState.toHistoryInput(prevState: prevState, rotationStep: rotationStep),
    );
    if (shouldResolve) {
      add(PuzzleEvent.solve(showResult: false));
    }
  }

  FutureOr<void> _timerStateChanged(final _SetTimer event, final Emitter<PuzzleState> emit) {
    if (event.running) {
      if (state.status == GameStatus.paused) {
        final prevState = state;
        final nextState =
        state.copyWith(status: GameStatus.playing, lastResumedAt: DateTime
            .now()
            .millisecondsSinceEpoch);
        emit(nextState);
        _historyUseCase.persistAfterChange(
          nextState.toHistoryInput(prevState: prevState, rotationStep: rotationStep),
        );
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
      _historyUseCase.persistAfterChange(
        nextState.toHistoryInput(prevState: prevState, rotationStep: rotationStep),
      );
    } else if (state.status == GameStatus.playing) {
      final prevState = state;
      final nextState = state.copyWith(status: GameStatus.paused);
      emit(nextState);
      _historyUseCase.persistAfterChange(
        nextState.toHistoryInput(prevState: prevState, rotationStep: rotationStep),
      );
    }
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

  PuzzlePieceUI _applyPlacementToPiece(final PuzzlePieceUI piece, final PlacementParams params) {
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

  PuzzlePieceUI? _findPieceAtPosition(final Offset position) =>
      state.pieces.lastWhereOrNull((final piece) => piece.containsPoint(position));

  PlaceZone? _getZoneAtPosition(final Offset position) {
    if (state.gridConfig.getBounds.contains(position)) {
      return PlaceZone.grid;
    } else if (state.boardConfig.getBounds.contains(position)) {
      return PlaceZone.board;
    }
    return null;
  }

  //todo draft solution
  // need to check to empty date cells
  // need to change status for unique solutions only
  GameStatus _getStatus(final Iterable<PuzzlePieceUI> pieces) {
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
    required final PuzzlePieceUI piece,
    required final Offset newPosition,
    required final PlaceZone zone,
    required final preventOverlap,
    final Iterable<PuzzlePieceUI>? pieces,
  }) {
    switch (zone) {
      case PlaceZone.grid:
        final testPiece = piece.copyWith(position: newPosition);
        final candidate = testPiece.toDomain(state.gridConfig);
        final others = (pieces ?? state.piecesByZone(zone))
            .where((final p) => p.id != piece.id)
            .map(
              (final other) => other.copyWith(originalPath: generatePathForType(other.type, state.gridConfig.cellSize)),
            );
        final otherDomains = others.map((final ui) => ui.toDomain(state.gridConfig));
        return _placementValidator.hasCollision(
          candidate: candidate,
          grid: state.gridConfig,
          others: otherDomains,
          preventOverlap: preventOverlap,
        );
      case PlaceZone.board:
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
        if (!state.boardConfig.getBounds.overlaps(testBounds)) {
          debugPrint('Piece not overlapping with board');
          return true;
        }
    }

    return false;
  }

  List<PuzzlePieceUI> _updatePieceInList(final PuzzlePieceUI piece) => List<PuzzlePieceUI>.from(state.pieces)
    ..removeWhere((final p) => p.id == piece.id)
    ..add(piece);

  List<Map<String, PlacementParams>> _combineSolutions(
    final Iterable<Map<String, PlacementParams>> solutions,
    final Iterable<PuzzlePieceUI> pieces,
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
        final parsed = solution[pieceId];
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

  double _stepRotation(final double value) => (value + rotationStep) % fullRotation;
}
