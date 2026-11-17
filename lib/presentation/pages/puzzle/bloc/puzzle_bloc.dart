import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:caesar_puzzle/application/contracts/session_recorder.dart';
import 'package:caesar_puzzle/application/contracts/settings_query.dart';
import 'package:caesar_puzzle/application/models/puzzle_history_input.dart';
import 'package:caesar_puzzle/application/models/puzzle_piece_snapshot.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_data.dart';
import 'package:caesar_puzzle/application/models/puzzle_session_status.dart';
import 'package:caesar_puzzle/application/solve_puzzle_use_case.dart';
import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/core/models/move.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/core/models/placement.dart';
import 'package:caesar_puzzle/core/models/position.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_board_entity.dart';
import 'package:caesar_puzzle/domain/entities/puzzle_grid_entity.dart';
import 'package:caesar_puzzle/presentation/layout/screen_spec.dart';
import 'package:caesar_puzzle/presentation/models/drawn_group.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_config_classifier.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/layouts/layout_edit.dart';
import 'package:caesar_puzzle/presentation/services/drawn_group_service.dart';
import 'package:caesar_puzzle/presentation/services/layout_service.dart';
import 'package:caesar_puzzle/presentation/services/lifecycle_service.dart';
import 'package:caesar_puzzle/presentation/services/move_history_service.dart';
import 'package:caesar_puzzle/presentation/services/piece_shape_matcher.dart';
import 'package:caesar_puzzle/presentation/services/puzzle_piece_movement_service.dart';
import 'package:caesar_puzzle/presentation/utils/board_layout_cells.dart';
import 'package:caesar_puzzle/presentation/utils/calendar_cells.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_entity_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_grid_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_extension.dart';
import 'package:caesar_puzzle/presentation/utils/puzzle_piece_utils.dart';
import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart' show kDoubleTapSlop, kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'puzzle_bloc.freezed.dart';
part 'puzzle_event.dart';
part 'puzzle_history_input_extension.dart';
part 'puzzle_state.dart';
part 'puzzle_state_placements.dart';
part 'puzzle_bloc_layout.dart';
part 'puzzle_bloc_drag.dart';
part 'puzzle_bloc_pieces_actions.dart';
part 'puzzle_bloc_solutions.dart';
part 'puzzle_bloc_session.dart';

enum PuzzleMode { daily, race }

