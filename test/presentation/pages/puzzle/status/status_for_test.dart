import 'package:caesar_puzzle/core/models/cell.dart';
import 'package:caesar_puzzle/core/models/piece_type.dart';
import 'package:caesar_puzzle/core/models/place_zone.dart';
import 'package:caesar_puzzle/core/models/placement.dart';
import 'package:caesar_puzzle/presentation/models/drawn_group.dart';
import 'package:caesar_puzzle/presentation/models/puzzle_piece_ui.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/bloc/puzzle_bloc.dart';
import 'package:caesar_puzzle/presentation/pages/puzzle/status/status_for.dart';
import 'package:caesar_puzzle/presentation/pages/settings/bloc/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _easy = SolutionIndicator.countSolutions;
const _medium = SolutionIndicator.solvability;
const _hard = SolutionIndicator.none;

final _gameTypes = PieceType.values.where((final t) => t != PieceType.zone1 && t != PieceType.zone2).toList();

PuzzlePieceUI _piece(final PieceType type, {required final bool onGrid}) {
  final piece = PuzzlePieceUI.fromType(type, Offset.zero, const Offset(5, 5), 10);
  return onGrid ? piece.copyWith(placeZone: PlaceZone.grid) : piece;
}

PuzzleState _state({
  final GameStatus status = GameStatus.playing,
  final int placed = 0,
  final int solutions = 50,
  final bool isDragging = false,
  final bool showPreview = false,
  final bool previewCollision = false,
  final DrawnGroup? drawnGroup,
  final DrawnGroupCommitStatus drawnStatus = DrawnGroupCommitStatus.tooSmall,
  final int solutionIdx = -1,
}) => PuzzleState.initial().copyWith(
  status: status,
  pieces: [
    _piece(PieceType.zone1, onGrid: true),
    for (var i = 0; i < _gameTypes.length; i++) _piece(_gameTypes[i], onGrid: i < placed),
  ],
  applicableSolutions: List.generate(solutions, (_) => <String, PlacementParams>{}),
  isDragging: isDragging,
  showPreview: showPreview,
  previewCollision: previewCollision,
  drawnGroup: drawnGroup,
  drawnGroupCommitStatus: drawnStatus,
  solutionIdx: solutionIdx,
);

DrawnGroup _group(final int cells) => DrawnGroup(
  cells: [for (var i = 0; i < cells; i++) DrawnCell(cell: Cell(0, i), order: i)],
  nextOrder: cells,
);

void main() {
  group('Easy', () {
    test('shows the solution count', () {
      expect(statusFor(_state(), _easy), const PuzzleStatus(StatusMessage.solutionsCount, tone: StatusTone.ok, count: 50));
      expect(statusFor(_state(placed: 3, solutions: 22), _easy).count, 22);
    });

    test('one solution left', () {
      expect(statusFor(_state(placed: 6, solutions: 1), _easy).message, StatusMessage.oneSolutionLeft);
    });

    test('dead end', () {
      expect(statusFor(_state(placed: 5, solutions: 0), _easy), const PuzzleStatus(StatusMessage.noSolutions, tone: StatusTone.bad));
    });

    test('searching while the solver runs', () {
      expect(statusFor(_state(status: GameStatus.searchingSolutions), _easy).message, StatusMessage.searching);
      expect(statusFor(_state(status: GameStatus.initialized, solutions: 0), _easy).message, StatusMessage.searching);
    });
  });

  group('Medium', () {
    test('ready before the first piece', () {
      expect(statusFor(_state(), _medium).message, StatusMessage.readyToPlay);
    });

    test('solvable while solutions remain', () {
      expect(statusFor(_state(placed: 2, solutions: 7), _medium), const PuzzleStatus(StatusMessage.solvable, tone: StatusTone.ok));
    });

    test('dead end', () {
      expect(statusFor(_state(placed: 5, solutions: 0), _medium), const PuzzleStatus(StatusMessage.deadEnd, tone: StatusTone.bad));
    });
  });

  group('Hard', () {
    test('ready before the first piece', () {
      expect(statusFor(_state(), _hard).message, StatusMessage.readyToPlay);
    });

    test('counts placed game pieces only and never warns', () {
      expect(statusFor(_state(placed: 3), _hard), const PuzzleStatus(StatusMessage.piecesPlaced, count: 3, total: 8));
      expect(statusFor(_state(placed: 5, solutions: 0), _hard).tone, StatusTone.neutral);
    });
  });

  group('context messages win over the level status', () {
    for (final indicator in SolutionIndicator.values) {
      test('$indicator: drag over the grid', () {
        expect(statusFor(_state(isDragging: true, showPreview: true), indicator).message, StatusMessage.releaseToPlace);
        expect(
          statusFor(_state(isDragging: true, showPreview: true, previewCollision: true), indicator),
          const PuzzleStatus(StatusMessage.doesNotFit, tone: StatusTone.bad),
        );
      });

      test('$indicator: drawing', () {
        expect(
          statusFor(_state(drawnGroup: _group(3)), indicator),
          const PuzzleStatus(StatusMessage.keepDrawing, count: 3, total: PuzzleBloc.minCommittableDrawnCells),
        );
        expect(
          statusFor(_state(drawnGroup: _group(5), drawnStatus: DrawnGroupCommitStatus.committable), indicator).message,
          StatusMessage.doubleTapToPlace,
        );
        expect(
          statusFor(_state(drawnGroup: _group(5), drawnStatus: DrawnGroupCommitStatus.invalid), indicator).tone,
          StatusTone.bad,
        );
      });

      test('$indicator: solved and solutions view', () {
        expect(statusFor(_state(status: GameStatus.solvedByUser, placed: 8), indicator).message, StatusMessage.solved);
        expect(
          statusFor(_state(status: GameStatus.showingSolution, solutionIdx: 0), indicator),
          const PuzzleStatus(StatusMessage.viewingSolution, count: 1, total: 50),
        );
      });
    }

    test('drag outside the grid falls back to the level status', () {
      expect(statusFor(_state(isDragging: true), _medium).message, StatusMessage.readyToPlay);
    });
  });
}
