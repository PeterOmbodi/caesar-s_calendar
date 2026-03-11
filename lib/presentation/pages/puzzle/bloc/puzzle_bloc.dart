import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:caesar_puzzle/application/contracts/settings_query.dart';
import 'package:caesar_puzzle/application/models/puzzle_history_input.dart';
import 'package:caesar_puzzle/application/models/puzzle_piece_snapshot.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_status.dart';
import 'package:caesar_puzzle/application/puzzle_history_use_case.dart';
import 'package:caesar_puzzle/application/solve_puzzle_use_case.dart';
import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/core/models/move.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/core/models/placement.dart';
import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_board_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_config_classifier.dart';
import 'package:caesar_puzzle/presentation/services/layout_service.dart';
import 'package:caesar_puzzle/presentation/services/lifecycle_service.dart';
import 'package:caesar_puzzle/presentation/services/move_history_service.dart';
import 'package:caesar_puzzle/presentation/services/puzzle_piece_movement_service.dart';
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
part 'puzzle_bloc_layout.dart';
part 'puzzle_bloc_drag.dart';
part 'puzzle_bloc_pieces_actions.dart';
part 'puzzle_bloc_solutions.dart';
part 'puzzle_bloc_session.dart';

class PuzzleBloc extends Bloc<PuzzleEvent, PuzzleState> {
  PuzzleBloc({
    required final SettingsQuery settings,
    required final SolvePuzzleUseCase solvePuzzleUseCase,
    required final PuzzleHistoryUseCase historyUseCase,
  }) : _settings = settings,
       _solvePuzzleUseCase = solvePuzzleUseCase,
       _historyUseCase = historyUseCase,
       super(PuzzleState.initial()) {
    _lifecycleService = LifecycleService(_onLifecycleChanged);

    on<_SetViewSize>((final event, final emit) => _onViewSize(event, emit));
    on<_Reset>((final event, final emit) => _reset(event, emit));
    on<_Configure>((final event, final emit) => _configure(event, emit));
    on<_OnTapDown>((final event, final emit) => _onTapDown(event, emit));
    on<_OnTapUp>((final event, final emit) => _onTapUp(event, emit));
    on<_OnPanStart>((final event, final emit) => _onPanStart(event, emit));
    on<_OnPanUpdate>((final event, final emit) => _onPanUpdate(event, emit));
    on<_OnPanEnd>((final event, final emit) => _onPanEnd(event, emit));
    on<_OnDoubleTapDown>((final event, final emit) => _flipPiece(event, emit));
    on<_RotatePiece>((final event, final emit) => _rotatePiece(event, emit));
    on<_Solve>((final event, final emit) => _solve(event, emit));
    on<_SetSolvingResults>(
      (final event, final emit) => _setSolvingResults(event, emit),
    );
    on<_ShowSolution>((final event, final emit) => _showSolution(event, emit));
    on<_ShowHint>((final event, final emit) => _showHint(event, emit));
    on<_Undo>((final event, final emit) => _undoMove(event, emit));
    on<_Redo>((final event, final emit) => _redoMove(event, emit));
    on<_SetTimer>((final event, final emit) => _timerStateChanged(event, emit));
    on<_RestoreSession>(
      (final event, final emit) => _restoreSession(event, emit),
    );
    on<_SetPuzzleDate>(
      (final event, final emit) => _setPuzzleDate(event, emit),
    );
    on<_MarkSolvedDialogShown>(
      (final event, final emit) => _markSolvedDialogShown(event, emit),
    );
  }

  static const double maxCellSize = 50;
  static const int gridRows = 7;
  static const int gridColumns = 7;
  static const double defaultPadding = 16.0;
  static const double wideScreenPadding = 24.0;
  static const double boardExtraX = 1.5;
  static const double rotationStep = math.pi / 2;
  static const double fullRotation = math.pi * 2;

  final SettingsQuery _settings;
  final SolvePuzzleUseCase _solvePuzzleUseCase;
  final PuzzleHistoryUseCase _historyUseCase;
  final LayoutService _layoutService = const LayoutService();
  final MoveHistoryService _moveHistoryService = const MoveHistoryService();
  final PuzzlePieceMovementService _movementHandler =
      const PuzzlePieceMovementService();

  late final LifecycleService _lifecycleService;

  Size? _lastViewSize;
  PuzzleSessionDifficulty? _currentSessionDifficulty;

  @override
  Future<void> close() {
    _lifecycleService.dispose();
    return super.close();
  }

  void markCurrentSessionEasy() {
    _currentSessionDifficulty = PuzzleSessionDifficulty.easy;
    _historyUseCase.markCurrentSessionEasy();
  }

  PuzzleSessionDifficulty get currentSessionDifficulty =>
      _currentSessionDifficulty ?? _difficultyFromSettings();
}