class PuzzleBloc extends Bloc<PuzzleEvent, PuzzleState> {
  PuzzleBloc({
    required final SettingsQuery settings,
    required final SolvePuzzleUseCase solvePuzzleUseCase,
    required final SessionRecorder sessionRecorder,
    this.mode = PuzzleMode.daily,
  }) : _settings = settings,
       _solvePuzzleUseCase = solvePuzzleUseCase,
       _sessionRecorder = sessionRecorder,
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
    on<_OnDoubleTapDown>((final event, final emit) => _handleDoubleTap(event, emit));
    on<_ClearDrawnGroup>((final event, final emit) => _clearDrawnGroup(event, emit));
    on<_SelectPiece>((final event, final emit) => _selectPiece(event, emit));
    on<_DeselectPiece>((final event, final emit) => emit(state.copyWith(selectedPieceId: null)));
    on<_RotateSelected>((final event, final emit) => _rotateSelected(event, emit));
    on<_FlipSelected>((final event, final emit) => _flipSelected(event, emit));
    on<_Solve>((final event, final emit) => _solve(event, emit));
    on<_SetSolvingResults>((final event, final emit) => _setSolvingResults(event, emit));
    _onIn<_ShowSolution>(PuzzleMode.daily, _showSolution);
    _onIn<_ShowHint>(PuzzleMode.daily, _showHint);
    on<_Undo>((final event, final emit) => _undoMove(event, emit));
    on<_Redo>((final event, final emit) => _redoMove(event, emit));
    on<_SetTimer>((final event, final emit) => _timerStateChanged(event, emit));
    _onIn<_RestoreSession>(PuzzleMode.daily, _restoreSession);
    _onIn<_SetPuzzleDate>(PuzzleMode.daily, _setPuzzleDate);
    on<_MarkSolvedDialogShown>((final event, final emit) => _markSolvedDialogShown(event, emit));
    _onIn<_ApplyLayout>(PuzzleMode.daily, _applyLayout);
    _onIn<_StartLayoutEdit>(PuzzleMode.daily, _startLayoutEdit);
    _onIn<_ResetLayoutEdit>(PuzzleMode.daily, _resetLayoutEdit);
    _onIn<_CancelLayoutEdit>(PuzzleMode.daily, _cancelLayoutEdit);
    _onIn<_StartRace>(PuzzleMode.race, _startRace);
  }

  static const int gridRows = 7;
  static const int minCommittableDrawnCells = 5;
  static const int gridColumns = 7;
  static const double defaultPadding = 16.0;
  static const double wideScreenPadding = 24.0;
  static const double rotationStep = math.pi / 2;
  static const double fullRotation = math.pi * 2;

  final PuzzleMode mode;
  final SettingsQuery _settings;
  final SolvePuzzleUseCase _solvePuzzleUseCase;
  final SessionRecorder _sessionRecorder;
  final LayoutService _layoutService = const LayoutService();
  final MoveHistoryService _moveHistoryService = const MoveHistoryService();
  final PuzzlePieceMovementService _movementHandler = const PuzzlePieceMovementService();
  final DrawnGroupService _drawnGroupService = const DrawnGroupService();
  final PieceShapeMatcher _pieceShapeMatcher = const PieceShapeMatcher();

  late final LifecycleService _lifecycleService;

  Size? _lastViewSize;
  double _lastMaxCell = double.infinity;
  double _lastTrayScale = PuzzlePieceUI.defaultTrayScale;
  EdgeInsets _lastContentInsets = EdgeInsets.zero;
  double _lastTrayTopInset = 0;
  double _lastTrayStartInset = 0;
  // Piece that the current tap down selected; such a tap must not rotate or flip it.
  String? _selectedOnTapDownId;
  // Where the dragged piece last fitted on the grid; a drop over a blocked spot lands there.
  Offset? _lastFreeGridPosition;
  PuzzleSessionDifficulty? _currentSessionDifficulty;
  int? _suppressTapAfterDrawnCommitAtMs;
  // A late tap of the flipping double tap must not select the piece the flip uncovered.
  ({int atMs, Offset position})? _lastDoubleTapFlip;
  // Only the latest solver run may deliver results.
  int _solveRun = 0;
  bool _isTimerSuspended = false;

  void _onIn<E extends PuzzleEvent>(final PuzzleMode only, final EventHandler<E, PuzzleState> handler) =>
      on<E>((final event, final emit) => mode == only ? handler(event, emit) : null);

  @override
  Future<void> close() {
    _lifecycleService.dispose();
    return super.close();
  }

  /// Stops the game clock until [resumeTimer], whatever the app lifecycle does meanwhile.
  void suspendTimer() {
    _isTimerSuspended = true;
    add(const PuzzleEvent.setTimer(running: false));
  }

  void resumeTimer() {
    _isTimerSuspended = false;
    add(const PuzzleEvent.setTimer(running: true));
  }

  void markCurrentSessionDifficulty(final PuzzleSessionDifficulty difficulty) {
    if (state.firstMoveAt == null) {
      _currentSessionDifficulty = difficulty;
      _sessionRecorder.resetSession();
      _sessionRecorder.setCurrentSessionDifficulty(difficulty);
      return;
    }
    final current = _currentSessionDifficulty;
    _currentSessionDifficulty = current == null || difficulty.assistRank > current.assistRank ? difficulty : current;
    _sessionRecorder.markCurrentSessionDifficulty(difficulty);
  }

  PuzzleSessionDifficulty get currentSessionDifficulty => _currentSessionDifficulty ?? _difficultyFromSettings();

  void markAssisted() => unawaited(
    _sessionRecorder.markPuzzleAssisted(puzzleDate: state.selectedDate, configPlacements: state.configPlacements),
  );

  Future<bool> countsForRecords() async {
    if (mode == PuzzleMode.race) {
      return false;
    }
    final today = DateTime.now();
    final date = state.selectedDate;
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
    if (!isToday || state.isCustomConfig || currentSessionDifficulty == PuzzleSessionDifficulty.easy) {
      return false;
    }
    return !await _sessionRecorder.isPuzzleAssisted(puzzleDate: date, configPlacements: state.configPlacements);
  }

  Future<int> countSolutionsFor(final List<PlacementParams> placements, final DateTime date) async {
    final pieces = _withLayout(placements).map((final p) => p.toDomain(state.gridConfig));
    final solutions = await _solvePuzzleUseCase(pieces: pieces, grid: state.gridConfig, date: date);
    return solutions.length;
  }
}
